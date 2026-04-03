# Player Controller v2.2 - Premium Movement Polish
# Snappy, responsive, competitive-grade platform fighter controls

extends CharacterBody2D
class_name SmashFighter

const CombatSystem = preload("res://scripts/combat_system.gd")
const Model3DManager = preload("res://scripts/model_3d_manager.gd")
const PlayerStateMachine = preload("res://scripts/player_states.gd")

# ============================================================================
# PREMIUM MOVEMENT TUNING - ADJUST THESE FOR GAME FEEL
# ============================================================================

# --- GROUND MOVEMENT ---
const RUN_SPEED: float = 520.0              # Max run velocity
const GROUND_ACCEL: float = 8000.0          # INSTANT: Was 3500, now 8000 for immediate response
const GROUND_DECEL: float = 6000.0          # Quick stop (was 4500)
const PIVOT_BOOST: float = 1.3              # 30% speed boost on direction change
const INITIAL_MOVE_BURST: float = 150.0     # Immediate velocity on first frame of movement

# --- AIR MOVEMENT ---
const AIR_SPEED_CAP: float = 380.0          # Max horizontal air speed
const AIR_ACCEL: float = 2200.0             # Was 1800, now 2200 for snappier air control
const AIR_DECEL: float = 1200.0             # Was 800, now 1200 for tighter air stops
const AIR_STOP_THRESHOLD: float = 20.0      # Stop completely below this speed

# --- JUMP PHYSICS ---
const JUMP_FORCE: float = -850.0            # Upward velocity
const SHORT_HOP_FORCE: float = -450.0       # Tap jump height
const DOUBLE_JUMP_FORCE: float = -780.0     # Aerial jump
const GRAVITY_SCALE: float = 1.0            # Gravity multiplier (1.0 = normal)

# --- FALLING ---
const GRAVITY: float = 2200.0               # Base gravity
const MAX_FALL_SPEED: float = 1100.0        # Terminal velocity
const FAST_FALL_SPEED: float = 1600.0       # Fast fall multiplier
const FAST_FALL_GRAVITY_MULT: float = 1.8   # Extra gravity when fast falling

# --- LANDING RECOVERY ---
const LANDING_LAG_FRAMES: int = 2           # Was 4 frames, now 2 (33ms vs 67ms)

# --- COYOTE TIME & BUFFERING ---
const COYOTE_TIME: float = 0.08               # 5 frames after leaving ground
const JUMP_BUFFER_TIME: float = 0.10          # 6 frames before landing

# --- ATTACK TUNING ---
const ATTACK_BUFFER_TIME: float = 0.08
const JAB_STARTUP_FRAMES: int = 2
const VISUAL_FLASH_DURATION: float = 0.05

# ============================================================================
# DEBUG FLAGS (for measuring input-to-response timing)
# ============================================================================
const DEBUG_MOVEMENT: bool = true           # Log state transitions
const DEBUG_INPUT_TIMING: bool = false     # Log input processing order

# === STAGE BOUNDARIES ===
const BLAST_ZONE_LEFT: float = -300
const BLAST_ZONE_RIGHT: float = 2220
const BLAST_ZONE_TOP: float = -300
const BLAST_ZONE_BOTTOM: float = 1380

# --- STATE VARIABLES ---
@export var player_id: int = 1  # 1 = player, 2 = opponent (1v1 only)
@export var stock_count: int = 3
var damage_percent: float = 0.0
var facing_right: bool = true
var jumps_remaining: int = 2
var is_fast_falling: bool = false

# --- 1V1 OPPONENT TRACKING ---
var opponent: Node = null  # Set in _ready, references the other player

# --- ATTACK DATA (for load_attacks) ---
const JAB_ACTIVE_FRAMES: int = 3
const JAB_RECOVERY_FRAMES: int = 10

# --- HITBOX DEBUG ---
const DEBUG_HITBOXES: bool = true  # Visualize hitbox/hurtbox
var hitbox_visual: ColorRect = null
var hurtbox_visual: ColorRect = null

# --- INPUT BUFFERS ---
var jump_buffer: float = 0.0
var attack_buffer: float = 0.0
var coyote_timer: float = 0.0
var landing_lag_timer: float = 0.0  # NEW: Track landing lag manually

