extends Node

# Layout padrão de teclado por player
const KEYBOARD_DEFAULTS = {
	1: {
		"left":   [KEY_A],
		"right":  [KEY_D],
		"up":     [KEY_W],
		"down":   [KEY_S],
		"jump":   [KEY_SPACE],
		"attack": [KEY_Z],
	},
	2: {
		"left":   [KEY_LEFT],
		"right":  [KEY_RIGHT],
		"up":     [KEY_UP],
		"down":   [KEY_DOWN],
		"jump":   [KEY_ENTER],
		"attack": [KEY_COMMA],
	},
	3: {
		"left":   [KEY_F],
		"right":  [KEY_H],
		"up":     [KEY_T],
		"down":   [KEY_G],
		"jump":   [KEY_V],
		"attack": [KEY_C],
	},
	4: {
		"left":   [KEY_J],
		"right":  [KEY_L],
		"up":     [KEY_I],
		"down":   [KEY_K],
		"jump":   [KEY_N],
		"attack": [KEY_B],
	},
}

# Layout padrão de controle (igual para todos — separado por device_id)
# Botões Xbox: A = joy_button 0, B = 1, X = 2, Y = 3
# D-pad: left = 13, right = 14, up = 11, down = 12
# Bumpers: LB = 9, RB = 10
const CONTROLLER_DEFAULTS = {
	"left":   JOY_BUTTON_DPAD_LEFT,
	"right":  JOY_BUTTON_DPAD_RIGHT,
	"up":     JOY_BUTTON_DPAD_UP,
	"down":   JOY_BUTTON_DPAD_DOWN,
	"jump":   JOY_BUTTON_A,
	"attack": JOY_BUTTON_X,
}

func _ready():
	setup_all_players()


func setup_all_players():
	for p in range(1, 5):
		setup_player(p)


func setup_player(p: int):
	var actions = ["left", "right", "up", "down", "jump", "attack"]
	for action in actions:
		var action_name = "p%d_%s" % [p, action]

		# Cria a action se não existir
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		else:
			InputMap.action_erase_events(action_name)

		# Teclado
		if KEYBOARD_DEFAULTS.has(p):
			for key in KEYBOARD_DEFAULTS[p][action]:
				var ev = InputEventKey.new()
				ev.keycode = key
				InputMap.action_add_event(action_name, ev)

		# Controle (device = player index - 1)
		if CONTROLLER_DEFAULTS.has(action):
			var ev = InputEventJoypadButton.new()
			ev.device = p - 1
			ev.button_index = CONTROLLER_DEFAULTS[action]
			InputMap.action_add_event(action_name, ev)

		# Analógico esquerdo para movimento
		if action == "left":
			var ev = InputEventJoypadMotion.new()
			ev.device = p - 1
			ev.axis = JOY_AXIS_LEFT_X
			ev.axis_value = -1.0
			InputMap.action_add_event(action_name, ev)
		elif action == "right":
			var ev = InputEventJoypadMotion.new()
			ev.device = p - 1
			ev.axis = JOY_AXIS_LEFT_X
			ev.axis_value = 1.0
			InputMap.action_add_event(action_name, ev)
		elif action == "up":
			var ev = InputEventJoypadMotion.new()
			ev.device = p - 1
			ev.axis = JOY_AXIS_LEFT_Y
			ev.axis_value = -1.0
			InputMap.action_add_event(action_name, ev)
		elif action == "down":
			var ev = InputEventJoypadMotion.new()
			ev.device = p - 1
			ev.axis = JOY_AXIS_LEFT_Y
			ev.axis_value = 1.0
			InputMap.action_add_event(action_name, ev)


func remap_action(p: int, action: String, event: InputEvent):
	var action_name = "p%d_%s" % [p, action]
	if not InputMap.has_action(action_name):
		return
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
