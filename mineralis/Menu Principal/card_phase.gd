extends Control

# --- Configuração no Inspector ---
@export var phase_id: String = "1_1"
@export var phase_texture: Texture2D
@export var unlock_sound: AudioStream

# --- Estado do Card ---
var is_unlocked: bool = false
var is_animating: bool = false
var is_hovering: bool = false

# --- Referências de nós ---
@onready var card_btn   = $CardButton
@onready var card_img   = $CardButton/CardImage
@onready var lock_icon  = $CardButton/CardImage/LockOverlay  
@onready var flash      = $GrayOverlay
@onready var sfx        = $UnlockSound

var mat : ShaderMaterial

signal card_pressed(phase_id: String)

func _ready() -> void:
	if phase_texture:
		card_img.texture = phase_texture
	
	var shader = load("res://Menu Principal/Shaders/gray_card.gdshader")
	if shader:
		var shader_instance = ShaderMaterial.new()
		shader_instance.shader = shader
		card_img.material = shader_instance
		mat = shader_instance
	
	if unlock_sound:
		sfx.stream = unlock_sound
	
	card_btn.pressed.connect(_on_pressed)
	
	is_unlocked = ProgressManager.is_phase_unlocked(phase_id)
	
	# Aplica o estado inicial
	if is_unlocked:
		_apply_unlocked_appearance()
	else:
		_apply_locked_appearance()

func _process(_delta: float) -> void:
	if is_animating: return
	var currently_hovered = card_btn.is_hovered()
	if currently_hovered and not is_hovering:
		is_hovering = true
		_handle_zoom(1.1)
	elif not currently_hovered and is_hovering:
		is_hovering = false
		_handle_zoom(1.0)

func _handle_zoom(target_scale: float) -> void:
	z_index = 10 if target_scale > 1.0 else 0
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(target_scale, target_scale), 0.1)

# --- CONFIGURAÇÃO VISUAL (SUTILEZA SEM SUMIR) ---

func _apply_locked_appearance() -> void:
	card_btn.disabled = true
	lock_icon.visible = true
	
	# Mantemos 1.0 para garantir que o card apareça no mapa
	self_modulate.a = 1.0 
	
	if mat:
		# Deixamos o shader fazer o trabalho de "apagar" o card
		mat.set_shader_parameter("gray_amount", 1.0) # Totalmente cinza
		mat.set_shader_parameter("brightness", 0.3)    # Bem escuro, mas visível

func _apply_unlocked_appearance() -> void:
	card_btn.disabled = false
	lock_icon.visible = false
	self_modulate.a = 1.0
	
	if mat:
		mat.set_shader_parameter("gray_amount", 0.0)
		mat.set_shader_parameter("brightness", 1.0)

# --- LÓGICA DE ANIMAÇÃO E CLIQUE ---

func _on_pressed() -> void:
	if is_unlocked and not is_animating:
		emit_signal("card_pressed", phase_id)

func unlock(animate: bool = true) -> void:
	if is_unlocked: return
	is_unlocked = true
	if animate: _play_unlock_animation()
	else: _apply_unlocked_appearance()

func _play_unlock_animation() -> void:
	is_animating = true
	if sfx.stream: sfx.play()
	
	var tween = create_tween()
	flash.color = Color(1, 1, 1, 0.8)
	flash.visible = true
	
	tween.set_parallel(true)
	tween.tween_property(flash, "color:a", 0.0, 0.4)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.2).set_trans(Tween.TRANS_BACK)
	
	if mat:
		tween.tween_method(func(v): mat.set_shader_parameter("gray_amount", v), 1.0, 0.0, 0.5)
		tween.tween_method(func(v): mat.set_shader_parameter("brightness", v), 0.3, 1.0, 0.5)
	
	tween.set_parallel(false)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_callback(func():
		_apply_unlocked_appearance()
		is_animating = false
		flash.visible = false
		_play_shimmer_effect()
	)

func _play_shimmer_effect() -> void:
	var shimmer = ColorRect.new()
	shimmer.color = Color(1, 1, 1, 0.3) 
	shimmer.size = Vector2(40, 200)      
	shimmer.rotation = deg_to_rad(25)    
	shimmer.position = Vector2(-100, -20) 
	add_child(shimmer)
	create_tween().tween_property(shimmer, "position:x", 200.0, 0.5).set_trans(Tween.TRANS_SINE)
	create_tween().tween_callback(shimmer.queue_free).set_delay(0.5)