# --- ATTACK STATE ---
var current_attack: CombatSystem.Attack = null
var attack_timer: float = 0.0
var hitbox_active: bool = false

# --- HITSTUN ---
var hitstun_timer: float = 0.0
var launch_velocity: Vector2 = Vector2.ZERO

# --- HIT COOLDOWN (prevents multi-hit per attack) ---
var hit_cooldown: float = 0.0  # Time until target can be hit again
const HIT_COOLDOWN_DURATION: float = 0.15  # 9 frames at 60fps

# --- ATTACK HIT TRACKING ---
var current_attack_has_hit: bool = false  # Track if current attack already landed a hit

# --- 3D MODEL ANIMATION ---
var character_3d: Node3D = null
var model_anim_timer: float = 0.0
const WALK_CYCLE_SPEED: float = 15.0
const PUNCH_RECOVERY: float = 0.3
var punch_timer: float = 0.0

# --- SHIELD & DODGE ---
var shield_health: float = 100.0
const SHIELD_MAX_HEALTH: float = 100.0
const SHIELD_DEGRADE_RATE: float = 15.0  # Health lost per second while shielding
const SHIELD_BREAK_STUN: float = 0.5  # Stun when shield breaks
var is_shielding: bool = false
var shield_node: ColorRect = null  # Visual shield

var dodge_timer: float = 0.0
const DODGE_DURATION: float = 0.25  # Invincibility frames
const DODGE_COOLDOWN: float = 0.5
var dodge_direction: float = 0.0  # -1 for left, 1 for right
var last_down_press: float = 0.0
const DOUBLE_TAP_WINDOW: float = 0.2  # Time between taps for double-tap

# --- MOVEMENT STATE ---
var was_on_floor: bool = false  # Track previous frame for coyote time
var last_input_x: float = 0.0   # Track direction for pivot detection

# === NODE REFERENCES ===
@onready var visuals: Node2D = $Visuals
@onready var state_machine: PlayerStateMachine = PlayerStateMachine.new()
@onready var hitbox_node: Area2D = $Hitbox
@onready var hurtbox_node: Area2D = $Hurtbox

# === ATTACKS ===
var attacks: Dictionary = {}

func _ready():
	add_child(state_machine)
	state_machine.state_changed.connect(_on_state_changed)
	
	# CRITICAL: Set up collision layers
	collision_layer = 2
	collision_mask = 7
	
	# Set up hitbox
	hitbox_node.collision_layer = 4
	hitbox_node.collision_mask = 8
	hitbox_node.area_entered.connect(_on_hitbox_area_entered)
	
	# Set up hurtbox
	hurtbox_node.collision_layer = 8
	hurtbox_node.collision_mask = 0
	
	# 1V1: Find opponent (the other player in scene)
	find_opponent()
	
	# Load modular combat system attacks
	load_attacks()
	
	# Initialize 3D model manager (replaces 2D visuals)
	setup_3d_model()
	
	# Setup shield visuals
	setup_shield()
	
	facing_right = (player_id == 2)
	update_facing()

func find_opponent() -> void:
	# 1V1: Find the other player node
	var parent = get_parent()
	for child in parent.get_children():
		if child is CharacterBody2D and child != self:
			if child.has_method("take_damage"):  # Verify it's a fighter
				opponent = child
				print("Player ", player_id, " found opponent: ", opponent.name)
				return
	print("Warning: Player ", player_id, " could not find opponent!")

func setup_3d_model() -> void:
	"""Use enhanced 2D visuals instead of problematic 3D"""
	
	# Keep 2D visuals but enhance them
	if visuals:
		visuals.visible = true
		
		# Make the body more visible
		var body = visuals.get_node_or_null("Body")
		if body:
			body.color = Color(0.2, 0.6, 1.0, 1.0) if player_id == 1 else Color(1.0, 0.3, 0.3, 1.0)
			body.size = Vector2(50, 70)  # Slightly larger
		
		# Add visual indicator for facing direction
		var indicator = ColorRect.new()
		indicator.name = "FacingIndicator"
		indicator.color = Color(1, 1, 0, 1)  # Yellow arrow
		indicator.size = Vector2(10, 10)
		indicator.position = Vector2(25, -25)  # Right side
		visuals.add_child(indicator)
	
	print("Player ", player_id, ": Enhanced 2D visuals ready")

