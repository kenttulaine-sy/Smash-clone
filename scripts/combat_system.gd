# Combat System Module
# Modular platform fighter combat with Smash-style mechanics
# Clean, tunable, no external dependencies

class_name CombatSystem
extends RefCounted

# ============================================================================
# TUNABLE COMBAT CONSTANTS
# ============================================================================

# Damage & Knockback
const BASE_DAMAGE: float = 5.0              # Starting damage per hit
const KNOCKBACK_SCALE: float = 0.12         # % damage multiplier (higher = more scaling)
const BASE_KNOCKBACK: float = 200.0         # Minimum knockback force
const MAX_KNOCKBACK: float = 1200.0        # Maximum knockback cap

# Hitstun
const BASE_HITSTUN: float = 0.3             # Seconds of stun at 0% damage
const HITSTUN_SCALE: float = 0.004           # Additional stun per % damage
const MAX_HITSTUN: float = 1.5              # Cap hitstun duration

# Hit Pause (freeze frame effect)
const HIT_PAUSE_DURATION: float = 0.05      # Seconds to freeze on hit
const HIT_PAUSE_SCALE: float = 0.001        # Additional freeze per damage

# Damage Caps
const MAX_DAMAGE_PERCENT: float = 999.0     # Maximum damage accumulation

# ============================================================================
# ATTACK DATA STRUCTURE
# ============================================================================

class Attack extends RefCounted:
	var name: String = "Unnamed"
	var startup_frames: int = 3          # Frames before hitbox active
	var active_frames: int = 4           # Frames hitbox stays out
	var recovery_frames: int = 10        # Frames after hitbox ends
	
	var damage: float = 5.0
	var base_knockback: float = 200.0
	var knockback_angle: float = 45.0    # 0 = right, 90 = up, etc.
	var knockback_growth: float = 1.0    # How much % affects this attack
	
	var hitbox_size: Vector2 = Vector2(50, 40)
	var hitbox_offset: Vector2 = Vector2(40, 0)
	
	func get_total_duration() -> float:
		return (startup_frames + active_frames + recovery_frames) / 60.0
	
	func get_startup_time() -> float:
		return startup_frames / 60.0
	
	func get_active_time() -> float:
		return active_frames / 60.0

# ============================================================================
# ATTACK REGISTRY - Factory for creating standard attacks
# ============================================================================

static var attacks: Dictionary = {}

static func register_attacks() -> Dictionary:
	"""Register and return all attacks in a dictionary."""
	if attacks.is_empty():
		attacks["jab"] = create_jab()
		attacks["forward_tilt"] = create_forward_tilt()
		attacks["up_tilt"] = create_up_tilt()
		attacks["down_tilt"] = create_down_tilt()
		attacks["forward_smash"] = create_forward_smash()
		attacks["up_smash"] = create_up_smash()
		attacks["neutral_air"] = create_neutral_air()
		attacks["forward_air"] = create_forward_air()
		attacks["back_air"] = create_back_air()
		attacks["up_air"] = create_up_air()
		attacks["down_air"] = create_down_air()
	return attacks.duplicate()

static func get_attack(name: String) -> Attack:
	if attacks.is_empty():
		register_attacks()
	return attacks.get(name, attacks["jab"])

# ============================================================================
# ATTACK FACTORY METHODS
# ============================================================================

static func create_jab() -> Attack:
	var atk = Attack.new()
	atk.name = "Jab"
	atk.startup_frames = 2
	atk.active_frames = 3
	atk.recovery_frames = 8
	atk.damage = 4.0
	atk.base_knockback = 150.0
	atk.knockback_angle = 45.0
	atk.hitbox_size = Vector2(50, 40)
	atk.hitbox_offset = Vector2(35, 0)
	return atk

static func create_forward_tilt() -> Attack:
	var atk = Attack.new()
	atk.name = "Forward Tilt"
	atk.startup_frames = 5
	atk.active_frames = 4
	atk.recovery_frames = 14
	atk.damage = 8.0
	atk.base_knockback = 280.0
	atk.knockback_angle = 35.0
	atk.hitbox_size = Vector2(60, 45)
	atk.hitbox_offset = Vector2(45, 0)
	return atk

static func create_up_tilt() -> Attack:
	var atk = Attack.new()
	atk.name = "Up Tilt"
	atk.startup_frames = 4
	atk.active_frames = 5
	atk.recovery_frames = 12
	atk.damage = 7.0
	atk.base_knockback = 220.0
	atk.knockback_angle = 80.0
	atk.hitbox_size = Vector2(45, 55)
	atk.hitbox_offset = Vector2(0, -40)
	return atk

static func create_down_tilt() -> Attack:
	var atk = Attack.new()
	atk.name = "Down Tilt"
	atk.startup_frames = 5
	atk.active_frames = 4
	atk.recovery_frames = 13
	atk.damage = 6.0
	atk.base_knockback = 180.0
	atk.knockback_angle = -20.0
	atk.hitbox_size = Vector2(55, 35)
	atk.hitbox_offset = Vector2(40, 20)
	return atk

