extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play("TitleScream")
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_fit_to_viewport()
	tree_exiting.connect(_on_exit)

func _fit_to_viewport() -> void:
	var vp_size = get_viewport().get_visible_rect().size
	size = vp_size
	position = Vector2.ZERO

func _on_viewport_resized() -> void:
	_fit_to_viewport()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")
pass # Replace with function body.

func _on_button_settings_pressed() -> void:
	SettingsManager.open_settings(self)
pass # Replace with function body.


func _on_button_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Creditos.tscn")
pass 

func _on_button_exit_pressed() -> void:
	get_tree().quit()
pass 

func _on_exit():
	AudioManager.stop("TitleScream")

func _on_audio_stream_player_2d_tree_exiting() -> void:
	pass # Replace with function body.
