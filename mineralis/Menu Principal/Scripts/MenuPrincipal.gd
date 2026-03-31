extends Control

# ─────────────────────────────────────────────────
# EXPORTS — configure no Inspector de cada card
# ─────────────────────────────────────────────────
@export var phase_id        : String      = "1_1"
@export var phase_texture   : Texture2D
@export var unlock_sound    : AudioStream
@export var starts_unlocked : bool        = false   # marque TRUE só no Card_1_1

# ─────────────────────────────────────────────────
# Estado interno
# ─────────────────────────────────────────────────
var is_unlocked  : bool = false
var is_animating : bool = false
var _mat         : ShaderMaterial

# ─────────────────────────────────────────────────
# Referências — LockOverlay declarado como Node
# para aceitar Sprite2D OU TextureRect sem erro
# ─────────────────────────────────────────────────
@onready var card_btn   : TextureButton   = $CardButton
@onready var card_img   : TextureRect     = $CardButton/CardImage
@onready var lock_icon  : Node            = $CardButton/CardImage/LockOverlay
@onready var flash      : ColorRect       = $GrayOverlay
@onready var sfx        : AudioStreamPlayer = $UnlockSound
@onready var stars      : GPUParticles2D  = $StarParticles

signal card_pressed(phase_id: String)

# ─────────────────────────────────────────────────
# _ready
# ─────────────────────────────────────────────────
func _ready() -> void:
	# 1. Textura do card
	if phase_texture:
		card_img.texture = phase_texture

	# 2. Shader de cinza
	var sm := ShaderMaterial.new()
	sm.shader = load("res://Menu Principal/Shaders/gray_card.gdshader")
	card_img.material = sm
	_mat = sm

	# 3. Som
	if unlock_sound:
		sfx.stream = unlock_sound

	# 4. Garante tamanho e mouse_filter corretos no Control
	custom_minimum_size = Vector2(160, 160)
	mouse_filter = Control.MOUSE_FILTER_PASS

	# 5. Conecta o botão (guard para não duplicar)
	if not card_btn.pressed.is_connected(_on_pressed):
		card_btn.pressed.connect(_on_pressed)

	# 6. Estado inicial
	#    Prioridade: starts_unlocked (Inspector) > ProgressManager > false
	var unlocked := starts_unlocked
	if not unlocked and Engine.has_singleton("ProgressManager"):
		unlocked = ProgressManager.is_unlocked(phase_id)

	is_unlocked = unlocked
	_apply_visual(false)


# ─────────────────────────────────────────────────
# API pública
# ─────────────────────────────────────────────────
func unlock(animate: bool = true) -> void:
	if is_unlocked:
		return
	is_unlocked = true
	if animate:
		_play_unlock_animation()
	else:
		_apply_visual(false)


func lock() -> void:
	is_unlocked = false
	_apply_visual(false)


# ─────────────────────────────────────────────────
# Aplica aparência baseada em is_unlocked
# ─────────────────────────────────────────────────
func _apply_visual(animate: bool) -> void:
	lock_icon.visible = not is_unlocked
	card_btn.disabled = not is_unlocked

	var g := 0.0 if is_unlocked else 1.0    # gray_amount
	var b := 1.0 if is_unlocked else 0.35   # brightness

	if animate and _mat:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_method(
			func(v: float): _mat.set_shader_parameter("gray_amount", v),
			1.0 - g, g, 0.5)
		tw.tween_method(
			func(v: float): _mat.set_shader_parameter("brightness", v),
			1.0 - b + 0.35, b, 0.5)
	elif _mat:
		_mat.set_shader_parameter("gray_amount", g)
		_mat.set_shader_parameter("brightness",  b)


# ─────────────────────────────────────────────────
# Hover via _process
# (necessário porque Control está dentro de Node2D)
# ─────────────────────────────────────────────────
var _was_hovered := false

func _process(_delta: float) -> void:
	if is_animating:
		return

# 1. Detecta se o mouse está sobre o card agora
	var hovered := get_global_rect().has_point(get_viewport().get_mouse_position())

# 2. SÓ EXECUTA se o estado mudou (evita o zoom no primeiro frame)
	if hovered != _was_hovered:
		_was_hovered = hovered

# Ajusta a profundidade visual
		z_index = 10 if hovered else 0

# Cria o Tween para suavizar a transição
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	if hovered:
		# Aplica o zoom (apenas 8% maior para não cobrir o mapa)
		tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
	else:
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)


# ─────────────────────────────────────────────────
# Animação de desbloqueio
# ─────────────────────────────────────────────────
func _play_unlock_animation() -> void:
	is_animating = true
	if sfx.stream:
		sfx.play()

	flash.color   = Color(1, 1, 1, 0.85)
	flash.visible = true

	var t := create_tween()

	# 1. Flash + scale UP
	t.set_parallel(true)
	t.tween_property(flash, "color:a", 0.0, 0.30)
	t.tween_property(self,  "scale",   Vector2(1.2, 1.2), 0.16)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 2. Scale DOWN
	t.set_parallel(false)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 3. Desgrayifica
	t.set_parallel(true)
	if _mat:
		t.tween_method(func(v: float): _mat.set_shader_parameter("gray_amount", v), 1.0, 0.0, 0.5)
		t.tween_method(func(v: float): _mat.set_shader_parameter("brightness",  v), 0.35, 1.0, 0.5)

	# 4. Finaliza
	t.set_parallel(false)
	t.tween_callback(func():
		lock_icon.visible = false
		card_btn.disabled = false
		flash.visible     = false
		is_animating      = false
		_fire_stars()
		_play_shimmer()
	)


func _fire_stars() -> void:
	stars.emitting = false
	await get_tree().process_frame
	stars.emitting = true


func _play_shimmer() -> void:
	var sh := ColorRect.new()
	sh.color    = Color(1, 1, 1, 0.30)
	sh.size     = Vector2(38, 220)
	sh.rotation = deg_to_rad(20)
	sh.position = Vector2(-60, -20)
	add_child(sh)
	var t := create_tween()
	t.tween_property(sh, "position:x", size.x + 60, 0.42)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(sh.queue_free)


# ─────────────────────────────────────────────────
# Clique
# ─────────────────────────────────────────────────
func _on_pressed() -> void:
	if not is_unlocked or is_animating:
		return
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.94, 0.94), 0.05)
	t.tween_property(self, "scale", Vector2(1.0,  1.0),  0.10)
	t.tween_callback(func(): emit_signal("card_pressed", phase_id))
