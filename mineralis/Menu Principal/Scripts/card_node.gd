extends Control

signal card_pressed(phase_id: String)
@export var phase_id : String = ""

var _tween: Tween

func _ready() -> void:
	if phase_id == "": phase_id = name.replace("Card_", "")
	
	# Garante que o pivô esteja no centro exato para o zoom ser simétrico
	pivot_offset = size / 2
	
	# Força o filtro do mouse para capturar tudo
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Conexões diretas
	mouse_entered.connect(_on_mouse_hover)
	mouse_exited.connect(_on_mouse_leave)

func _on_mouse_hover() -> void:
	# Traz para a frente para não ficar atrás de ninguém ao crescer
	z_index = 10
	_executar_zoom(Vector2(1.05, 1.05))

func _on_mouse_leave() -> void:
	# Volta para a camada normal e reseta o tamanho
	z_index = 0
	_executar_zoom(Vector2(1.0, 1.0))

func _executar_zoom(valor: Vector2) -> void:
	if _tween: _tween.kill()
	_tween = create_tween()
	# Usamos TRANS_SINE para uma volta mais garantida e suave
	_tween.tween_property(self, "scale", valor, 0.1).set_trans(Tween.TRANS_SINE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_pressed.emit(phase_id)

func unlock(_animate: bool) -> void:
	var l_node = find_child("LockOverlay", true, false)
	var g_node = find_child("GrayOverlay", true, false)
	if l_node: l_node.hide()
	if g_node: g_node.hide()
	
	var img = find_child("CardImage", true, false)
	if img: img.material = null 
	
	self.modulate = Color(1, 1, 1, 1)

func lock() -> void:
	var l_node = find_child("LockOverlay", true, false)
	var g_node = find_child("GrayOverlay", true, false)
	if l_node: l_node.show()
	if g_node: g_node.show()
