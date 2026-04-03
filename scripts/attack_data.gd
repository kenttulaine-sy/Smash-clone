# Attack Data Resource
# Defines properties for each attack in the game

class_name AttackData
extends Resource

enum AttackType {
	JAB,
	FORWARD_TILT,
	UP_TILT,
	DOWN_TILT,
	FORWARD_SMASH,
	UP_SMASH,
	DOWN_SMASH,
	NEUTRAL_AIR,
	FORWARD_AIR,
	BACK_AIR,
	UP_AIR,
	DOWN_AIR
}

@export var attack_name: String = "Unnamed Attack"
@export var attack_type: AttackType = AttackType.JAB

# Frame data (at 60fps)
@export var startup_frames: int = 3      # Frames before hitbox appears
@export var active_frames: int = 4       # Frames hitbox is active
@export var recovery_frames: int = 10    # Frames after hitbox ends
@export var total_frames: int = 17       # Total animation length

# Damage and knockback
@export var base_damage: float = 5.0
@export var base_knockback: float = 150.0
@export var knockback_angle: float = 45.0  # Degrees
@export var knockback_scaling: float = 1.0  # How much % affects knockback

# Hitbox properties
@export var hitbox_offset: Vector2 = Vector2(40, 0)
@export var hitbox_size: Vector2 = Vector2(50, 40)

# Effects
@export var hit_pause_frames: int = 8     # Freeze frames on hit
@export var hitstun_frames: int = 15       # Opponent stun duration
@export var sound_effect: String = ""

# Special properties
@export var is_spike: bool = false        # Sends opponent downward
@export var is_meteor_smash: bool = false  # Stronger spike
@export var can_kill: bool = false        # High knockback growth

func get_total_duration() -> float:
	return total_frames / 60.0

func get_startup_time() -> float:
	return startup_frames / 60.0

func get_active_time() -> float:
	return active_frames / 60.0

func get_recovery_time() -> float:
	return recovery_frames / 60.0

func calculate_damage(charge_percent: float = 0.0) -> float:
	return base_damage + (base_damage * charge_percent * 0.5)

func calculate_knockback(opponent_damage: float, charge_percent: float = 0.0) -> float:
	var percent_factor = 1.0 + (opponent_damage / 100.0) * knockback_scaling
	var charge_factor = 1.0 + (charge_percent * 0.7)
	return base_knockback * percent_factor * charge_factor
