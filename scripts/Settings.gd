extends CanvasLayer

signal closed

const ACTION_SUFFIXES := SettingsManager.ACTION_SUFFIXES
const ACTION_LABELS := {
	"left":   "← Esquerda",
	"right":  "→ Direita",
	"up":     "↑ Cima",
	"down":   "↓ Baixo",
	"jump":   "Pulo",
	"attack": "Ataque",
}

const GLOBAL_ACTION_LABELS := {
	"start": "start",
}

var _listening := false
var _listen_player: int = 0
var _listen_suffix: String = ""
var _listen_button: Button = null
var _listen_is_global := false
var _listen_key_lbl: Label = null
var _device_option: Dictionary = {}

var _status_label: Label
var _overlay: ColorRect
var _panel: PanelContainer

# -------------------------------------------------------
#  Setup
# -------------------------------------------------------
func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func open() -> void:
	for p in _device_option.keys():
		_populate_device_option(_device_option[p], p)
	visible = true
	_set_players_active(false)


func close() -> void:
	if _listening:
		_cancel_remap()
	_set_players_active(true)
	visible = false
	closed.emit()


func _set_players_active(active: bool) -> void:
	if not is_inside_tree():
		return
	for player in get_tree().get_nodes_in_group("players"):
		player.set_physics_process(active)
		player.set_process(active)
		player.set_process_input(active)


# -------------------------------------------------------
#  Construção da UI
# -------------------------------------------------------
func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.65)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_panel = PanelContainer.new()
	_panel.anchor_left   = 0.5
	_panel.anchor_top    = 0.5
	_panel.anchor_right  = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left   = -360
	_panel.offset_top    = -300
	_panel.offset_right  = 360
	_panel.offset_bottom = 300
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "⚙  Configurações de Controles"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	_status_label.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(_status_label)

	# --- Seção global (Start) ---
	var global_hbox := HBoxContainer.new()
	global_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(global_hbox)

	var global_title := Label.new()
	global_title.text = "Teclas globais:"
	global_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	global_hbox.add_child(global_title)

	for action in SettingsManager.GLOBAL_ACTIONS:
		var action_label := Label.new()
		action_label.text = GLOBAL_ACTION_LABELS.get(action, action) + ":"
		action_label.custom_minimum_size = Vector2(80, 0)
		global_hbox.add_child(action_label)

		var key_lbl := Label.new()
		key_lbl.text = _get_global_binding_text(action)
		key_lbl.custom_minimum_size = Vector2(140, 0)
		key_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
		global_hbox.add_child(key_lbl)

		var remap_btn := Button.new()
		remap_btn.text = "Alterar"
		remap_btn.custom_minimum_size = Vector2(80, 30)
		remap_btn.pressed.connect(_on_remap_global_pressed.bind(action, remap_btn, key_lbl))
		global_hbox.add_child(remap_btn)

	vbox.add_child(HSeparator.new())
	# --- fim seção global ---

	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(0, 380)
	vbox.add_child(tabs)

	for p in range(1, 5):
		var page := _build_player_page(p)
		page.name = "Player %d" % p
		tabs.add_child(page)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	var save_btn := Button.new()
	save_btn.text = "💾  Salvar"
	save_btn.custom_minimum_size = Vector2(140, 44)
	save_btn.pressed.connect(_on_save_pressed)
	hbox.add_child(save_btn)

	var reset_btn := Button.new()
	reset_btn.text = "↺  Redefinir"
	reset_btn.custom_minimum_size = Vector2(140, 44)
	reset_btn.pressed.connect(_on_reset_pressed)
	hbox.add_child(reset_btn)

	var close_btn := Button.new()
	close_btn.text = "✕  Fechar"
	close_btn.custom_minimum_size = Vector2(140, 44)
	close_btn.pressed.connect(close)
	hbox.add_child(close_btn)


func _on_reset_pressed() -> void:
	SettingsManager.reset_settings()
	_panel.queue_free()
	await get_tree().process_frame
	_device_option.clear()
	_build_ui()
	_set_status("↺  Configurações redefinidas!")


func _build_player_page(player: int) -> Control:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var dev_row := HBoxContainer.new()
	root.add_child(dev_row)

	var dev_label := Label.new()
	dev_label.text = "Dispositivo:"
	dev_label.custom_minimum_size = Vector2(120, 0)
	dev_row.add_child(dev_label)

	var dev_option := OptionButton.new()
	dev_option.custom_minimum_size = Vector2(220, 0)
	_populate_device_option(dev_option, player)
	dev_option.item_selected.connect(_on_device_selected.bind(player, dev_option))
	dev_row.add_child(dev_option)
	_device_option[player] = dev_option

	root.add_child(HSeparator.new())

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	root.add_child(grid)

	for header in ["Ação", "Tecla atual", ""]:
		var lbl := Label.new()
		lbl.text = header
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		grid.add_child(lbl)

	for suffix in ACTION_SUFFIXES:
		var name_lbl := Label.new()
		name_lbl.text = ACTION_LABELS.get(suffix, suffix)
		name_lbl.custom_minimum_size = Vector2(120, 0)
		grid.add_child(name_lbl)

		var key_lbl := Label.new()
		key_lbl.text = _get_binding_text(player, suffix)
		key_lbl.custom_minimum_size = Vector2(170, 0)
		key_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
		grid.add_child(key_lbl)

		var remap_btn := Button.new()
		remap_btn.text = "Alterar"
		remap_btn.custom_minimum_size = Vector2(80, 30)
		remap_btn.pressed.connect(_on_remap_pressed.bind(player, suffix, remap_btn, key_lbl))
		grid.add_child(remap_btn)

	return margin


