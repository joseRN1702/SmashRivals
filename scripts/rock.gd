extends CharacterBody2D

@export var speed := 300.0
@export var jump_force := 500.0
@export var gravity := 900.0
@export var max_jumps := 2
@export var player: int = 1
@export var preview_frames: SpriteFrames

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $Hitbox
@onready var anim_player = $AnimationPlayer

@export var portrait: Texture2D

var playerG: String

# ACTIONS — geradas automaticamente com base no player id
var action_left: String
var action_right: String
var action_up: String
var action_down: String
var action_jump: String
var action_attack: String

# INPUT
var previous_actions := {}

# MOVEMENT
var accel := 2000.0
var friction := 1800.0
var air_accel := 1000.0
var air_friction := 800.0

var facing_right := true

# ATTACK
var jab_index := 0
var can_chain := false
var attacking := false
var buffered_attack := false
var hit_landed := false
var is_in_hitstun := false
const MAX_JAB := 3

# HITSTUN
var hitstun_timer := 0.0
const HITSTUN_BASE := 0.12
const HITSTUN_KNOCKBACK_SCALE := 0.00018
const HITSTUN_MAX := 0.7

# JUMP
var jumps_left := 0
var fall_multiplier := 1.3
var low_jump_multiplier := 1.8
var coyote_time := 0.1
var coyote_timer := 0.0
var max_air_speed := 250.0

# DASH
var dash_speed := 700.0
var dash_time := 0.15
var dash_timer := 0.0
var is_dashing := false

var dash_tap_time := 0.25
var dash_tap_timer := 0.0
var last_tap_dir := 0

# RUN
var run_speed := 400
var is_running := false
var run_stop_timer := 0.0
var run_stop_delay := 0.1

# DASH ATTACK
var dash_attacking := false
var dash_attack_time := 0.0
var dash_attack_duration := 0.45
var dash_attack_dir := 0

# TURNAROUND
var turnaround_timer := 0.0
const TURNAROUND_DELAY := 0.1
var buffered_flip := false

# FSMASH
var smash_tap_timer := 0.0
const SMASH_TAP_WINDOW := 0.12
var smash_tap_dir := 0
var is_charging := false
var charge_timer := 0.0
const CHARGE_MAX := 1.3
var fsmash_charged_damage := 12.0
var fsmash_charged_knockback := 1000.0
const FSMASH_BASE_DAMAGE := 12.0
const FSMASH_BASE_KNOCKBACK := 250.0

# UPSMASH
const UPSMASH_BASE_DAMAGE := 12.0
const UPSMASH_BASE_KNOCKBACK := 200.0
var upsmash_charged_damage := 12.0
var upsmash_charged_knockback := 1000.0

# DOWNSMASH
const DSMASH_BASE_DAMAGE := 11.0
const DSMASH_BASE_KNOCKBACK := 300.0
var dsmash_charged_damage := 11.0
var dsmash_charged_knockback := 300.0

# STOCKS / RESPAWN
@export var stocks: int = 3
var spawn_position: Vector2
var is_dead := false
var respawn_invincible := false
var respawn_invincible_timer := 0.0
const RESPAWN_INVINCIBLE_TIME := 5.0
const RESPAWN_DELAY := 1.5

# LANDING
var was_on_floor := false

# FALLEN
var is_fallen := false
var fallen_timer := 0.0
@export var fallen_duration := 1.0
var pending_fallen := false

