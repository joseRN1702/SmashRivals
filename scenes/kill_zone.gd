# KillZone.gd
# Coloque este script num Area2D que envolve toda a arena (fora dos limites)
extends Area2D

func _on_body_entered(body: Node2D) -> void:
	print("KillZone detectou: ", body.name)
	print("É do grupo players? ", body.is_in_group("players"))
	if body.is_in_group("players"):
		body.die()
