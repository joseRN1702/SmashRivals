extends Node

signal stock_changed(player_id: int, stocks_left: int)
signal percentage_changed(player_id: int, percentage: float)
signal player_eliminated(player_id: int)
signal kill_registered(killer_id: int, victim_id: int)
const CHARACTER_SELECT := "res://scenes/character_select.tscn"

@export var starting_stocks: int = 3

var player_data := {}

# SELEÇÃO DE PERSONAGENS
const CHARACTERS = {
	"rock":     { "scene": "res://characters/rock.tscn",     "name": "Pedra"   },
	"paper":    { "scene": "res://characters/paper.tscn",    "name": "Papel"   },
	"scissors": { "scene": "res://characters/scissors.tscn", "name": "Tesoura" },
}

const CHAR_KEYS = ["rock", "paper", "scissors"]

var slot_data := {
	1: { "state": "player", "char_index": 0, "device": -1, "ready": false },
	2: { "state": "player", "char_index": 1, "device": -1, "ready": false },
	3: { "state": "empty",  "char_index": 0, "device": -1, "ready": false },
	4: { "state": "empty",  "char_index": 0, "device": -1, "ready": false },
}

var character_count := {}


func reset_selection():
	character_count = {}
	player_data = {}
	slot_data = {
		1: { "state": "player", "char_index": 0, "device": -1, "ready": false },
		2: { "state": "player", "char_index": 1, "device": -1, "ready": false },
		3: { "state": "empty",  "char_index": 0, "device": -1, "ready": false },
		4: { "state": "empty",  "char_index": 0, "device": -1, "ready": false },
	}


func all_ready() -> bool:
	var active = []
	for slot_id in slot_data:
		if slot_data[slot_id]["state"] != "empty":
			active.append(slot_data[slot_id])
	if active.size() < 2:
		return false
	for slot in active:
		if not slot["ready"]:
			return false
	return true


func register_player(player_id: int, stocks: int = starting_stocks):
	player_data[player_id] = {
		"stocks": stocks,
		"percentage": 0.0,
		"kills": 0,
		"last_attacker": -1,
		"tint": Color(1, 1, 1)
	}


func add_percentage(player_id: int, amount: float):
	if not player_data.has(player_id):
		return
	player_data[player_id]["percentage"] += amount
	emit_signal("percentage_changed", player_id, player_data[player_id]["percentage"])


func reset_percentage(player_id: int):
	if not player_data.has(player_id):
		return
	player_data[player_id]["percentage"] = 0.0
	emit_signal("percentage_changed", player_id, 0.0)


func get_percentage(player_id: int) -> float:
	return player_data.get(player_id, {}).get("percentage", 0.0)


func set_last_attacker(victim_id: int, attacker_id: int):
	if player_data.has(victim_id):
		player_data[victim_id]["last_attacker"] = attacker_id


func player_died(victim_id: int):
	if not player_data.has(victim_id):
		return
	var attacker_id = player_data[victim_id]["last_attacker"]
	if attacker_id != -1 and player_data.has(attacker_id):
		player_data[attacker_id]["kills"] += 1
		emit_signal("kill_registered", attacker_id, victim_id)
		print("Player %d matou Player %d! (kills: %d)" % [attacker_id, victim_id, player_data[attacker_id]["kills"]])
	player_data[victim_id]["stocks"] -= 1
	emit_signal("stock_changed", victim_id, player_data[victim_id]["stocks"])
	if player_data[victim_id]["stocks"] <= 0:
		emit_signal("player_eliminated", victim_id)
		print("Player %d foi eliminado!" % victim_id)
	else:
		print("Player %d: %d stock(s) restante(s)" % [victim_id, player_data[victim_id]["stocks"]])


func get_stocks(player_id: int) -> int:
	return player_data.get(player_id, {}).get("stocks", 0)


func get_kills(player_id: int) -> int:
	return player_data.get(player_id, {}).get("kills", 0)


func count_character(char_id: String) -> int:
	var count = character_count.get(char_id, 0)
	character_count[char_id] = count + 1
	return count


func register_player_tint(player_id: int, tint: Color):
	if player_data.has(player_id):
		player_data[player_id]["tint"] = tint