var ATTACK_DATA := {
	"jab1":        { "damage": 3.0,  "knockback": 0.0,   "angle": 0,  "hitstun_push": 120.0 },
	"jab2":        { "damage": 4.0,  "knockback": 0.0,   "angle": 0,  "hitstun_push": 120.0 },
	"jab3":        { "damage": 6.0,  "knockback": 300.0, "angle": 45, "hitstun_push": 0.0   },
	"dash_attack": { "damage": 10.0, "knockback": 500.0, "angle": 10, "hitstun_push": 0.0   },
	"nair":        { "damage": 7.0,  "knockback": 200.0, "angle": 60, "hitstun_push": 0.0   },
	"uptilt":      { "damage": 4.0,  "knockback": 200.0, "angle": 85, "hitstun_push": 0.0   },
	"ftilt":       { "damage": 6.0,  "knockback": 200.0, "angle": 15, "hitstun_push": 0.0   },
	"bair":        { "damage": 11.0, "knockback": 650.0, "angle": 30, "hitstun_push": 0.0   },
	"fair":        { "damage": 9.0,  "knockback": 580.0, "angle": 180, "hitstun_push": 0.0  },
	"dair":        { "damage": 12.0, "knockback": 300.0, "angle": 270, "hitstun_push": 0.0  },
	"dtilt":       { "damage": 5.0,  "knockback": 250.0, "angle": 0,  "hitstun_push": 0.0   },
	"upair":       { "damage": 8.0,  "knockback": 300.0, "angle": 85, "hitstun_push": 0.0   },
	"fsmash":      { "damage": 12.0, "knockback": 100.0, "angle": 10, "hitstun_push": 0.0   },
	"upsmash":     { "damage": 13.0, "knockback": 200.0, "angle": 88, "hitstun_push": 0.0   },
	"dsmash":      { "damage": 11.0, "knockback": 300.0, "angle": 40, "hitstun_push": 0.0   },
}

var current_attack_key := ""


func _ready():
	add_to_group("players")
	add_to_group("player" + str(player))
	playerG = "player" + str(player)
	spawn_position = global_position
	jumps_left = max_jumps

	# Monta os nomes das actions baseado no player id
	action_left   = "p%d_left"   % player
	action_right  = "p%d_right"  % player
	action_up     = "p%d_up"     % player
	action_down   = "p%d_down"   % player
	action_jump   = "p%d_jump"   % player
	action_attack = "p%d_attack" % player

	previous_actions[action_left]   = false
	previous_actions[action_right]  = false
	previous_actions[action_up]     = false
	previous_actions[action_down]   = false
	previous_actions[action_jump]   = false
	previous_actions[action_attack] = false

	GameManager.register_player(player, stocks)
	var tint = _get_player_tint()
	GameManager.register_player_tint(player, tint)
	anim.modulate = tint


func _get_player_tint() -> Color:
	const TINTS = [
		Color(1, 1, 1),
		Color(0.4, 0.8, 1.0),
		Color(1.0, 0.5, 0.5),
		Color(0.5, 1.0, 0.5),
	]
	var char_id = portrait.resource_path if portrait else name
	var same_char_count = GameManager.count_character(char_id)
	return TINTS[same_char_count % TINTS.size()]


func _physics_process(delta):
	if is_dead:
		return

	if is_fallen:
		fallen_timer -= delta
		print("velocity.x: ", velocity.x, " | is_on_floor: ", is_on_floor())
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.y += gravity * delta
		move_and_slide()
		update_input_states()
		if fallen_timer <= 0.0:
			_end_fallen()
		return
	
	if respawn_invincible:
		respawn_invincible_timer -= delta
		if respawn_invincible_timer <= 0.0:
			respawn_invincible = false
			anim.modulate = GameManager.player_data[player]["tint"]

	if is_in_hitstun:
		hitstun_timer -= delta
		if hitstun_timer <= 0.0:
			_end_hitstun()

	if is_charging:
		charge_timer = min(charge_timer + delta, CHARGE_MAX)
		if previous_actions[action_attack] and not key_pressed(action_attack):
			if current_attack_key == "fsmash":
				release_fsmash()
			elif current_attack_key == "upsmash":
				release_upsmash()
			elif current_attack_key == "dsmash":
				release_dsmash()

	if not is_in_hitstun:
		handle_attack()
		handle_movement(delta)
		handle_jump()

	was_on_floor = is_on_floor()
	apply_gravity(delta)
	move_and_slide()
	handle_animation()
	hitbox_handler()
	update_input_states()


func _end_hitstun():
	is_in_hitstun = false
	hitstun_timer = 0.0
	attacking = false
	dash_attacking = false
	if anim.animation == "damage":
		anim.play("idle")


func update_input_states():
	for action in previous_actions.keys():
		previous_actions[action] = Input.is_action_pressed(action)


