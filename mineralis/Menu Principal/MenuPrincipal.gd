extends Node2D

@onready var cards = {
	"1_1": $Card_1_1,
	"1_2": $Card_1_2,
	"1_3": $Card_1_3
}

func _ready():
	await get_tree().process_frame
	
	for id in cards:
		var card = cards[id]
		if card:
			# Inicializa o estado visual sem animação
			if ProgressManager.is_phase_unlocked(id):
				card.unlock(false)
			card.card_pressed.connect(_on_card_selected)

func _on_card_selected(id):
	print("Fase selecionada: ", id)