func setup_shield() -> void:
	"""Create visual shield effect"""
	shield_node = ColorRect.new()
	shield_node.name = "ShieldVisual"
	shield_node.color = Color(0.3, 0.6, 1.0, 0.5)  # Blue translucent
	shield_node.size = Vector2(60, 80)
	shield_node.position = Vector2(-30, -40)
	shield_node.visible = false
	add_child(shield_node)

func update_model_animation(delta: float) -> void:
	"""Procedurally animate the 3D model based on player state"""
	if character_3d == null:
		return
	
	model_anim_timer += delta
	
	# Base rotation/position
	var base_rot = Vector3.ZERO
	var base_pos = Vector3(0, 100, 0)
	
	# Handle punch animation
	if punch_timer > 0:
		punch_timer -= delta
		var punch_progress = punch_timer / PUNCH_RECOVERY
		# Arm swing forward then back
		base_rot.z = -45 * sin(punch_progress * PI) * sign(punch_progress)
		base_pos.x = 20 * sin(punch_progress * PI)
	
	# Handle walking animation (only when moving on ground)
	elif abs(velocity.x) > 50 and is_on_floor():
		var walk_cycle = sin(model_anim_timer * WALK_CYCLE_SPEED)
		# Bob up and down
		base_pos.y += 10 * abs(walk_cycle)
		# Slight body tilt
		base_rot.z = 5 * walk_cycle
		# Arm swing
		base_rot.y = 15 * walk_cycle
	
	# Handle jumping animation
	elif not is_on_floor():
		# Lean into velocity
		base_rot.z = clamp(velocity.x * 0.05, -20, 20)
		# Arms up slightly
		base_rot.x = -10
	
	# Apply to model
	character_3d.rotation_degrees = base_rot
	character_3d.position = base_pos

func trigger_punch_animation() -> void:
	"""Trigger punch animation"""
	punch_timer = PUNCH_RECOVERY

func setup_hitbox_visuals() -> void:
	# Visualize hitbox and hurtbox for debugging
	if hitbox_node:
		hitbox_visual = ColorRect.new()
		hitbox_visual.color = Color(1, 0, 0, 0.3)  # Red, semi-transparent
		hitbox_visual.size = Vector2(50, 40)
		hitbox_visual.position = Vector2(-25, -20)
		hitbox_visual.visible = false
		hitbox_node.add_child(hitbox_visual)
	
	if hurtbox_node:
		hurtbox_visual = ColorRect.new()
		hurtbox_visual.color = Color(0, 1, 0, 0.3)  # Green, semi-transparent
		hurtbox_visual.size = Vector2(40, 60)
		hurtbox_visual.position = Vector2(-20, -30)
		hurtbox_node.add_child(hurtbox_visual)

func load_attacks():
	# Load attacks from modular combatSystem
	attacks = CombatSystem.register_attacks()
	print("Loaded ", attacks.size(), " modular attacks for 1v1 combat")

func _physics_process(delta):
	# === INPUT BUFFERING (Process FIRST before anything else) ===
	if jump_buffer > 0:
		jump_buffer -= delta
	if attack_buffer > 0:
		attack_buffer -= delta
	if coyote_timer > 0:
		coyote_timer -= delta
	
	# === HIT COOLDOWN ===
	if hit_cooldown > 0:
		hit_cooldown -= delta
		if hit_cooldown <= 0:
			print("  Player ", player_id, " hit cooldown ended - hittable again")
	
	# Check for buffered attack input FIRST - highest priority
	if attack_buffer > 0 and state_machine.can_attack():
		attack_buffer = 0
		trigger_attack_from_state()
		return
	
	# Check for jump input with coyote time (can jump shortly after leaving ground)
	var can_ground_jump = is_on_floor() or coyote_timer > 0
	if (get_input_jump() or jump_buffer > 0) and can_ground_jump and jumps_remaining >= 2:
		jump_buffer = 0
		coyote_timer = 0
		perform_ground_jump()
		return
	
	# Check for buffered jump that might have been pressed before landing
	if jump_buffer > 0 and state_machine.can_move():
		if is_on_floor() and jumps_remaining >= 2:
			jump_buffer = 0
			perform_ground_jump()
			return
	
	state_machine.update(delta)
	check_blast_zones()
	
	# PREMIUM: Track ground state for coyote time
	was_on_floor = is_on_floor()
	
	# Update 3D model animation
	update_model_animation(delta)
	
	# State machine
	match state_machine.current_state:
		PlayerStateMachine.State.IDLE:
			process_idle(delta)
		PlayerStateMachine.State.RUN:
			process_run(delta)
		PlayerStateMachine.State.JUMP_SQUAT:
			process_jump_squat(delta)
		PlayerStateMachine.State.AIRBORNE:
			process_airborne(delta)
		PlayerStateMachine.State.ATTACK_GROUND, PlayerStateMachine.State.ATTACK_AIR:
			process_attack(delta)
		PlayerStateMachine.State.SHIELD:
			process_shield(delta)
		PlayerStateMachine.State.DODGE:
			process_dodge(delta)
		PlayerStateMachine.State.HITSTUN:
			process_hitstun(delta)
		PlayerStateMachine.State.LANDING_LAG:
			process_landing_lag(delta)
		PlayerStateMachine.State.DEAD:
			process_dead(delta)
		PlayerStateMachine.State.RESPAWN:
			process_respawn(delta)