func key_pressed(action: String) -> bool:
	return Input.is_action_pressed(action)


func key_just_pressed(action: String) -> bool:
	return Input.is_action_pressed(action) and not previous_actions[action]


func handle_movement(delta):
	var direction := 0
	if dash_attacking:
		handle_dash_attack(delta)
		return

	if key_pressed(action_left):
		direction -= 1
	if key_pressed(action_right):
		direction += 1

	var input_dir := 0
	if key_just_pressed(action_right):
		input_dir = 1
	elif key_just_pressed(action_left):
		input_dir = -1

	if input_dir != 0:
		if not attacking and last_tap_dir == input_dir and dash_tap_timer > 0:
			start_dash(input_dir)
		dash_tap_timer = dash_tap_time
		last_tap_dir = input_dir

	dash_tap_timer -= delta

	if input_dir != 0 and is_on_floor() and not attacking:
		smash_tap_dir = input_dir
		smash_tap_timer = SMASH_TAP_WINDOW

	if key_just_pressed(action_up) and is_on_floor() and not attacking:
		smash_tap_dir = 0
		smash_tap_timer = SMASH_TAP_WINDOW

	if key_just_pressed(action_down) and is_on_floor() and not attacking:
		smash_tap_dir = 0
		smash_tap_timer = SMASH_TAP_WINDOW

	smash_tap_timer -= delta

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			if direction != 0 and not attacking:
				is_running = true
		else:
			return

	if is_running and not attacking:
		if direction == 0:
			run_stop_timer -= delta
			if run_stop_timer <= 0:
				is_running = false
		else:
			run_stop_timer = run_stop_delay

	var acc
	var fric

	if is_on_floor():
		coyote_timer = coyote_time
		acc = accel
		fric = friction
	else:
		coyote_timer -= delta
		acc = air_accel
		fric = air_friction

	var attack_speed_mult := 1.0

	if attacking:
		if is_on_floor():
			acc *= 0.05
			fric *= 6.0
		else:
			acc *= 0.3
			fric *= 1.2

		match jab_index:
			1: attack_speed_mult = 0.15
			2: attack_speed_mult = 0.08
			3: attack_speed_mult = 0.0

	var target_speed = speed
	if is_running:
		target_speed = run_speed
	target_speed *= attack_speed_mult

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * target_speed, acc * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, fric * delta)

	if not attacking:
		if not is_on_floor():
			if direction > 0 and not facing_right:
				turnaround_timer = TURNAROUND_DELAY
				buffered_flip = true
			elif direction < 0 and facing_right:
				turnaround_timer = TURNAROUND_DELAY
				buffered_flip = true

			if buffered_flip:
				turnaround_timer -= delta
				if turnaround_timer <= 0.0:
					flip()
					buffered_flip = false
			else:
				turnaround_timer = 0.0
		else:
			if direction > 0 and not facing_right:
				flip()
			elif direction < 0 and facing_right:
				flip()

	if dash_attacking:
		acc *= 0.02
		fric *= 0.3


func start_dash(direction):
	if is_dashing:
		return
	is_dashing = true
	dash_timer = dash_time
	velocity.x = direction * dash_speed
	AudioManager.play("dash")


func handle_jump():
	if key_just_pressed(action_jump):
		if jumps_left > 0 or coyote_timer > 0:
			if key_pressed(action_right) and not facing_right:
				flip()
				buffered_flip = false
				turnaround_timer = 0.0
			elif key_pressed(action_left) and facing_right:
				flip()
				buffered_flip = false
				turnaround_timer = 0.0
			velocity.y = -jump_force
			jumps_left -= 1
			AudioManager.play("jump")


func apply_gravity(delta):
	if not is_on_floor():
		if not is_in_hitstun:
			velocity.x = clamp(velocity.x, -max_air_speed, max_air_speed)

		var hitstun_float := 0.65 if is_in_hitstun else 1.0

		if velocity.y > 0:
			velocity.y += gravity * fall_multiplier * hitstun_float * delta
		elif velocity.y < 0 and not key_pressed(action_jump):
			velocity.y += gravity * low_jump_multiplier * hitstun_float * delta
		else:
			velocity.y += gravity * hitstun_float * delta
	else:
		jumps_left = max_jumps  # <-- movido pra cá, reseta sempre que está no chão
		if not was_on_floor and pending_fallen:
			pending_fallen = false
			_start_fallen()
		if not was_on_floor:
			AudioManager.play("landing")
		buffered_flip = false
		turnaround_timer = 0.0


