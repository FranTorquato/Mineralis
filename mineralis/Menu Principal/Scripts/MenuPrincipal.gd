extends Control

# ─────────────────────────────────────────────────
# EXPORTS
# ─────────────────────────────────────────────────
@export_group("Configurações do Card")
@export var phase_id        : String      = "1_1"
@export var phase_texture   : Texture2D
@export var unlock_sound    : AudioStream
@export var starts_unlocked : bool        = false

# ─────────────────────────────────────────────────
# Estado interno
# ─────────────────────────────────────────────────
var is_unlocked  : bool = false
var is_animating : bool = false
var _mat         : ShaderMaterial
var _was_hovered : bool = false

# ─────────────────────────────────────────────────
# Referências (Ajustadas para sua árvore de nós)
# ─────────────────────────────────────────────────
# Referências dos Cards (Fases)
@onready var card_btn   : TextureButton   = get_node_or_null("CardButton")
@onready var card_img   : TextureRect     = get_node_or_null("CardButton/CardImage")
@onready var lock_icon  : Node            = get_node_or_null("CardButton/CardImage/LockOverlay")
@onready var flash      : ColorRect       = get_node_or_null("GrayOverlay")
@onready var sfx        : AudioStreamPlayer = get_node_or_null("UnlockSound")
@onready var stars      : GPUParticles2D  = get_node_or_null("StarParticles")

# Referências do Menu (Título e Container de Botões)
@onready var titulo_btn  = get_node_or_null("Titulo") # Nome exato da sua árvore
@onready var menu_opcoes = get_node_or_null("Botões") # Nome exato da sua árvore

signal card_pressed(phase_id: String)

# ─────────────────────────────────────────────────
# _ready
# ─────────────────────────────────────────────────
func _ready() -> void:
	# 1. Lógica Inicial do Menu (Mineralis -> Botões)
	if titulo_btn and menu_opcoes:
		menu_opcoes.visible = false
		menu_opcoes.modulate.a = 0
		titulo_btn.visible = true
		titulo_btn.modulate.a = 1.0
		# Centraliza o pivô para animações de escala
		titulo_btn.pivot_offset = titulo_btn.size / 2
		
		# Conecta o clique do título se não estiver conectado no editor
		if not titulo_btn.pressed.is_connected(_on_titulo_pressed):
			titulo_btn.pressed.connect(_on_titulo_pressed)

	# 2. Lógica do Card (Só executa se os nós do card existirem)
	if card_img and card_btn:
		if phase_texture:
			card_img.texture = phase_texture
			
func _on_titulo_pressed() -> void:
	if titulo_btn and menu_opcoes:
		# Desativa o clique para não bugar se o jogador clicar rápido demais
		titulo_btn.disabled = true
		
		# Cria o Tween para sumir os dois juntos
		var tw = create_tween().set_parallel(true)
		
		# 1. Faz o Título (e o Corvan junto) crescer um pouco (efeito de zoom)
		tw.tween_property(titulo_btn, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_QUAD)
		
		# 2. Faz a transparência ir para zero (os dois somem juntos aqui)
		tw.tween_property(titulo_btn, "modulate:a", 0.0, 0.25)
		
		# 3. Quando a animação acabar, esconde de vez e mostra o menu rústico
		tw.set_parallel(false)
		tw.tween_callback(func(): 
			titulo_btn.visible = false
			_show_rustic_menu()
		)

func _show_rustic_menu():
	if menu_opcoes:
		menu_opcoes.visible = true
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# Fade in e um leve movimento de subida para os botões de madeira
		tw.tween_property(menu_opcoes, "modulate:a", 1.0, 0.5)
		var original_y = menu_opcoes.position.y
		menu_opcoes.position.y += 15
		tw.parallel().tween_property(menu_opcoes, "position:y", original_y, 0.5)

# ─────────────────────────────────────────────────
# Funções de Controle das Fases (Cards)
# ─────────────────────────────────────────────────
func unlock(animate: bool = true) -> void:
	if is_unlocked: return
	is_unlocked = true
	if animate: _play_unlock_animation()
	else: _apply_visual(false)

func lock() -> void:
	is_unlocked = false
	_apply_visual(false)

func _apply_visual(animate: bool = false) -> void:
	if not lock_icon or not card_btn: return
	lock_icon.visible = not is_unlocked
	card_btn.disabled = not is_unlocked
	
	var g := 0.0 if is_unlocked else 1.0
	var b := 1.0 if is_unlocked else 0.35
	
	if animate and _mat:
		var tw := create_tween().set_parallel(true)
		tw.tween_method(func(v: float): _mat.set_shader_parameter("gray_amount", v), 1.0 - g, g, 0.5)
		tw.tween_method(func(v: float): _mat.set_shader_parameter("brightness", v), 1.0 - b + 0.35, b, 0.5)
	elif _mat:
		_mat.set_shader_parameter("gray_amount", g)
		_mat.set_shader_parameter("brightness", b)

func _process(_delta: float) -> void:
	# Lógica de Hover apenas para os Cards
	if is_animating or not card_img: return
	
	var hovered := get_global_rect().has_point(get_viewport().get_mouse_position())
	if hovered != _was_hovered:
		_was_hovered = hovered
		z_index = 10 if hovered else 0
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(self, "scale", Vector2(1.05, 1.05) if hovered else Vector2(1.0, 1.0), 0.1)

func _play_unlock_animation() -> void:
	is_animating = true
	if sfx and sfx.stream: sfx.play()
	if flash: flash.visible = true
	
	var t := create_tween()
	t.set_parallel(true)
	if flash: t.tween_property(flash, "color:a", 0.0, 0.30)
	t.tween_property(self, "scale", Vector2(1.2, 1.2), 0.16).set_trans(Tween.TRANS_BACK)
	
	t.set_parallel(false)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK)
	t.tween_callback(func():
		if lock_icon: lock_icon.visible = false
		if card_btn: card_btn.disabled = false
		if flash: flash.visible = false
		is_animating = false
		_fire_stars()
	)

func _fire_stars() -> void:
	if stars:
		stars.emitting = true

func _on_pressed() -> void:
	if not is_unlocked or is_animating: return
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)
	t.tween_callback(func(): emit_signal("card_pressed", phase_id))
