extends Node

# -------------------------------------------------------
#  GameEnd.gd  —  Adicione como filho na Level1.tscn
#
#  Escuta o sinal player_eliminated do GameManager.
#  Quando sobrar só 1 player, exibe "GAME !!!" em fade
#  e volta para character_select.tscn.
# -------------------------------------------------------

const CHARACTER_SELECT := "res://scenes/character_select.tscn"
const RETURN_DELAY := 3.0  # segundos exibindo o texto antes de trocar de cena

var _overlay: CanvasLayer
var _label: Label
var _players_alive: int = 0


func _ready() -> void:
	_build_overlay()
	GameManager.player_eliminated.connect(_on_player_eliminated)
	# Conta quantos players estão ativos no início da partida
	await get_tree().process_frame
	_players_alive = get_tree().get_nodes_in_group("players").size()


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 20
	_overlay.visible = false
	add_child(_overlay)

	# Fundo escuro
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(bg)

	# Texto central
	_label = Label.new()
	_label.text = "GAME !!!"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 96)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.0))
	_overlay.add_child(_label)

	# Guarda referência ao bg para animar junto
	_overlay.set_meta("bg", bg)


func _on_player_eliminated(_player_id: int) -> void:
	_players_alive -= 1
	if _players_alive <= 1:
		_show_game_end()
		AudioManager.play("GAME")
		AudioManager.stop("theme")


func _show_game_end() -> void:
	_overlay.visible = true
	var bg: ColorRect = _overlay.get_meta("bg")

	var tween := create_tween().set_parallel(true)

	# Fade in do fundo e do texto simultaneamente
	tween.tween_property(bg,     "color",                       Color(0, 0, 0, 0.7), 1.0)
	tween.tween_property(_label, "theme_override_colors/font_color", Color(1, 1, 1, 1.0), 1.0)

	await tween.finished
	await get_tree().create_timer(RETURN_DELAY - 1.0).timeout

	# Fade out antes de trocar de cena
	var tween_out := create_tween().set_parallel(true)
	tween_out.tween_property(bg,     "color",                       Color(0, 0, 0, 0.0), 0.5)
	tween_out.tween_property(_label, "theme_override_colors/font_color", Color(1, 1, 1, 0.0), 0.5)

	await tween_out.finished
	GameManager.reset_selection()
	get_tree().change_scene_to_file(CHARACTER_SELECT)
	