func _start_fallen():
	is_fallen = true
	fallen_timer = fallen_duration
	velocity = Vector2.ZERO
	jumps_left = max_jumps  # <-- adiciona
	reset_attack()

	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(anim, "scale", Vector2(1.4, 0.3), 0.12)


func _end_fallen():
	is_fallen = false
	fallen_timer = 0.0

	# Levanta com um bounce
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(anim, "scale", Vector2(1.0, 1.0), 0.4)

	anim.play("idle")

func handle_attack():
	if not key_just_pressed(action_attack):
		return

	if not is_on_floor():
		if key_pressed(action_down):
			start_dair()
			return
		if key_pressed(action_up):
			start_upair()
			return
		var holding_back = (key_pressed(action_left) and facing_right) or (key_pressed(action_right) and not facing_right)
		if holding_back:
			start_bair()
			return
		var holding_forward = (key_pressed(action_right) and facing_right) or (key_pressed(action_left) and not facing_right)
		if holding_forward:
			start_fair()
			return
		start_nair()
		return

	if abs(velocity.x) > 450:
		start_dash_attack()
		return

	if key_pressed(action_up):
		if smash_tap_timer > 0:
			start_upsmash()
			return
		start_uptilt()
		return

	if key_pressed(action_down):
		if smash_tap_timer > 0:
			start_dsmash()
			return
		start_dtilt()
		return

	var holding_forward = (key_pressed(action_right) and facing_right) or (key_pressed(action_left) and not facing_right)
	if holding_forward and abs(velocity.x) <= 450:
		var smash_dir = 1 if key_pressed(action_right) else -1
		if smash_tap_timer > 0 and smash_tap_dir == smash_dir:
			start_fsmash()
			return
		start_ftilt()
		return

	if attacking:
		buffered_attack = true
	else:
		start_attack(1)


func start_attack(index):
	attacking = true
	can_chain = false
	jab_index = index
	AudioManager.play("attack")

	if index > MAX_JAB:
		reset_attack()
		return

	velocity.x *= 0.15

	match index:
		1:
			current_attack_key = "jab1"
			var push_dir = 1 if facing_right else -1
			velocity.x += 80 * push_dir
			anim.play("jab1")
			anim_player.play("jab1")
		2:
			current_attack_key = "jab2"
			var push_dir = 1 if facing_right else -1
			velocity.x += 60 * push_dir
			anim.play("jab2")
			anim_player.play("jab2")
		3:
			current_attack_key = "jab3"
			var push_dir = 1 if facing_right else -1
			velocity.x += 120 * push_dir
			anim.play("jab3")
			anim_player.play("jab3")


func start_uptilt():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	current_attack_key = "uptilt"
	velocity.x *= 0.0
	anim.play("uptilt")
	anim_player.play("uptilt")
	AudioManager.play("attack")


func start_ftilt():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	current_attack_key = "ftilt"
	velocity.x = 0.0
	anim.play("ftilt")
	anim_player.play("ftilt")
	AudioManager.play("attack")


func start_dtilt():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	current_attack_key = "dtilt"
	velocity.x = 0.0
	anim.play("dtilt")
	anim_player.play("dtilt")
	AudioManager.play("attack")


func start_dash_attack():
	is_running = false
	is_dashing = false
	attacking = true
	dash_attacking = true
	buffered_attack = false
	jab_index = 0
	current_attack_key = "dash_attack"
	dash_attack_dir = 1 if facing_right else -1
	dash_attack_time = dash_attack_duration
	velocity.x = 500 * dash_attack_dir
	anim.play("dash_attack")
	anim_player.play("dash_attack")
	AudioManager.play("attack")