static func create_forward_smash() -> Attack:
	var atk = Attack.new()
	atk.name = "Forward Smash"
	atk.startup_frames = 12
	atk.active_frames = 5
	atk.recovery_frames = 32
	atk.damage = 15.0
	atk.base_knockback = 450.0
	atk.knockback_growth = 1.3
	atk.knockback_angle = 40.0
	atk.hitbox_size = Vector2(70, 50)
	atk.hitbox_offset = Vector2(55, 0)
	return atk

static func create_up_smash() -> Attack:
	var atk = Attack.new()
	atk.name = "Up Smash"
	atk.startup_frames = 10
	atk.active_frames = 6
	atk.recovery_frames = 28
	atk.damage = 14.0
	atk.base_knockback = 400.0
	atk.knockback_growth = 1.2
	atk.knockback_angle = 85.0
	atk.hitbox_size = Vector2(50, 65)
	atk.hitbox_offset = Vector2(0, -50)
	return atk

static func create_neutral_air() -> Attack:
	var atk = Attack.new()
	atk.name = "Neutral Air"
	atk.startup_frames = 4
	atk.active_frames = 6
	atk.recovery_frames = 14
	atk.damage = 7.0
	atk.base_knockback = 200.0
	atk.knockback_angle = 45.0
	atk.hitbox_size = Vector2(55, 55)
	atk.hitbox_offset = Vector2(0, 0)
	return atk

static func create_forward_air() -> Attack:
	var atk = Attack.new()
	atk.name = "Forward Air"
	atk.startup_frames = 6
	atk.active_frames = 4
	atk.recovery_frames = 18
	atk.damage = 10.0
	atk.base_knockback = 300.0
	atk.knockback_angle = 30.0
	atk.hitbox_size = Vector2(60, 45)
	atk.hitbox_offset = Vector2(45, 0)
	return atk

static func create_back_air() -> Attack:
	var atk = Attack.new()
	atk.name = "Back Air"
	atk.startup_frames = 5
	atk.active_frames = 4
	atk.recovery_frames = 16
	atk.damage = 11.0
	atk.base_knockback = 320.0
	atk.knockback_angle = 145.0
	atk.hitbox_size = Vector2(60, 45)
	atk.hitbox_offset = Vector2(-45, 0)
	return atk

static func create_up_air() -> Attack:
	var atk = Attack.new()
	atk.name = "Up Air"
	atk.startup_frames = 5
	atk.active_frames = 5
	atk.recovery_frames = 14
	atk.damage = 9.0
	atk.base_knockback = 240.0
	atk.knockback_angle = 85.0
	atk.hitbox_size = Vector2(45, 50)
	atk.hitbox_offset = Vector2(0, -45)
	return atk

static func create_down_air() -> Attack:
	var atk = Attack.new()
	atk.name = "Down Air"
	atk.startup_frames = 6
	atk.active_frames = 4
	atk.recovery_frames = 20
	atk.damage = 10.0
	atk.base_knockback = 280.0
	atk.knockback_angle = -70.0
	atk.hitbox_size = Vector2(50, 40)
	atk.hitbox_offset = Vector2(0, 40)
	return atk

# ============================================================================
# COMBAT CALCULATIONS
# ============================================================================

static func calculate_knockback(attack: Attack, defender_damage: float, charge_percent: float = 0.0) -> float:
	"""
	Calculate knockback force based on:
	- Attack's base knockback
	- Defender's current damage % (higher = more knockback)
	- Attack's knockback growth multiplier
	- Optional charge percentage (for smash attacks)
	"""
	var damage_factor = 1.0 + (defender_damage * KNOCKBACK_SCALE * attack.knockback_growth / 100.0)
	var charge_factor = 1.0 + (charge_percent * 0.6)
	var knockback = attack.base_knockback * damage_factor * charge_factor
	return clamp(knockback, BASE_KNOCKBACK, MAX_KNOCKBACK)

static func calculate_hitstun(attack: Attack, defender_damage: float) -> float:
	"""
	Calculate hitstun duration based on knockback received.
	More damage = longer stun.
	"""
	var knockback = calculate_knockback(attack, defender_damage)
	var stun = BASE_HITSTUN + (knockback * HITSTUN_SCALE)
	return clamp(stun, 0.0, MAX_HITSTUN)

static func calculate_launch_velocity(knockback: float, angle_degrees: float, facing_right: bool) -> Vector2:
	"""
	Convert knockback force and angle to velocity vector.
	Angle: 0 = right, 90 = up, 180 = left, -90 = down
	"""
	var angle_rad = deg_to_rad(angle_degrees)
	
	# If facing left, flip horizontal component
	if not facing_right:
		angle_rad = PI - angle_rad
	
	var x = cos(angle_rad) * knockback
	var y = -sin(angle_rad) * knockback  # Negative because Y is down in Godot
	
	return Vector2(x, y)

static func apply_damage(current_damage: float, attack_damage: float) -> float:
	"""
	Add damage with cap.
	"""
	return clamp(current_damage + attack_damage, 0.0, MAX_DAMAGE_PERCENT)

static func get_hit_pause_duration(attack_damage: float) -> float:
	"""
	Calculate freeze-frame duration on hit (visual impact feel).
	"""
	return clamp(HIT_PAUSE_DURATION + (attack_damage * HIT_PAUSE_SCALE), 0.0, 0.15)