# -------------------------------------------------------
#  Dispositivos
# -------------------------------------------------------
func _populate_device_option(opt: OptionButton, player: int) -> void:
	opt.clear()
	opt.add_item("Teclado", -1)
	for joy_id in Input.get_connected_joypads():
		opt.add_item(Input.get_joy_name(joy_id), joy_id)
	var current := SettingsManager.get_player_device(player)
	for i in opt.item_count:
		if opt.get_item_id(i) == current:
			opt.select(i)
			return
	opt.select(0)


func _on_device_selected(index: int, player: int, opt: OptionButton) -> void:
	SettingsManager.set_player_device(player, opt.get_item_id(index))


# -------------------------------------------------------
#  Remapeamento — player
# -------------------------------------------------------
func _on_remap_pressed(player: int, suffix: String, btn: Button, key_lbl: Label) -> void:
	if _listening:
		if _listen_button:
			_listen_button.text = "Alterar"
		_listening = false

	_listening = true
	_listen_is_global = false
	_listen_player = player
	_listen_suffix = suffix
	_listen_button = btn
	_listen_key_lbl = key_lbl
	btn.text = "[ ... ]"
	_set_status("P%d / %s  — pressione a tecla  (ESC = cancelar)" % [player, ACTION_LABELS.get(suffix, suffix)])


# -------------------------------------------------------
#  Remapeamento — global
# -------------------------------------------------------
func _on_remap_global_pressed(action: String, btn: Button, key_lbl: Label) -> void:
	if _listening:
		if _listen_button:
			_listen_button.text = "Alterar"
		_listening = false

	_listening = true
	_listen_is_global = true
	_listen_suffix = action
	_listen_button = btn
	_listen_key_lbl = key_lbl
	btn.text = "[ ... ]"
	_set_status("%s (global) — pressione a tecla  (ESC = cancelar)" % GLOBAL_ACTION_LABELS.get(action, action))


# -------------------------------------------------------
#  Input
# -------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not visible or not _listening:
		return

	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_cancel_remap()
		get_viewport().set_input_as_handled()
		return

	var valid := false
	if event is InputEventKey and event.pressed and not event.echo:
		valid = true
	elif event is InputEventJoypadButton and event.pressed:
		valid = true
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		valid = true

	if not valid:
		return

	if _listen_is_global:
		SettingsManager.remap_global_action(_listen_suffix, event)
		if _listen_key_lbl:
			_listen_key_lbl.text = _get_global_binding_text(_listen_suffix)
	else:
		SettingsManager.remap_key(_listen_player, _listen_suffix, event)
		if _listen_key_lbl:
			_listen_key_lbl.text = _get_binding_text(_listen_player, _listen_suffix)

	if _listen_button:
		_listen_button.text = "Alterar"

	_set_status("✔  Tecla alterada!")
	_listening = false
	_listen_button = null
	_listen_key_lbl = null
	get_viewport().set_input_as_handled()


func _cancel_remap() -> void:
	if _listen_button:
		_listen_button.text = "Alterar"
	_listening = false
	_listen_button = null
	_listen_key_lbl = null
	_set_status("Cancelado.")


# -------------------------------------------------------
#  Helpers
# -------------------------------------------------------
func _get_binding_text(player: int, suffix: String) -> String:
	var action := SettingsManager.action_name(player, suffix)
	if not InputMap.has_action(action):
		return "—"
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "—"
	var parts: Array[String] = []
	for ev in events:
		parts.append(_event_label(ev))
	return " / ".join(parts)


func _get_global_binding_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "—"
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "—"
	var parts: Array[String] = []
	for ev in events:
		parts.append(_event_label(ev))
	return " / ".join(parts)


func _event_label(ev: InputEvent) -> String:
	if ev is InputEventKey:
		return OS.get_keycode_string(ev.keycode) if ev.keycode != KEY_NONE \
			else OS.get_keycode_string(ev.physical_keycode)
	elif ev is InputEventJoypadButton:
		return "Btn %d" % ev.button_index
	elif ev is InputEventJoypadMotion:
		return "Axis%d%s" % [ev.axis, "+" if ev.axis_value > 0 else "-"]
	return ev.as_text()


func _set_status(msg: String) -> void:
	_status_label.text = msg


# -------------------------------------------------------
#  Salvar
# -------------------------------------------------------
func _on_save_pressed() -> void:
	SettingsManager.save_settings()
	_set_status("✔  Salvo!")