func start_nair():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	current_attack_key = "nair"
	velocity.x *= 0.6
	anim.play("nair")
	anim_player.play("nair")
	AudioManager.play("attack")


func start_bair():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	current_attack_key = "bair"
	anim.play("bair")
	anim_player.play("bair")
	AudioManager.play("attack")


func start_fair():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	current_attack_key = "fair"
	anim.play("fair")
	anim_player.play("fair")
	AudioManager.play("attack")


func start_dair():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	current_attack_key = "dair"
	velocity.x *= 0.3
	velocity.y *= 0.2
	anim.play("dair")
	anim_player.play("dair")
	AudioManager.play("attack")


func start_upair():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	current_attack_key = "upair"
	velocity.x *= 0.8
	anim.play("upair")
	anim_player.play("upair")
	AudioManager.play("attack")


func start_fsmash():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	is_charging = true
	charge_timer = 0.0
	current_attack_key = "fsmash"
	velocity.x = 0.0
	anim.play("fsmash_charge")


func release_fsmash():
	is_charging = false
	var charge_ratio = clamp(charge_timer / CHARGE_MAX, 0.0, 1.0)
	fsmash_charged_damage = FSMASH_BASE_DAMAGE * (1.0 + charge_ratio * 1.5)
	fsmash_charged_knockback = FSMASH_BASE_KNOCKBACK * (1.0 + charge_ratio * 1.3)
	var push_dir = 1 if facing_right else -1
	velocity.x = 150.0 * push_dir
	anim.play("fsmash")
	AudioManager.play("smash")
	await get_tree().create_timer(0.5).timeout
	reset_attack()


func start_upsmash():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	is_charging = true
	charge_timer = 0.0
	current_attack_key = "upsmash"
	velocity.x = 0.0
	anim.play("upsmash_charge")


func release_upsmash():
	is_charging = false
	var charge_ratio = clamp(charge_timer / CHARGE_MAX, 0.0, 1.0)
	upsmash_charged_damage = UPSMASH_BASE_DAMAGE * (1.0 + charge_ratio * 1.5)
	upsmash_charged_knockback = UPSMASH_BASE_KNOCKBACK * (1.0 + charge_ratio * 1.3)
	anim.play("upsmash")
	AudioManager.play("smash")
	await get_tree().create_timer(0.5).timeout
	reset_attack()


func start_dsmash():
	attacking = true
	dash_attacking = false
	buffered_attack = false
	is_charging = true
	charge_timer = 0.0
	current_attack_key = "dsmash"
	velocity.x = 0.0
	anim.play("dsmash_charge")


func release_dsmash():
	is_charging = false
	var charge_ratio = clamp(charge_timer / CHARGE_MAX, 0.0, 1.0)
	dsmash_charged_damage = DSMASH_BASE_DAMAGE * (1.0 + charge_ratio * 1.5)
	dsmash_charged_knockback = DSMASH_BASE_KNOCKBACK * (1.0 + charge_ratio * 1.3)
	anim.play("dsmash")
	AudioManager.play("smash")
	await get_tree().create_timer(0.5).timeout
	reset_attack()


func _calculate_hitstun(knockback: float, damage: float) -> float:
	if knockback > 0.0:
		var knockback_scaled = knockback * (1.0 + GameManager.get_percentage(player) / 100.0)
		return clamp(HITSTUN_BASE + knockback_scaled * HITSTUN_KNOCKBACK_SCALE, HITSTUN_BASE, HITSTUN_MAX)
	else:
		return clamp(HITSTUN_BASE + damage * 0.01, HITSTUN_BASE, 0.22)


func apply_hitstun_shake(direction: int):
	var original_x = position.x
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(self, "position:x", original_x + (8 * direction), 0.04)
		tween.tween_property(self, "position:x", original_x - (4 * direction), 0.04)
	tween.tween_property(self, "position:x", original_x, 0.04)


