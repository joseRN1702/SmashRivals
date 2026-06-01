extends Camera2D

@onready var limitDL = $"../../Marker2D".global_position
@onready var limitUR = $"../../Marker2D2".global_position

func _ready() -> void:
	limit_left = limitDL.x
	limit_bottom = limitDL.y
	limit_right = limitUR.x
	limit_top = limitUR.y
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0

func _process(delta: float) -> void:
	var players = get_tree().get_nodes_in_group("players")

	if players.is_empty():
		print("No players")
		return

	var avg = Vector2.ZERO
	var count = 0
	for p in players:
		if is_instance_valid(p) and not p.is_dead:
			avg += p.global_position
			count += 1

	if count == 0:
		return

	global_position = avg / count
