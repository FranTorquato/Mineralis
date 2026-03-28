extends Control
 
# --- Configuração no Inspector ---
@export var phase_id: String = "1_1"        # Ex: "1_1", "1_2", "1_3"
@export var phase_texture: Texture2D        # Arraste o SVG/PNG aqui
@export var lock_texture: Texture2D         # Ícone de cadeado (opcional)
@export var unlock_sound: AudioStream       # Som ao desbloquear
 
# --- Estado ---
var is_unlocked: bool = false
var is_animating: bool = false
 
# --- Referências de nós ---
@onready var card_button: TextureButton = $CardButton
@onready var card_image: TextureRect = $CardButton/CardImage
@onready var lock_overlay: TextureRect = $CardButton/CardImage/LockOverlay
@onready var gray_overlay: ColorRect = $GrayOverlay
@onready var anim_player: AnimationPlayer = $AnimPlayer
@onready var unlock_audio: AudioStreamPlayer = $UnlockSound
 
# Shader material (será aplicado em card_image)
var shader_material_instance: ShaderMaterial
 
# --- Sinal emitido ao clicar ---
signal card_pressed(phase_id: String)
 
 
func _ready() -> void:
	# Aplica a textura
	card_image.texture = phase_texture
	
	# Configura o shader de cinza
	var shader = load("res://shaders/gray_card.gdshader")
	shader_material_instance = ShaderMaterial.new()
	shader_material_instance.shader = shader
	card_image.material = shader_material_instance
	
	# Configura o som
	if unlock_sound:
		unlock_audio.stream = unlock_sound
	
	# Conecta o botão
	card_button.pressed.connect(_on_card_pressed)
	
	# Aplica estado inicial (sem animação)
	_apply_locked_state(false)
 
 
func unlock(animate: bool = true) -> void:
	"""Desbloqueia o card. Chame isto quando o jogador completar a fase anterior."""
	if is_unlocked:
		return
	
	is_unlocked = true
	
	if animate:
		_play_unlock_animation()
	else:
		_apply_locked_state(false)
 
 
func lock() -> void:
	"""Bloqueia o card (uso raro, ex: reset de progresso)."""
	is_unlocked = false
	_apply_locked_state(false)
 
 
# --- Estados visuais ---
 
func _apply_locked_state(animate: bool = false) -> void:
	card_button.disabled = true
	lock_overlay.visible = true
	
	if animate:
		# Transição suave para cinza
		var tween = create_tween()
		tween.tween_method(
			func(v): shader_material_instance.set_shader_parameter("gray_amount", v),
			0.0, 1.0, 0.4
		)
		tween.parallel().tween_method(
			func(v): shader_material_instance.set_shader_parameter("brightness", v),
			1.0, 0.6, 0.4
		)
	else:
		shader_material_instance.set_shader_parameter("gray_amount", 1.0)
		shader_material_instance.set_shader_parameter("brightness", 0.6)
		modulate.a = 1.0
 
 
func _apply_unlocked_state(animate: bool = false) -> void:
	card_button.disabled = false
	lock_overlay.visible = false
	
	if animate:
		var tween = create_tween()
		tween.tween_method(
			func(v): shader_material_instance.set_shader_parameter("gray_amount", v),
			1.0, 0.0, 0.6
		)
		tween.parallel().tween_method(
			func(v): shader_material_instance.set_shader_parameter("brightness", v),
			0.6, 1.0, 0.6
		)
	else:
		shader_material_instance.set_shader_parameter("gray_amount", 0.0)
		shader_material_instance.set_shader_parameter("brightness", 1.0)
 
 
# --- Animação de desbloqueio ---
 
func _play_unlock_animation() -> void:
	is_animating = true
	
	# Som de desbloqueio
	if unlock_audio.stream:
		unlock_audio.play()
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# 1. Flash branco
	gray_overlay.color = Color(1, 1, 1, 0.8)
	gray_overlay.visible = true
	tween.tween_property(gray_overlay, "color:a", 0.0, 0.3)
	
	# 2. Escala (pulse)
	tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25)
	
	# 3. Destrava cor (começa a ficar colorido)
	tween.tween_callback(func():
		_apply_locked_state(false)
	)
	
	# 4. Shimmer (brilho percorrendo o card)
	tween.tween_callback(_play_shimmer_effect)
	
	# 5. Finaliza
	tween.tween_callback(func():
		is_animating = false
		gray_overlay.visible = false
	)
 
 
func _play_shimmer_effect() -> void:
	"""Efeito de brilho passando pelo card após desbloqueio."""
	# Cria um ColorRect diagonal branco semi-transparente
	var shimmer = ColorRect.new()
	shimmer.color = Color(1, 1, 1, 0.4)
	shimmer.size = Vector2(40, 80)
	shimmer.position = Vector2(-40, 0)
	add_child(shimmer)
	
	var tween = create_tween()
	tween.tween_property(shimmer, "position:x", 120.0, 0.4)
	tween.tween_callback(shimmer.queue_free)
 
 
# --- Hover effect (card desbloqueado) ---
 
func _on_card_button_mouse_entered() -> void:
	if not is_unlocked or is_animating:
		return
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
 
 
func _on_card_button_mouse_exited() -> void:
	if not is_unlocked or is_animating:
		return
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
 
 
func _on_card_pressed() -> void:
	if is_unlocked and not is_animating:
		# Feedback visual de clique
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		
		emit_signal("card_pressed", phase_id)