func receive_hit(attack_key: String, direction: int, attacker: Node = null, attacker_pos: Vector2 = Vector2.ZERO):
	if not ATTACK_DATA.has(attack_key):
		return

	if respawn_invincible:
		respawn_invincible = false
		respawn_invincible_timer = 0.0
		anim.modulate = GameManager.player_data[player]["tint"]

	var damage: float
	var knockback_base: float


	if attack_key == "fsmash" and attacker != null:
		damage = attacker.fsmash_charged_damage
		knockback_base = attacker.fsmash_charged_knockback
	elif attack_key == "upsmash" and attacker != null:
		damage = attacker.upsmash_charged_damage
		knockback_base = attacker.upsmash_charged_knockback
	elif attack_key == "dsmash" and attacker != null:
		damage = attacker.dsmash_charged_damage
		knockback_base = attacker.dsmash_charged_knockback
	else:
		var data = ATTACK_DATA[attack_key]
		damage = data["damage"]
		knockback_base = data["knockback"]

	var angle_deg: float = ATTACK_DATA[attack_key]["angle"]

	GameManager.add_percentage(player, damage)
	reset_attack()

	is_in_hitstun = true
	hitstun_timer = _calculate_hitstun(knockback_base, damage)

	anim.play("damage")

	var pct = GameManager.get_percentage(player)

	if knockback_base > 0.0:
		var knockback_scaled = knockback_base * (1.0 + pct / 100.0)
		knockback_scaled = min(knockback_scaled, 3000.0)

		if attack_key == "nair" and attacker_pos != Vector2.ZERO:
			var diff = global_position - attacker_pos
			var real_angle = diff.angle()
			velocity.x = cos(real_angle) * knockback_scaled
			velocity.y = sin(real_angle) * knockback_scaled
		elif attack_key == "dtilt" and attacker_pos != Vector2.ZERO:
			var target = attacker_pos + Vector2(0, -80)
			var diff = target - global_position
			var real_angle = diff.angle()
			velocity.x = cos(real_angle) * knockback_scaled
			velocity.y = sin(real_angle) * knockback_scaled
		else:
			var angle_rad = deg_to_rad(angle_deg)
			velocity.x = cos(angle_rad) * knockback_scaled * direction
			velocity.y = -sin(angle_rad) * knockback_scaled
	else:
		velocity.x = ATTACK_DATA[attack_key]["hitstun_push"] * direction
		apply_hitstun_shake(direction)

	if attacker != null:
		GameManager.set_last_attacker(player, attacker.player)

	var ui = get_tree().get_first_node_in_group("percentage_ui")
	if ui:
		ui.update_percentage(player, pct)

	var angle_rad_check = deg_to_rad(angle_deg)
	var vy = -sin(angle_rad_check)
	print("angle_deg: ", angle_deg, " | vy: ", vy)
	if vy > 0.3:
		pending_fallen = true
	print("pending_fallen ativado!")
	AudioManager.play("attack")
	print("Player ", player, " tomou hit! Porcentagem: ", pct, "% | Hitstun: ", hitstun_timer, "s")


func die():
	if is_dead:
		return
	is_dead = true
	
	GameManager.player_died(player)
	
	if GameManager.get_stocks(player) <= 0:
		queue_free()
		return

	GameManager.reset_percentage(player)
	velocity = Vector2.ZERO
	reset_attack()
	_end_hitstun()

	var ui = get_tree().get_first_node_in_group("percentage_ui")
	if ui:
		ui.update_percentage(player, 0.0)

	visible = false
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	_start_respawn_float()


