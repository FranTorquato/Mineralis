extends Control

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	pass
#
#func _on_btn_exit_pressed():
	#get_tree().quit() 

func _on_btn_new_game_mouse_entered():
	# Faz o Corvan começar a marretar quando o mouse entra no botão 
	$AnimatedSprite2D.play("marretando")

func _on_btn_new_game_mouse_exited():
	# Faz o Corvan voltar a ficar parado quando o mouse sai 
	$AnimatedSprite2D.play("idle")
