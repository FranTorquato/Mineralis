extends Control

func _process(delta: float) -> void:
	pass
#
#func _on_btn_exit_pressed():
	#get_tree().quit() 

func _on_btn_new_game_pressed():
	# O caminho deve ser exatamente onde você salvou a primeira cena da fase
	get_tree().change_scene_to_file("res://Fase 1-1/Cena01.tscn")

@onready var animation_player = $AnimationPlayer # Ajuste o caminho para o seu nó AnimationPlayer
