extends Node

# -------------------------------------------------------
#  SettingsManager  (Autoload)
#  Salva/carrega em  user://settings.cfg
# -------------------------------------------------------

const SAVE_PATH := "user://settings.cfg"
const SETTINGS_SCENE := "res://scenes/settings.tscn"  # ← ajuste se necessário

var _settings_instance: Node = null
const MAX_PLAYERS := 4

const ACTION_SUFFIXES := ["left", "right", "up", "down", "jump", "attack"]

const GLOBAL_ACTIONS := ["start"]

const DEFAULT_GLOBAL_BINDINGS := {
	"start": KEY_ENTER,
}

var player_device: Array[int] = [-1, -1, -1, -1]

# Defaults exatamente como estão no Input Map do projeto (Physical keycodes)
const DEFAULT_BINDINGS := {
	"p1_left":   KEY_A,
	"p1_right":  KEY_D,
	"p1_up":     KEY_W,
	"p1_down":   KEY_S,
	"p1_jump":   KEY_2,
	"p1_attack": KEY_1,
	"p2_left":   KEY_LEFT,
	"p2_right":  KEY_RIGHT,
	"p2_up":     KEY_UP,
	"p2_down":   KEY_DOWN,
	"p2_jump":   KEY_END,
	"p2_attack": KEY_DELETE,
	"p3_left":   KEY_KP_1,
	"p3_right":  KEY_KP_3,
	"p3_up":     KEY_KP_5,
	"p3_down":   KEY_KP_2,
	"p3_jump":   KEY_KP_SUBTRACT,
	"p3_attack": KEY_KP_MULTIPLY,
	"p4_left":   KEY_J,
	"p4_right":  KEY_L,
	"p4_up":     KEY_I,
	"p4_down":   KEY_K,
	"p4_jump":   KEY_BACKSLASH,
	"p4_attack": KEY_APOSTROPHE,
}

# -------------------------------------------------------
#  Inicialização
# -------------------------------------------------------
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _settings_instance and is_instance_valid(_settings_instance) and _settings_instance.visible:
				if not _settings_instance._listening:
					_settings_instance.close()
			else:
				open_settings(get_tree().root)
			get_viewport().set_input_as_handled()


# -------------------------------------------------------
#  Helpers
# -------------------------------------------------------
func action_name(player: int, suffix: String) -> String:
	return "p%d_%s" % [player, suffix]


# -------------------------------------------------------
#  Remapear uma tecla (por player)
# -------------------------------------------------------
func remap_key(player: int, suffix: String, new_event: InputEvent) -> void:
	var action := action_name(player, suffix)
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	var to_remove: Array = []
	for ev in InputMap.action_get_events(action):
		if new_event is InputEventKey and ev is InputEventKey:
			to_remove.append(ev)
		elif new_event is InputEventJoypadButton and ev is InputEventJoypadButton:
			to_remove.append(ev)
		elif new_event is InputEventJoypadMotion and ev is InputEventJoypadMotion:
			to_remove.append(ev)
	for ev in to_remove:
		InputMap.action_erase_event(action, ev)

	InputMap.action_add_event(action, new_event)


