
# bot_controller.gd
extends Node

var character: CharacterBody2D
var target: CharacterBody2D
@export var attack_range := 80.0
@export var preferred_range := 110.0
@export var aggression := 0.7
@export var bravery := 0.8
var reaction_timer := 0.0
var action_timer := 0.0
var action_cooldown := 0.35
var style_timer := 0.0
var current_state := "approach"
var move_style := "walk"
var jump_recover_cooldown := 0.0


@export var tile_size := 16.0

@export var stage_left_tile := 27.0
@export var stage_right_tile := 54.0

var stage_left := 0.0
var stage_right := 0.0
var stage_center := 0.0


func _ready():

	character = get_parent()

	stage_left = stage_left_tile * tile_size
	stage_right = stage_right_tile * tile_size

	stage_center = (stage_left + stage_right) / 2.0

	await get_tree().process_frame

	randomize()

	_find_target()
	_choose_approach()



func _find_target():
	var players = get_tree().get_nodes_in_group("players")

	for p in players:
		if p != character:
			target = p
			break


func _physics_process(delta):

	if not character:
		return

	if not is_instance_valid(character):
		return

	if character.is_dead:
		return

	if not target or not is_instance_valid(target):
		_find_target()
		return

	reaction_timer -= delta
	action_timer -= delta
	style_timer -= delta
	jump_recover_cooldown -= delta

	if style_timer <= 0:
		style_timer = randf_range(1.0, 2.5)
		_choose_approach()

	if reaction_timer > 0:
		return
	reaction_timer = randf_range(0.08, 0.18)

	_decide_state()

	await _execute_state(delta)


func _decide_state():

	var dist = character.global_position.distance_to(target.global_position)

	var pct = GameManager.get_percentage(character.player)

	if pct > 120 and dist < attack_range * 2:
		current_state = "recover"
		return

	if dist <= attack_range:
		current_state = "attack"
	else:
		current_state = "approach"


func _choose_approach():

	var roll = randf()

	if roll < 0.35:
		move_style = "walk"

	elif roll < 0.60:
		move_style = "dash"

	elif roll < 0.80:
		move_style = "bait"

	else:
		move_style = "jump_in"


func _execute_state(_delta):

	match current_state:

		"approach":
			await _do_approach()

		"attack":
			await _do_attack()

		"recover":
			await _do_recover()


func _do_approach():

	var diff = target.global_position - character.global_position

	var dir = sign(diff.x)

	var dist = abs(diff.x)

	if diff.y < -80 and character.is_on_floor():
		_press_jump()

	match move_style:

		"walk":
			await _approach_walk(dir, dist)

		"dash":
			await _approach_dash(dir, dist)

		"bait":
			await _approach_bait(dir)

		"jump_in":
			await _approach_jump_in(dir)


func _approach_walk(dir, dist):

	if dist > preferred_range:

		if dir > 0:
			await _press_right()
		else:
			await _press_left()

	# perto demais
	elif dist < preferred_range * 0.6:

		if dir > 0:
			await _press_left()
		else:
			await _press_right()


func _approach_dash(dir, dist):

	if dist > attack_range:

		# double tap
		if dir > 0:
			await _press_right()
			await _press_right()
		else:
			await _press_left()
			await _press_left()


func _approach_bait(dir):
	if dir > 0:
		await _press_left()
	else:
		await _press_right()

	await get_tree().create_timer(
		randf_range(0.08, 0.2)
	).timeout

	if dir > 0:
		await _press_right()
	else:
		await _press_left()


func _approach_jump_in(dir):

	if character.is_on_floor():

		_press_jump()

		if dir > 0:
			await _press_right()
		else:
			await _press_left()

		if randf() < 0.5:

			await get_tree().create_timer(0.1).timeout

			if is_instance_valid(character):
				character.start_fair()

func _do_attack():

	if action_timer > 0:
		return

	if randf() > aggression:
		return

	action_timer = action_cooldown

	var diff = target.global_position - character.global_position

	var on_floor = character.is_on_floor()

	if not on_floor:

		if diff.y > 30:
			character.start_dair()

		elif diff.y < -30:
			character.start_upair()

		elif sign(diff.x) == (1 if character.facing_right else -1):
			character.start_fair()

		else:
			character.start_nair()

	else:

		var roll = randf()

		if roll < 0.3:
			character.start_attack(1)

		elif roll < 0.5:
			character.start_ftilt()

		elif roll < 0.65:
			character.start_uptilt()

		elif roll < 0.8:
			character.start_dtilt()

		else:

			character.is_charging = true

			character.charge_timer = randf_range(0.1, 0.5)

			character.current_attack_key = "fsmash"

			await get_tree().create_timer(
				character.charge_timer
			).timeout

			if is_instance_valid(character):
				character.release_fsmash()


func _do_recover():

	var diff_x = stage_center - character.global_position.x

	var dir = sign(diff_x)

	var height = character.global_position.y

	# =========================
	# VOLTAR PRO CENTRO
	# =========================

	if dir > 0:
		await _press_right()
	else:
		await _press_left()

	# =========================
	# PULOS
	# =========================

	if jump_recover_cooldown > 0:
		return

	# MUITO BAIXO
	if height > 550:

		if character.jumps_left > 0:

			_press_jump()

			jump_recover_cooldown = 0.25

		return

	# LONGE DO STAGE
	if abs(diff_x) > 8:

		if character.jumps_left >= 2:

			_press_jump()

			jump_recover_cooldown = 0.35

	# ABAIXO DO PALCO
	elif height > 120:

		if character.jumps_left > 0:

			_press_jump()

			jump_recover_cooldown = 0.4



func _press_right():

	var ev = InputEventAction.new()

	ev.action = character.action_right
	ev.pressed = true

	Input.parse_input_event(ev)

	await get_tree().process_frame

	ev.pressed = false

	Input.parse_input_event(ev)


func _press_left():

	var ev = InputEventAction.new()

	ev.action = character.action_left
	ev.pressed = true

	Input.parse_input_event(ev)

	await get_tree().process_frame

	ev.pressed = false

	Input.parse_input_event(ev)


func _press_jump():

	if character.jumps_left > 0 or character.coyote_timer > 0:

		character.velocity.y = -character.jump_force

		character.jumps_left -= 1

		AudioManager.play("jump")
