# Player State Machine for Smash-style Combat
# Manages all player states and transitions

extends Node
class_name PlayerStateMachine

enum State {
	IDLE,
	RUN,
	JUMP_SQUAT,
	AIRBORNE,
	ATTACK_GROUND,
	ATTACK_AIR,
	SHIELD,
	DODGE,
	GRAB,
	GRABBED,
	LEDGE_HANG,
	HITSTUN,
	LANDING_LAG,
	DEAD,
	RESPAWN
}

var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var state_timer: float = 0.0

# State durations (in seconds)
const JUMP_SQUAT_TIME: float = 0.08  # 5 frames at 60fps
const LANDING_LAG_LIGHT: float = 0.067  # 4 frames
const LANDING_LAG_HEAVY: float = 0.167  # 10 frames

signal state_changed(new_state, old_state)
signal attack_started(attack_type)
signal attack_ended()

func _ready():
	pass

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
		
	previous_state = current_state
	current_state = new_state
	state_timer = 0.0
	state_changed.emit(new_state, previous_state)

func update(delta: float) -> void:
	state_timer += delta

func is_attacking() -> bool:
	return current_state == State.ATTACK_GROUND or current_state == State.ATTACK_AIR

func is_grounded() -> bool:
	return current_state in [State.IDLE, State.RUN, State.ATTACK_GROUND, State.SHIELD, State.LANDING_LAG]

func can_move() -> bool:
	return current_state in [State.IDLE, State.RUN, State.AIRBORNE]

func can_attack() -> bool:
	return current_state in [State.IDLE, State.RUN, State.AIRBORNE]

func is_invulnerable() -> bool:
	return current_state in [State.DEAD, State.RESPAWN] or state_timer < 2.0 and previous_state == State.RESPAWN

func get_state_name() -> String:
	match current_state:
		State.IDLE: return "IDLE"
		State.RUN: return "RUN"
		State.JUMP_SQUAT: return "JUMP_SQUAT"
		State.AIRBORNE: return "AIRBORNE"
		State.ATTACK_GROUND: return "ATTACK_GROUND"
		State.ATTACK_AIR: return "ATTACK_AIR"
		State.SHIELD: return "SHIELD"
		State.HITSTUN: return "HITSTUN"
		State.LANDING_LAG: return "LANDING_LAG"
		State.DEAD: return "DEAD"
		State.RESPAWN: return "RESPAWN"
		_: return "UNKNOWN"
