extends AnimatedSprite2D

# Esta função é chamada quando o node entra na cena.
func _ready() -> void:
	# 1. Garante que a Lhama comece virada para a esquerda
	# (Se você já marcou o 'Flip H' no Inspector, esta linha não é estritamente necessária,
	# mas é bom para garantir).
	flip_h = true

	# 2. Faz a animação padrão começar a tocar
	# Substitua 'default' pelo nome da animação que você quer que toque.
	play("default")