func process_idle(delta):
	apply_gravity(delta)
	
	var input_x = get_input_x()
	
	# PREMIUM: Immediate stop on no input
	if abs(input_x) < 0.1:
		# Hard stop - go to zero quickly
		if abs(velocity.x) < 50:
			velocity.x = 0  # Snap to zero when very slow
		else:
			velocity.x = move_toward(velocity.x, 0, GROUND_DECEL * delta)
	
	# PREMIUM: Instant movement start with burst
	if abs(input_x) > 0.1:
		# If starting from zero, add burst velocity immediately
		if abs(velocity.x) < 10:
			velocity.x = input_x * INITIAL_MOVE_BURST
			if DEBUG_MOVEMENT:
				print("Player ", player_id, ": MOVE BURST - velocity=", velocity.x)
		
		state_machine.change_state(PlayerStateMachine.State.RUN)
		return
	
	# Attack (jump handled at top of _physics_process for instant response)
	if get_input_attack():
		start_attack(attacks["jab"])
		return
	
	# Try shield (hold S/down)
	if try_shield():
		return
	
	move_and_slide()
	update_facing()

func process_run(delta):
	apply_gravity(delta)
	
	var input_x = get_input_x()
	
	# Try shield first
	if try_shield():
		return
	
	# PREMIUM: Snappy pivot with speed boost
	if input_x != 0 and sign(input_x) != sign(velocity.x) and abs(velocity.x) > 50:
		# Immediate direction flip with pivot boost
		velocity.x = -velocity.x * 0.5  # Preserve some momentum but flip
		velocity.x += input_x * RUN_SPEED * PIVOT_BOOST * 0.3  # Add pivot boost
		if DEBUG_MOVEMENT:
			print("Player ", player_id, ": PIVOT - velocity=", velocity.x)
		update_facing()
	
	# PREMIUM: Direct velocity approach for immediate response
	var target_speed = input_x * RUN_SPEED
	if abs(input_x) > 0.1:
		# Accelerate toward target
		velocity.x = move_toward(velocity.x, target_speed, GROUND_ACCEL * delta)
	else:
		# Transition to idle - let process_idle handle stopping
		state_machine.change_state(PlayerStateMachine.State.IDLE)
		return
	
	# Attack (jump handled at top of _physics_process for instant response)
	if get_input_attack():
		start_attack(attacks["forward_tilt"])
		return
	
	move_and_slide()
	update_facing()

func start_jump_squat():
	# DEPRECATED: Now using perform_ground_jump() for instant response
	# Kept for compatibility
	pass

func perform_ground_jump():
	# INSTANT JUMP: Apply velocity immediately, no delay
	var jump_force = JUMP_FORCE
	if not get_input_jump_held():
		jump_force = SHORT_HOP_FORCE
	
	velocity.y = jump_force
	jumps_remaining -= 1  # DECREMENT: was 2, now 1 (one air jump left)
	state_machine.change_state(PlayerStateMachine.State.AIRBORNE)
	
	# Visual feedback (works with 2D or 3D)
	flash_visual_feedback(Color(0.5, 0.8, 1.0, 1.0), 0.03)

