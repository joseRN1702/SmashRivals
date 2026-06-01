extends Control

const PLAYER_COLORS = [
	Color(0.23, 0.48, 0.83),
	Color(0.83, 0.23, 0.23),
	Color(0.22, 0.75, 0.33),
	Color(0.85, 0.60, 0.10),
]

const STATE_LABELS = {
	"player": "JOGADOR",
	"bot":    "BOT",
	"empty":  "VAZIO",
}

@onready var start_label = $StartLabel

@onready var cards = {
	1: $CenterContainer/HBoxContainer/Card1,
	2: $CenterContainer/HBoxContainer/Card2,
	3: $CenterContainer/HBoxContainer/Card3,
	4: $CenterContainer/HBoxContainer/Card4,
}

@onready var state_labels = {
	1: $CenterContainer/HBoxContainer/Card1/VBoxContainer/StateLabel,
	2: $CenterContainer/HBoxContainer/Card2/VBoxContainer/StateLabel,
	3: $CenterContainer/HBoxContainer/Card3/VBoxContainer/StateLabel,
	4: $CenterContainer/HBoxContainer/Card4/VBoxContainer/StateLabel,
}

@onready var player_labels = {
	1: $CenterContainer/HBoxContainer/Card1/VBoxContainer/PlayerLabel,
	2: $CenterContainer/HBoxContainer/Card2/VBoxContainer/PlayerLabel,
	3: $CenterContainer/HBoxContainer/Card3/VBoxContainer/PlayerLabel,
	4: $CenterContainer/HBoxContainer/Card4/VBoxContainer/PlayerLabel,
}

@onready var portrait_rects = {
	1: $CenterContainer/HBoxContainer/Card1/VBoxContainer/PortraitContainer/SubViewport,
	2: $CenterContainer/HBoxContainer/Card2/VBoxContainer/PortraitContainer/SubViewport,
	3: $CenterContainer/HBoxContainer/Card3/VBoxContainer/PortraitContainer/SubViewport,
	4: $CenterContainer/HBoxContainer/Card4/VBoxContainer/PortraitContainer/SubViewport,
}

@onready var char_name_labels = {
	1: $CenterContainer/HBoxContainer/Card1/VBoxContainer/CharNameLabel,
	2: $CenterContainer/HBoxContainer/Card2/VBoxContainer/CharNameLabel,
	3: $CenterContainer/HBoxContainer/Card3/VBoxContainer/CharNameLabel,
	4: $CenterContainer/HBoxContainer/Card4/VBoxContainer/CharNameLabel,
}

@onready var char_icons = {
	1: $CenterContainer/HBoxContainer/Card1/VBoxContainer/IconsHBox,
	2: $CenterContainer/HBoxContainer/Card2/VBoxContainer/IconsHBox,
	3: $CenterContainer/HBoxContainer/Card3/VBoxContainer/IconsHBox,
	4: $CenterContainer/HBoxContainer/Card4/VBoxContainer/IconsHBox,
}

@onready var ready_overlays = {
	1: $CenterContainer/HBoxContainer/Card1/VBoxContainer/ReadyLabel,
	2: $CenterContainer/HBoxContainer/Card2/VBoxContainer/ReadyLabel,
	3: $CenterContainer/HBoxContainer/Card3/VBoxContainer/ReadyLabel,
	4: $CenterContainer/HBoxContainer/Card4/VBoxContainer/ReadyLabel,
}

var connected_devices := []


func _ready():
	AudioManager.play("Select")
	GameManager.reset_selection()
	_scan_devices()
	_setup_cards()
	_refresh_all_cards()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	tree_exiting.connect(_on_exit)


func _scan_devices():
	connected_devices = Input.get_connected_joypads()


func _on_joy_connection_changed(_device: int, _connected: bool):
	connected_devices = Input.get_connected_joypads()
	_refresh_all_cards()


func _setup_cards():
	for slot in range(1, 5):
		var color = PLAYER_COLORS[slot - 1]
		player_labels[slot].text = "P%d" % slot
		player_labels[slot].add_theme_color_override("font_color", color)
		_apply_card_style(slot)


