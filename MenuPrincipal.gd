extends Node2D
# ──────────────────────────────────────────────────────────────
# MenuPrincipal.gd
# Salve em: res://Menu Principal/Scripts/MenuPrincipal.gd
#
# Sua cena tem:
#   MenuPrincipal (Node2D)
#   ├── MapaFundo
#   ├── MapaMenuPrincipal
#   ├── Card_1_1  (instância de card_phase.tscn)
#   ├── Card_1_2
#   ├── Card_1_3
#   └── WorldEnvironment
# ──────────────────────────────────────────────────────────────

@onready var card_1_1 : Control = $Card_1_1
@onready var card_1_2 : Control = $Card_1_2
@onready var card_1_3 : Control = $Card_1_3

# Mapa phase_id → nó do card
var _cards : Dictionary = {}

func _ready() -> void:
	_cards = {
		"1_1": card_1_1,
		"1_2": card_1_2,
		"1_3": card_1_3,
	}

	# ── FIX CRÍTICO ──────────────────────────────────────────
	# Control dentro de Node2D não recebe input automaticamente.
	# Precisamos garantir que o viewport propague os eventos UI.
	# ─────────────────────────────────────────────────────────
	# (nenhum código extra necessário aqui — o fix já está no
	#  mouse_filter = PASS do card_phase.gd)

	# Conecta sinais e aplica estado inicial
	for phase_id in _cards:
		var card = _cards[phase_id]
		if not card.card_pressed.is_connected(_on_card_pressed):
			card.card_pressed.connect(_on_card_pressed)

	# Aplica estados salvos (cards já fazem isso no próprio _ready,
	# mas o MenuPrincipal pode sobrescrever se necessário)
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


# ── Callbacks ────────────────────────────────────────────────

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