func flash_visual_feedback(color: Color, duration: float) -> void:
	"""Flash character color for visual feedback (2D or 3D)"""
	var model_manager = get_node_or_null("Model3DManager")
	if model_manager:
		model_manager.flash_color(color, duration)
	else:
		# Fallback to 2D
		var body = visuals.get_node_or_null("Body")
		if body:
			var original_color = body.color
			body.color = color
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(body):
				body.color = original_color

func process_shield(delta: float) -> void:
	"""Shield state - blocks attacks but degrades over time"""
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, GROUND_DECEL * delta)  # Slow movement
	
	# Degrade shield
	shield_health -= SHIELD_DEGRADE_RATE * delta
	
	# Update shield visual size based on health
	if shield_node:
		var health_percent = shield_health / SHIELD_MAX_HEALTH
		shield_node.modulate.a = health_percent * 0.5  # Fade as it weakens
	
	# Check for shield break
	if shield_health <= 0:
		shield_health = 0
		shield_node.visible = false
		is_shielding = false
		state_machine.change_state(PlayerStateMachine.State.HITSTUN)
		print("Player ", player_id, ": SHIELD BROKEN!")
		return
	
	# Release shield if down input released
	if not get_input_down_held():
		is_shielding = false
		shield_node.visible = false
		state_machine.change_state(PlayerStateMachine.State.IDLE)
		return
	
	move_and_slide()

func process_dodge(delta: float) -> void:
	"""Dodge/Roll state - invincible movement"""
	apply_gravity(delta)
	
	# Continue dodge movement
	velocity.x = dodge_direction * RUN_SPEED * 1.5
	
	# Update timer
	dodge_timer -= delta
	
	# End dodge when timer expires
	if dodge_timer <= 0:
		velocity.x *= 0.3  # Slow down after dodge
		state_machine.change_state(PlayerStateMachine.State.IDLE)
		return
	
	move_and_slide()

func process_jump_squat(delta):
	# Deprecated - instant jump now handles this
	state_machine.change_state(PlayerStateMachine.State.AIRBORNE)

func process_airborne(delta):
	apply_gravity(delta)
	
	var input_x = get_input_x()
	
	# PREMIUM: Snappy air control with quick stops
	if abs(input_x) > 0.1:
		var target_speed = input_x * AIR_SPEED_CAP
		velocity.x = move_toward(velocity.x, target_speed, AIR_ACCEL * delta)
	else:
		# PREMIUM: Tighter air deceleration for crisp stops
		if abs(velocity.x) < AIR_STOP_THRESHOLD:
			velocity.x = 0  # Snap to stop when very slow
		else:
			velocity.x = move_toward(velocity.x, 0, AIR_DECEL * delta)
	
	# Fast fall
	if get_input_down() and velocity.y > 0 and not is_fast_falling:
		is_fast_falling = true
		velocity.y = FAST_FALL_SPEED * 0.3  # Quick snap to fast fall
		apply_gravity(delta * FAST_FALL_GRAVITY_MULT)  # Extra gravity
	
	# Double jump
	if get_input_jump_just_pressed() and jumps_remaining > 0:
		velocity.y = DOUBLE_JUMP_FORCE
		jumps_remaining -= 1
		create_double_jump_effect()
	
	# Air attack
	if get_input_attack():
		start_attack(attacks["neutral_air"])
		return
	
	# Landing
	if is_on_floor():
		is_fast_falling = false
		jumps_remaining = 2  # RESET: Full double jump restored on landing
		coyote_timer = 0  # Reset coyote time when grounded
		
		# PREMIUM: Fast landing recovery
		landing_lag_timer = LANDING_LAG_FRAMES / 60.0
		state_machine.change_state(PlayerStateMachine.State.LANDING_LAG)
		return
	
	# Not on floor - trigger coyote time if we just left ground
	if was_on_floor and not is_on_floor():
		coyote_timer = COYOTE_TIME
		was_on_floor = false
	
	move_and_slide()
	update_facing()

