extends Node2D

@onready var P1Spawn = $Players/P1S
@onready var P2Spawn = $Players/P2S
@onready var P3Spawn = $Players/P3S
@onready var P4Spawn = $Players/P4S



func _ready():
	AudioManager.play("theme")
	tree_exiting.connect(_on_exit)
	_spawn_players()


func _spawn_players():
	var player_number = 1

	for slot_id in GameManager.slot_data:
		var slot = GameManager.slot_data[slot_id]

		if slot["state"] == "empty":
			continue
		
	# Não desativa o physics process — o bot precisa dele

		var key = GameManager.CHAR_KEYS[slot["char_index"]]
		var scene_path = GameManager.CHARACTERS[key]["scene"]
		var scene = load(scene_path)
		var instance = scene.instantiate()

		# Configura o player
		instance.player = player_number

		# Posição de spawn
		var spawn = get_node_or_null("SpawnPoints/Spawn%d" % player_number)
		if spawn:
			instance.global_position = spawn.global_position
		else:
			match player_number:
				1:
					instance.global_position = -P1Spawn.global_position
					
				2:
					instance.global_position = -P2Spawn.global_position
					
				3:
					instance.global_position = -P3Spawn.global_position
					
				4: 
					instance.global_position = -P4Spawn.global_position

		if slot["state"] == "bot":
			var bot = load("res://scripts/bot_controller.gd").new()
			instance.add_child(bot)

		$Players.add_child(instance)
		player_number += 1


func _on_exit():
	AudioManager.stop("TitleScream")

func _on_audio_stream_player_2d_tree_exiting() -> void:
	pass # Replace with function body.
