extends Control

@onready var card_1_1 = $Card_1_1
@onready var card_1_2 = $Card_1_2
@onready var card_1_3 = $Card_1_3

# Mapa phase_id → nó do card
var _cards : Dictionary = {}

func _ready() -> void:
	_cards = {
		"1_1": card_1_1,
		"1_2": card_1_2,
		"1_3": card_1_3,
	}

	# Conecta sinais e aplica estado inicial
	for phase_id in _cards:
		var card = _cards[phase_id]
		if not card.card_pressed.is_connected(_on_card_pressed):
			card.card_pressed.connect(_on_card_pressed)

	_refresh_cards()

	# Escuta desbloqueios futuros
	if Engine.has_singleton("ProgressManager"):
		if not ProgressManager.phase_unlocked.is_connected(_on_phase_unlocked):
			ProgressManager.phase_unlocked.connect(_on_phase_unlocked)

	# Animação de entrada escalonada
	_play_enter_animation()


func _refresh_cards() -> void:
	for phase_id in _cards:
		var card = _cards[phase_id]
		var unlocked := false
		if Engine.has_singleton("ProgressManager"):
			unlocked = ProgressManager.is_unlocked(phase_id)
		if unlocked:
			card.unlock(false)
		else:
			card.lock()


func _on_phase_unlocked(phase_id: String) -> void:
	if _cards.has(phase_id):
		_cards[phase_id].unlock(true)   # com animação


func _on_card_pressed(phase_id: String) -> void:
	match phase_id:
		"1_1": get_tree().change_scene_to_file("res://Fase 1-3/fase_1_1.tscn")
		"1_2": get_tree().change_scene_to_file("res://Fase 1-3/fase_1_2.tscn")
		"1_3": get_tree().change_scene_to_file("res://Fase 1-3/fase_1_3.tscn")
		# Adicione as demais fases conforme criar


# ── Animação de entrada ───────────────────────────────────────

func _play_enter_animation() -> void:
	var list := _cards.values()
	for i in list.size():
		var card : Control = list[i]
		card.modulate.a  = 0.0
		card.position.y += 18.0
		var tw := create_tween()
		tw.set_delay(i * 0.12)
		tw.tween_property(card, "modulate:a", 1.0, 0.28)
		tw.parallel().tween_property(card, "position:y", card.position.y - 18.0, 0.28)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