func process_attack(delta):
	attack_timer += delta
	
	if current_attack == null:
		end_attack()
		return
	
	var startup_time = current_attack.startup_frames / 60.0
	var active_start = startup_time
	var active_end = startup_time + (current_attack.active_frames / 60.0)
	var total_time = current_attack.get_total_duration()
	
	# Activate hitbox during active frames
	if attack_timer >= active_start and attack_timer < active_end:
		if not hitbox_active:
			activate_hitbox()
	elif attack_timer >= active_end:
		deactivate_hitbox()
	
	# End attack
	if attack_timer >= total_time:
		end_attack()
		return
	
	# Slow gravity during attack
	velocity.y += GRAVITY * delta * 0.3
	velocity.x *= 0.9
	move_and_slide()

func activate_hitbox():
	hitbox_active = true
	current_attack_has_hit = false  # Reset hit tracking for new attack
	
	# Position hitbox based on facing
	var offset = current_attack.hitbox_offset
	if not facing_right:
		offset.x *= -1
	
	hitbox_node.position = offset
	
	# Set hitbox size
	var shape = RectangleShape2D.new()
	shape.size = current_attack.hitbox_size
	
	# Clear old shape and add new
	for child in hitbox_node.get_children():
		child.queue_free()
	
	var collision = CollisionShape2D.new()
	collision.shape = shape
	hitbox_node.add_child(collision)
	
	# Enable monitoring
	hitbox_node.monitoring = true
	hitbox_node.monitorable = true

func deactivate_hitbox():
	hitbox_active = false
	hitbox_node.monitoring = false
	hitbox_node.monitorable = false

func _on_hitbox_area_entered(area):
	if not hitbox_active or not current_attack:
		return
	
	# PREVENT MULTI-HIT: Only hit once per attack cycle
	if current_attack_has_hit:
		print("  HIT BLOCKED: Attack already landed a hit this cycle")
		return
	
	# 1V1 VALIDATION: Only hit the opponent, no self-hit, no other entities
	
	# Check if it's a hurtbox
	if area.name != "Hurtbox" and area.collision_layer != 8:
		return  # Not a valid target
	
	var target = area.get_parent()
	
	# 1V1: Only hit the opponent
	if target != opponent:
		return  # Ignore other entities or wrong player
	
	# PROXIMITY CHECK: Must be within attack range
	var distance_to_target = global_position.distance_to(target.global_position)
	var attack_range = current_attack.hitbox_size.x + 50  # Hitbox size + buffer
	
	if distance_to_target > attack_range:
		return  # Too far away
	
	# Calculate damage and knockback
	var damage = current_attack.damage
	var kb = current_attack.base_knockback * (1.0 + (target.damage_percent / 100.0) * 0.5)
	var angle = current_attack.knockback_angle
	
	# DEBUG: Show pre-flip angle
	print("  Pre-flip angle: ", angle, " Facing right: ", facing_right)
	
	if not facing_right:
		angle = 180 - angle
	
	# DEBUG: Enhanced hit confirmation
	print("  HIT CONFIRMED: Dmg=", damage, " KB=", kb, " Angle=", angle, " Dir=", "right" if facing_right else "left")
	
	# Mark attack as having hit (prevents multi-hit)
	current_attack_has_hit = true
	
	# Apply hit
	if target.has_method("take_damage"):
		# Hit pause effect
		Engine.time_scale = 0.05
		await get_tree().create_timer(0.05).timeout
		Engine.time_scale = 1.0
		
		target.take_damage(damage, kb, angle, self)
		create_hit_effect(area.global_position)
		
		print("Player ", player_id, " hit opponent! Distance: ", distance_to_target, " Damage: ", damage)

func create_hit_effect(pos):
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 0.8, 0.9)
	flash.size = Vector2(40, 40)
	flash.position = pos - flash.size / 2
	get_tree().root.add_child(flash)
	
	await get_tree().create_timer(0.1).timeout
	flash.queue_free()

func create_double_jump_effect():
	pass  # Placeholder for particle effect

func end_attack():
	deactivate_hitbox()
	current_attack = null
	if is_on_floor():
		state_machine.change_state(PlayerStateMachine.State.IDLE)
	else:
		state_machine.change_state(PlayerStateMachine.State.AIRBORNE)

func process_hitstun(delta):
	hitstun_timer -= delta
	
	velocity = launch_velocity
	launch_velocity *= 0.98
	
	apply_gravity(delta)
	
	if hitstun_timer <= 0:
		if is_on_floor():
			state_machine.change_state(PlayerStateMachine.State.IDLE)
		else:
			state_machine.change_state(PlayerStateMachine.State.AIRBORNE)
		return
	
	move_and_slide()

