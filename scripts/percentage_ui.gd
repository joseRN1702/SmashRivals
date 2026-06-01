extends CanvasLayer

const PLAYER_COLORS = [
	Color(0.23, 0.48, 0.83),  # P1 azul
	Color(0.83, 0.23, 0.23),  # P2 vermelho
	Color(0.22, 0.75, 0.33),  # P3 verde
	Color(0.85, 0.60, 0.10),  # P4 amarelo
]

const COLOR_PCT_LOW  = Color(1.0, 1.0, 1.0)
const COLOR_PCT_MID  = Color(1.0, 0.75, 0.2)
const COLOR_PCT_HIGH = Color(1.0, 0.3, 0.2)

# Dicionários indexados por player_id
var pct_labels := {}
var stocks_containers := {}
var portrait_rects := {}


func _ready():
	add_to_group("percentage_ui")
	await get_tree().process_frame
	_build_hud()
	GameManager.stock_changed.connect(_on_stock_changed)
	GameManager.percentage_changed.connect(_on_percentage_changed)


func _build_hud():
	# Descobre quantos players existem na cena
	var players = get_tree().get_nodes_in_group("players")
	players.sort_custom(func(a, b): return a.player < b.player)

	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	hbox.offset_bottom = -10
	hbox.offset_top = -110
	root.add_child(hbox)

	for p in players:
		hbox.add_child(_make_card(p.player))
		update_percentage(p.player, 0.0)
		update_stocks(p.player, GameManager.starting_stocks)

	_load_portraits(players)


func _make_card(p: int) -> HBoxContainer:
	var color = PLAYER_COLORS[(p - 1) % PLAYER_COLORS.size()]

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	# Portrait
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(70, 90)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(portrait)
	portrait_rects[p] = portrait

	# Separador colorido
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(3, 0)
	sep.color = color
	hbox.add_child(sep)

	# Coluna direita
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox)

	var name_label = Label.new()
	name_label.text = "P" + str(p)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", color)
	vbox.add_child(name_label)

	var pct_label = Label.new()
	pct_label.text = "0%"
	pct_label.add_theme_font_size_override("font_size", 28)
	pct_label.add_theme_color_override("font_color", COLOR_PCT_LOW)
	vbox.add_child(pct_label)
	pct_labels[p] = pct_label

	var stocks_hbox = HBoxContainer.new()
	stocks_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(stocks_hbox)
	stocks_containers[p] = stocks_hbox

	return hbox


func _load_portraits(players: Array):
	for p in players:
		if p.get("portrait") != null and portrait_rects.has(p.player):
			portrait_rects[p.player].texture = p.portrait
			portrait_rects[p.player].modulate = GameManager.player_data[p.player]["tint"]


func update_stocks(p: int, count: int):
	if not stocks_containers.has(p):
		return
	var container = stocks_containers[p]
	var color = PLAYER_COLORS[(p - 1) % PLAYER_COLORS.size()]

	for child in container.get_children():
		child.queue_free()

	for i in range(count):
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(12, 12)
		icon.color = color
		container.add_child(icon)


func update_percentage(p: int, value: float):
	if not pct_labels.has(p):
		return
	var label = pct_labels[p]

	label.text = str(int(value)) + "%"

	var color: Color
	if value < 70.0:
		color = COLOR_PCT_LOW
	elif value < 130.0:
		color = COLOR_PCT_MID
	else:
		color = COLOR_PCT_HIGH

	label.add_theme_color_override("font_color", color)


func _on_stock_changed(player_id: int, stocks_left: int):
	update_stocks(player_id, stocks_left)


func _on_percentage_changed(player_id: int, value: float):
	update_percentage(player_id, value)