# -------------------------------------------------------
#  Remapear uma action global
# -------------------------------------------------------
func remap_global_action(action: String, new_event: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	var to_remove: Array = []
	for ev in InputMap.action_get_events(action):
		if new_event is InputEventKey and ev is InputEventKey:
			to_remove.append(ev)
		elif new_event is InputEventJoypadButton and ev is InputEventJoypadButton:
			to_remove.append(ev)
		elif new_event is InputEventJoypadMotion and ev is InputEventJoypadMotion:
			to_remove.append(ev)
	for ev in to_remove:
		InputMap.action_erase_event(action, ev)

	InputMap.action_add_event(action, new_event)


# -------------------------------------------------------
#  Dispositivo do player
# -------------------------------------------------------
func set_player_device(player: int, device: int) -> void:
	player_device[player - 1] = device


func get_player_device(player: int) -> int:
	return player_device[player - 1]


func device_label(device: int) -> String:
	if device == -1:
		return "Teclado"
	return Input.get_joy_name(device)


# -------------------------------------------------------
#  Salvar
# -------------------------------------------------------
func save_settings() -> void:
	var cfg := ConfigFile.new()

	for p in range(1, MAX_PLAYERS + 1):
		cfg.set_value("devices", "player_%d" % p, player_device[p - 1])

	for p in range(1, MAX_PLAYERS + 1):
		for suffix in ACTION_SUFFIXES:
			var action := action_name(p, suffix)
			if not InputMap.has_action(action):
				continue
			var events := InputMap.action_get_events(action)
			var serialized: Array = []
			for ev in events:
				serialized.append(_serialize_event(ev))
			cfg.set_value("bindings_p%d" % p, suffix, serialized)

	for action in GLOBAL_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var events := InputMap.action_get_events(action)
		var serialized: Array = []
		for ev in events:
			serialized.append(_serialize_event(ev))
		cfg.set_value("bindings_global", action, serialized)

	cfg.save(SAVE_PATH)


# -------------------------------------------------------
#  Carregar
# -------------------------------------------------------
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return

	for p in range(1, MAX_PLAYERS + 1):
		player_device[p - 1] = cfg.get_value("devices", "player_%d" % p, -1)

	for p in range(1, MAX_PLAYERS + 1):
		for suffix in ACTION_SUFFIXES:
			var action := action_name(p, suffix)
			if not InputMap.has_action(action):
				InputMap.add_action(action)
			var serialized: Array = cfg.get_value("bindings_p%d" % p, suffix, [])
			if serialized.is_empty():
				continue
			InputMap.action_erase_events(action)
			for data in serialized:
				var ev := _deserialize_event(data)
				if ev:
					InputMap.action_add_event(action, ev)

	for action in GLOBAL_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var serialized: Array = cfg.get_value("bindings_global", action, [])
		if serialized.is_empty():
			continue
		InputMap.action_erase_events(action)
		for data in serialized:
			var ev := _deserialize_event(data)
			if ev:
				InputMap.action_add_event(action, ev)


# -------------------------------------------------------
#  Redefinir para defaults
# -------------------------------------------------------
func reset_settings() -> void:
	player_device = [-1, -1, -1, -1]
	for action in DEFAULT_BINDINGS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = DEFAULT_BINDINGS[action]
		InputMap.action_add_event(action, ev)

	for action in DEFAULT_GLOBAL_BINDINGS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = DEFAULT_GLOBAL_BINDINGS[action]
		InputMap.action_add_event(action, ev)

	save_settings()


# -------------------------------------------------------
#  Popup helper
# -------------------------------------------------------
func open_settings(parent: Node) -> void:
	if _settings_instance and is_instance_valid(_settings_instance):
		_settings_instance.open()
		return
	var scene := load(SETTINGS_SCENE)
	_settings_instance = scene.instantiate()
	parent.get_tree().root.add_child(_settings_instance)
	_settings_instance.closed.connect(_on_settings_closed)
	_settings_instance.open()


func _on_settings_closed() -> void:
	pass


# -------------------------------------------------------
#  Serialização
# -------------------------------------------------------
func _serialize_event(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		return { "type": "key", "keycode": ev.keycode, "physical": ev.physical_keycode }
	elif ev is InputEventJoypadButton:
		return { "type": "joy_button", "device": ev.device, "button_index": ev.button_index }
	elif ev is InputEventJoypadMotion:
		return { "type": "joy_motion", "device": ev.device, "axis": ev.axis, "value": ev.axis_value }
	return {}


func _deserialize_event(data: Dictionary) -> InputEvent:
	match data.get("type", ""):
		"key":
			var ev := InputEventKey.new()
			ev.keycode = data.get("keycode", KEY_NONE)
			ev.physical_keycode = data.get("physical", KEY_NONE)
			return ev
		"joy_button":
			var ev := InputEventJoypadButton.new()
			ev.device = data.get("device", 0)
			ev.button_index = data.get("button_index", 0)
			return ev
		"joy_motion":
			var ev := InputEventJoypadMotion.new()
			ev.device = data.get("device", 0)
			ev.axis = data.get("axis", 0)
			ev.axis_value = data.get("value", 1.0)
			return ev
	return null