func process_landing_lag(delta):
	apply_gravity(delta)
	
	# PREMIUM: Fast landing recovery with controllable timer
	landing_lag_timer -= delta
	velocity.x *= 0.85  # Slightly less friction during landing
	
	if landing_lag_timer <= 0:
		state_machine.change_state(PlayerStateMachine.State.IDLE)
		if DEBUG_MOVEMENT:
			print("Player ", player_id, ": LANDING RECOVERY COMPLETE")
	
	move_and_slide()

func process_dead(delta):
	visible = false
	velocity = Vector2.ZERO
	
	if state_machine.state_timer >= 0.5:
		stock_count -= 1
		if stock_count <= 0:
			emit_signal("player_defeated", player_id)
		else:
			state_machine.change_state(PlayerStateMachine.State.RESPAWN)

func process_respawn(delta):
	if state_machine.state_timer >= 1.0:
		position = Vector2(960 + (player_id - 1.5) * 300, 400)
		velocity = Vector2.ZERO
		damage_percent = 0
		visible = true
		state_machine.change_state(PlayerStateMachine.State.IDLE)

func take_damage(damage, knockback, angle, attacker):
	# DEBUG: Check why hit might be blocked
	if state_machine.is_invulnerable():
		print("  TAKE_DAMAGE BLOCKED: Player ", player_id, " is invulnerable")
		return
	
	if hit_cooldown > 0:
		print("  TAKE_DAMAGE BLOCKED: Player ", player_id, " on hit cooldown (", hit_cooldown, "s remaining)")
		return
	
	# Apply damage
	damage_percent += damage
	damage_percent = clamp(damage_percent, 0, 999)
	
	# Convert angle to radians
	var rad = deg_to_rad(angle)
	launch_velocity = Vector2(cos(rad), -sin(rad)) * knockback
	
	# DEBUG: Show pushback values
	print("  TAKE_DAMAGE: Player ", player_id, " hit! Launch velocity: ", launch_velocity, " (knockback=", knockback, ")")
	
	# Set hitstun based on knockback
	hitstun_timer = 0.1 + (knockback / 2000.0)
	
	# Set hit cooldown (prevents rapid re-hit)
	hit_cooldown = HIT_COOLDOWN_DURATION
	print("  Hit cooldown started: ", hit_cooldown, "s")
	
	state_machine.change_state(PlayerStateMachine.State.HITSTUN)
	
	# VISUAL FEEDBACK: Flash red on hit
	flash_character_color(Color(1.0, 0.2, 0.2, 1.0), 0.1)
	
	# SCREEN SHAKE: Based on knockback strength
	var shake_amount = min(knockback / 50.0, 12.0)
	trigger_screen_shake(shake_amount)
	
	print("  Player ", player_id, " took damage! KB=", knockback, " Angle=", angle)

func flash_character_color(color: Color, duration: float) -> void:
	"""Flash the character with a color for hit feedback"""
	var body = visuals.get_node_or_null("Body")
	if body:
		var original_color = body.color
		body.color = color
		await get_tree().create_timer(duration).timeout
		if is_instance_valid(body):
			body.color = original_color

func trigger_screen_shake(amount: float) -> void:
	"""Trigger screen shake effect"""
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(amount)
	elif camera:
		# Fallback: manual shake
		camera.offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		await get_tree().create_timer(0.05).timeout
		if is_instance_valid(camera):
			camera.offset = Vector2.ZERO

func check_blast_zones():
	if state_machine.current_state in [PlayerStateMachine.State.DEAD, PlayerStateMachine.State.RESPAWN]:
		return
	
	if position.x < BLAST_ZONE_LEFT or position.x > BLAST_ZONE_RIGHT or \
	   position.y < BLAST_ZONE_TOP or position.y > BLAST_ZONE_BOTTOM:
		state_machine.change_state(PlayerStateMachine.State.DEAD)

func apply_gravity(delta):
	var gravity = GRAVITY * GRAVITY_SCALE
	if is_fast_falling and velocity.y > 0:
		gravity *= 1.5
	
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, MAX_FALL_SPEED if not is_fast_falling else FAST_FALL_SPEED)

