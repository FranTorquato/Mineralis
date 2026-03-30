extends Node2D

@onready var cards = {
	"1_1": $Card_1_1,
	"1_2": $Card_1_2,
	"1_3": $Card_1_3
}

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame  # dois frames para garantir

	for id in cards:
		var card = cards[id]
		if card:
			if ProgressManager.is_unlocked(id):
				card.unlock(false)
				card.card_pressed.connect(_on_card_selected)

# TESTE DIRETO — força unlock do Card_1_2 após 2 segundos
	await get_tree().create_timer(2.0).timeout
	print("=== FORÇANDO UNLOCK DO CARD 1_2 ===")
	var c = $Card_1_2
	print("Card encontrado: ", c)
	print("is_unlocked antes: ", c.is_unlocked)
	c.is_unlocked = false  # força reset do estado
	c.unlock(true)
	print("unlock() chamado")

func _on_card_selected(id):
	print("Fase selecionada: ", id)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			print("tecla 1 pressionada!")
			$Card_1_2.unlock(true)
			if event.keycode == KEY_2:
				$Card_1_3.unlock(true)
				if event.keycode == KEY_R:
					SaveManager.reset_save()
			get_tree().reload_current_scene()
