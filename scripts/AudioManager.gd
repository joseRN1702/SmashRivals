extends Node

var players := {}

func _ready():
	_load_sounds()

func _load_sounds():
	var sound_names = ["landing", "jump", "dash", "smash", "attack", "appear", "stepleft", "stepright", "damage", "Select", "TitleScream", "menu", "ready", "theme","GAME"]
	for s in sound_names:
		var player = AudioStreamPlayer.new()
		player.stream = load("res://audio/" + s + ".wav")
		add_child(player)
		players[s] = player

func play(sound: String):
	if players.has(sound):
		players[sound].play()


func stop(sound: String):
	if players.has(sound):
		players[sound].stop()