func _start_respawn_float():
	
	visible = true
	is_dead = false
	velocity = Vector2.ZERO
	AudioManager.play("appear")

	var tween = create_tween()
	tween.tween_property(self, "global_position", spawn_position, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	respawn_invincible = true
	respawn_invincible_timer = RESPAWN_INVINCIBLE_TIME
	_start_blink()

	print("Player %d respawnou! Stocks: %d" % [player, GameManager.get_stocks(player)])


func _start_blink():
	var base_color = GameManager.player_data[player]["tint"]
	while respawn_invincible:
		anim.modulate = Color(base_color.r, base_color.g, base_color.b, 0.3)
		await get_tree().create_timer(0.15).timeout
		anim.modulate = Color(base_color.r, base_color.g, base_color.b, 1.0)
		await get_tree().create_timer(0.15).timeout
	anim.modulate = base_color


func enable_chain():
	can_chain = true


func reset_attack():
	attacking = false
	dash_attacking = false
	is_charging = false
	charge_timer = 0.0
	jab_index = 0
	can_chain = false
	hit_landed = false

	ATTACK_DATA["fsmash"]["damage"] = FSMASH_BASE_DAMAGE
	ATTACK_DATA["fsmash"]["knockback"] = FSMASH_BASE_KNOCKBACK
	ATTACK_DATA["upsmash"]["damage"] = UPSMASH_BASE_DAMAGE
	ATTACK_DATA["upsmash"]["knockback"] = UPSMASH_BASE_KNOCKBACK
	ATTACK_DATA["dsmash"]["damage"] = DSMASH_BASE_DAMAGE
	ATTACK_DATA["dsmash"]["knockback"] = DSMASH_BASE_KNOCKBACK

	current_attack_key = ""


func activate_hitbox():
	hitbox.monitoring = true


func deactivate_hitbox():
	hitbox.monitoring = false


func handle_animation():
	if is_in_hitstun:
		return
	if dash_attacking:
		return
	if attacking:
		return
	if is_charging:
		return

	var new_anim = "idle"

	if is_dashing and is_on_floor():
		new_anim = "dash"
	elif not is_on_floor():
		if velocity.y < 0:
			new_anim = "jump"
		else:
			new_anim = "fall"
	elif is_running:
		new_anim = "running"
	elif velocity.x != 0:
		new_anim = "run"

	if anim.animation != new_anim:
		anim.play(new_anim)


func handle_dash_attack(delta):
	dash_attack_time -= delta
	velocity.x = move_toward(velocity.x, 200 * dash_attack_dir, 900 * delta)
	if dash_attack_time <= 0:
		dash_attacking = false
		reset_attack()


func flip():
	facing_right = !facing_right
	scale.x *= -1


func hitbox_handler():
	const ALL_HITBOXES = ["HitJab1", "HitJab2", "DashAttack", "Nair", "Uptilt", "Ftilt", "Bair", "Fair", "Dair", "Dtilt", "Upair", "Fsmash", "Upsmash", "Dsmash"]

	const ATTACK_HITBOX = {
		"nair":        "Nair",
		"uptilt":      "Uptilt",
		"ftilt":       "Ftilt",
		"bair":        "Bair",
		"fair":        "Fair",
		"dair":        "Dair",
		"dtilt":       "Dtilt",
		"upair":       "Upair",
		"dash_attack": "DashAttack",
		"fsmash":      "Fsmash",
		"upsmash":     "Upsmash",
		"dsmash":      "Dsmash",
	}

	for h in ALL_HITBOXES:
		$Hitbox.get_node(h).disabled = true

	if is_in_hitstun:
		return

	if dash_attacking:
		$Hitbox/DashAttack.disabled = false
		return

	if current_attack_key in ATTACK_HITBOX:
		var is_smash = current_attack_key in ["fsmash", "upsmash", "dsmash"]
		if is_smash and is_charging:
			return
		$Hitbox.get_node(ATTACK_HITBOX[current_attack_key]).disabled = false
		return

	if jab_index == 1 or jab_index == 2:
		$Hitbox/HitJab1.disabled = false
	elif jab_index == 3:
		$Hitbox/HitJab2.disabled = false


func _on_animation_player_animation_finished(anim_name):
	if is_in_hitstun:
		return
	if buffered_attack and jab_index < MAX_JAB:
		buffered_attack = false
		hit_landed = false
		start_attack(jab_index + 1)
	else:
		reset_attack()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if respawn_invincible:
		return
	if is_fallen:
		return
	if area.is_in_group("attack") and not area.get_parent().is_in_group(playerG):
		var attacker = area.get_parent()
		if attacker.hit_landed:
			return
		attacker.hit_landed = true
		var knockback_dir = 1 if attacker.global_position.x < global_position.x else -1
		receive_hit(attacker.current_attack_key, knockback_dir, attacker, attacker.global_position)


func _on_animated_sprite_2d_animation_finished() -> void:
	pass
