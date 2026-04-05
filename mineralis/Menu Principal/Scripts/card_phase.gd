extends Control

var _cards : Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child.name.begins_with("Card_"):
			var pid = child.name.replace("Card_", "")
			_cards[pid] = child
			# Conecta o sinal do script card_node.gd
			if child.has_signal("card_pressed"):
				child.card_pressed.connect(_on_card_pressed)

	_refresh_cards()
	
	if not ProgressManager.phase_unlocked.is_connected(_on_phase_unlocked):
		ProgressManager.phase_unlocked.connect(_on_phase_unlocked)

func _refresh_cards() -> void:
	for phase_id in _cards:
		var card = _cards[phase_id]
		# O Manager diz se está aberto
		if ProgressManager.is_unlocked(phase_id):
			card.unlock(false)
		else:
			card.lock()

func _on_card_pressed(phase_id: String) -> void:
	if not ProgressManager.is_unlocked(phase_id):
		return
	var path = "res://Fase 1-3/fase_" + phase_id + ".tscn"
	if FileAccess.file_exists(path):
		get_tree().change_scene_to_file(path)

func _on_phase_unlocked(phase_id: String) -> void:
	if _cards.has(phase_id):
		_cards[phase_id].unlock(true)