func update_facing():
	if velocity.x > 30:
		facing_right = true
	elif velocity.x < -30:
		facing_right = false
	
	# Update 2D visuals (hidden but kept for compatibility)
	visuals.scale.x = 1 if facing_right else -1
	
	# Update 3D model sprite
	var sprite = get_node_or_null("CharacterSprite3D")
	if sprite:
		sprite.flip_h = not facing_right  # Flip horizontally

# === INPUT FUNCTIONS ===
func get_input_x() -> float:
	var left = Input.is_action_pressed("p1_left") if player_id == 1 else Input.is_action_pressed("p2_left")
	var right = Input.is_action_pressed("p1_right") if player_id == 1 else Input.is_action_pressed("p2_right")
	
	if left: return -1.0
	if right: return 1.0
	return 0.0

func get_input_jump() -> bool:
	return Input.is_action_just_pressed("p1_jump") if player_id == 1 else Input.is_action_just_pressed("p2_jump")

func get_input_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("p1_jump") if player_id == 1 else Input.is_action_just_pressed("p2_jump")

func get_input_jump_held() -> bool:
	return Input.is_action_pressed("p1_jump") if player_id == 1 else Input.is_action_pressed("p2_jump")

func get_input_attack() -> bool:
	var pressed = Input.is_action_just_pressed("p1_attack") if player_id == 1 else Input.is_action_just_pressed("p2_attack")
	
	# NEW: Buffer the attack input if we can't attack right now
	if pressed and not state_machine.can_attack():
		attack_buffer = ATTACK_BUFFER_TIME
		return false  # Don't trigger yet, let buffer handle it
	
	return pressed

func trigger_attack_from_state():
	# Choose attack based on current state
	match state_machine.current_state:
		PlayerStateMachine.State.IDLE:
			start_attack(attacks["jab"])
		PlayerStateMachine.State.RUN:
			start_attack(attacks["forward_tilt"])
		PlayerStateMachine.State.AIRBORNE:
			start_attack(attacks["neutral_air"])

func start_attack(attack):
	current_attack = attack
	attack_timer = 0.0
	hitbox_active = false
	current_attack_has_hit = false  # Reset hit tracking for new attack
	
	# Visual feedback - flash yellow
	flash_visual_feedback(Color(1.0, 1.0, 0.3, 1.0), VISUAL_FLASH_DURATION)
	
	# Trigger punch animation
	trigger_punch_animation()
	
	# Start attack state
	if is_on_floor():
		state_machine.change_state(PlayerStateMachine.State.ATTACK_GROUND)
	else:
		state_machine.change_state(PlayerStateMachine.State.ATTACK_AIR)

func get_input_down() -> bool:
	var pressed = Input.is_action_just_pressed("p1_down") if player_id == 1 else Input.is_action_just_pressed("p2_down")
	
	if pressed:
		var current_time = Time.get_time_dict_from_system()["second"]
		if current_time - last_down_press < DOUBLE_TAP_WINDOW:
			# Double tap detected - trigger dodge
			trigger_dodge()
			return false  # Don't process as shield
		last_down_press = current_time
	
	return pressed

func get_input_down_held() -> bool:
	return Input.is_action_pressed("p1_down") if player_id == 1 else Input.is_action_pressed("p2_down")

func trigger_dodge() -> void:
	"""Initiate dodge/roll"""
	if not is_on_floor() or dodge_timer > 0:
		return
	
	# Determine dodge direction
	var input_x = get_input_x()
	if input_x != 0:
		dodge_direction = sign(input_x)
	else:
		dodge_direction = 1 if facing_right else -1
	
	dodge_timer = DODGE_DURATION
	state_machine.change_state(PlayerStateMachine.State.DODGE)
	print("Player ", player_id, ": DODGE!")

func try_shield() -> bool:
	"""Attempt to start shielding"""
	if not is_on_floor() or shield_health <= 0:
		return false
	
	if get_input_down_held() and state_machine.current_state in [PlayerStateMachine.State.IDLE, PlayerStateMachine.State.RUN]:
		is_shielding = true
		shield_node.visible = true
		state_machine.change_state(PlayerStateMachine.State.SHIELD)
		print("Player ", player_id, ": SHIELD UP")
		return true
	
	return false

func _on_state_changed(new_state, old_state):
	print("Player ", player_id, ": ", state_machine.get_state_name())

signal player_defeated(player_id)