func _apply_card_style(slot: int):
	var slot_info = GameManager.slot_data[slot]
	var color = PLAYER_COLORS[slot - 1]

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = color if slot_info["state"] != "empty" else Color(0.3, 0.3, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	cards[slot].add_theme_stylebox_override("panel", style)


func _refresh_card(slot: int):
	var slot_info = GameManager.slot_data[slot]

	_apply_card_style(slot)
	state_labels[slot].text = STATE_LABELS[slot_info["state"]]
	_update_char_name(slot)
	_update_portrait(slot)
	_build_char_icons(slot)
	ready_overlays[slot].visible = slot_info["ready"]
	start_label.visible = GameManager.all_ready()


func _refresh_all_cards():
	for slot in range(1, 5):
		_refresh_card(slot)


func _update_portrait(slot: int):
	var slot_info = GameManager.slot_data[slot]
	var viewport = portrait_rects[slot]

	for child in viewport.get_children():
		child.queue_free()

	if slot_info["state"] == "empty":
		return

	var key = GameManager.CHAR_KEYS[slot_info["char_index"]]
	var scene = load(GameManager.CHARACTERS[key]["scene"])
	var instance = scene.instantiate()

	var frames = instance.get("preview_frames")
	instance.queue_free()

	if frames:
		var sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = frames
		sprite.position = Vector2(110, 90)
		sprite.scale = Vector2(2, 2)
		sprite.play("AnimatedIcon")
		viewport.add_child(sprite)

func _update_char_name(slot: int):
	var slot_info = GameManager.slot_data[slot]
	var lbl = char_name_labels[slot]

	if slot_info["state"] == "empty":
		lbl.text = ""
	elif slot_info["state"] == "bot":
		lbl.text = GameManager.CHARACTERS[GameManager.CHAR_KEYS[slot_info["char_index"]]]["name"] + " (BOT)"
	else:
		lbl.text = GameManager.CHARACTERS[GameManager.CHAR_KEYS[slot_info["char_index"]]]["name"]


func _build_char_icons(slot: int):
	var container = char_icons[slot]
	for child in container.get_children():
		child.queue_free()

	var slot_info = GameManager.slot_data[slot]
	if slot_info["state"] == "empty":
		return

	for i in range(GameManager.CHAR_KEYS.size()):
		var key = GameManager.CHAR_KEYS[i]
		var char_data = GameManager.CHARACTERS[key]

		var btn = TextureRect.new()
		btn.custom_minimum_size = Vector2(44, 44)
		btn.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		btn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		var instance = load(char_data["scene"]).instantiate()
		if instance.get("portrait"):
			btn.texture = instance.portrait
		instance.queue_free()

		btn.modulate = PLAYER_COLORS[slot - 1] if i == slot_info["char_index"] else Color(0.5, 0.5, 0.5)
		container.add_child(btn)


func _process(_delta):
	for slot in range(1, 5):
		_handle_slot_input(slot)

	if GameManager.all_ready():
		if Input.is_action_just_pressed("start") or Input.is_action_just_pressed("p2_jump"):
			_start_game()


func _handle_slot_input(slot: int):
	var slot_info = GameManager.slot_data[slot]

	if slot >= 3 and not _has_device(slot):
		return

	if Input.is_action_just_pressed("p%d_up" % slot):
		if not slot_info["ready"]:
			_cycle_state(slot, -1)
			_refresh_card(slot)
			AudioManager.play("menu")

	if Input.is_action_just_pressed("p%d_down" % slot):
		if not slot_info["ready"]:
			_cycle_state(slot, 1)
			_refresh_card(slot)
			AudioManager.play("menu")

	if Input.is_action_just_pressed("p%d_left" % slot):
		if not slot_info["ready"] and slot_info["state"] != "empty":
			slot_info["char_index"] = (slot_info["char_index"] - 1 + GameManager.CHAR_KEYS.size()) % GameManager.CHAR_KEYS.size()
			_refresh_card(slot)
			AudioManager.play("menu")

	if Input.is_action_just_pressed("p%d_right" % slot):
		if not slot_info["ready"] and slot_info["state"] != "empty":
			slot_info["char_index"] = (slot_info["char_index"] + 1) % GameManager.CHAR_KEYS.size()
			_refresh_card(slot)
			AudioManager.play("menu")

	if Input.is_action_just_pressed("p%d_attack" % slot):
		if slot_info["state"] != "empty" and not slot_info["ready"]:
			slot_info["ready"] = true
			_refresh_card(slot)
			AudioManager.play("ready")

	if Input.is_action_just_pressed("p%d_jump" % slot):
		if slot_info["ready"]:
			slot_info["ready"] = false
			_refresh_card(slot)


func _cycle_state(slot: int, direction: int):
	var states = ["player", "bot", "empty"]
	var slot_info = GameManager.slot_data[slot]
	var idx = states.find(slot_info["state"])
	slot_info["state"] = states[(idx + direction + states.size()) % states.size()]
	slot_info["ready"] = false


func _has_device(slot: int) -> bool:
	if slot <= 2:
		return true
	return (slot - 3) < connected_devices.size()


func _start_game():
	get_tree().change_scene_to_file("res://scenes/level1.tscn")

func _on_exit():
	AudioManager.stop("Select")

func _on_tree_exiting() -> void:
	pass # Replace with function body.
