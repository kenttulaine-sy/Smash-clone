extends CharacterBody2D
class_name SmashPlayer

# Player identification
@export var player_id: int = 1

# Smash Bros Constants
const GRAVITY: float = 1800.0          # Gravity strength
const AIR_FRICTION: float = 0.95      # Air momentum conservation  
const GROUND_FRICTION: float = 0.85   # Ground slide
const WALK_SPEED: float = 200.0       # Walking speed
const DASH_SPEED: float = 450.0       # Dash speed
const AIR_SPEED: float = 300.0        # Air control
const JUMP_FORCE: float = -650.0      # Jump strength
const SHORT_HOP_FORCE: float = -350.0 # Short hop
const DOUBLE_JUMP_FORCE: float = -600.0 # Double jump
const FAST_FALL_SPEED: float = 1200.0   # Fast fall velocity
const MAX_AIR_SPEED: float = 600.0    # Terminal horizontal air velocity
const MAX_FALL_SPEED: float = 800.0   # Terminal fall speed

# Attack constants
const JAB_DAMAGE: int = 4
const JAB_KNOCKBACK: float = 150.0
const JAB_ANGLE: float = 45.0

const FORWARD_TILT_DAMAGE: int = 8
const FORWARD_TILT_KNOCKBACK: float = 300.0
const FORWARD_TILT_ANGLE: float = 35.0

const UP_TILT_DAMAGE: int = 7
const UP_TILT_KNOCKBACK: float = 250.0
const UP_TILT_ANGLE: float = 80.0

const SMASH_CHARGE_MAX: float = 2.0   # Seconds to fully charge
const SMASH_DAMAGE_MULTIPLIER: float = 2.0

# Player state
var damage_percent: float = 0.0       # Smash Bros percentage (0-999)
var stocks: int = 3                   # Lives
var jumps_remaining: int = 2          # Jump count
var is_grounded: bool = false
var facing_right: bool = true
var is_shielding: bool = false
var shield_health: float = 100.0
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var invincibility_frames: int = 0

# Knockback state
var in_hitstun: bool = false
var hitstun_frames: int = 0

# Input state
var input_direction: Vector2 = Vector2.ZERO
var is_dashing: bool = false
var dash_timer: float = 0.0
var is_fast_falling: bool = false

# Hitbox visualization (for debugging)
var attack_hitbox: Area2D = null

func _ready():
    # Set up hitbox connections
    var hitbox = $Hitbox
    var hurtbox = $Hurtbox
    
    hitbox.body_entered.connect(_on_hitbox_entered)
    hurtbox.area_entered.connect(_on_hurtbox_entered)
    
    # Initialize attack hitbox
    attack_hitbox = Area2D.new()
    attack_hitbox.collision_layer = 4
    attack_hitbox.collision_mask = 8
    add_child(attack_hitbox)
    
    var attack_shape = CollisionShape2D.new()
    var rect_shape = RectangleShape2D.new()
    rect_shape.size = Vector2(80, 60)
    attack_shape.shape = rect_shape
    attack_hitbox.add_child(attack_shape)
    attack_hitbox.body_entered.connect(_on_attack_hit)
    attack_hitbox.monitorable = false
    attack_hitbox.monitoring = false

func _physics_process(delta):
    # Update state
    is_grounded = is_on_floor()
    
    if is_grounded:
        jumps_remaining = 2
        is_fast_falling = false
    
    # Handle hitstun
    if in_hitstun:
        hitstun_frames -= 1
        if hitstun_frames <= 0:
            in_hitstun = false
        # Apply hitstun gravity
        velocity.y += GRAVITY * delta * 0.5
        move_and_slide()
        return
    
    # Handle shield
    if is_shielding:
        handle_shield(delta)
        return
    
    # Handle attack
    if is_attacking:
        handle_attack(delta)
        return
    
    # Get input
    get_input()
    
    # Apply physics
    apply_gravity(delta)
    apply_movement(delta)
    apply_friction(delta)
    
    # Move
    move_and_slide()
    
    # Update visuals
    update_facing()
    update_visuals()

func get_input():
    var left = Input.is_action_pressed("p1_left") if player_id == 1 else Input.is_action_pressed("p2_left")
    var right = Input.is_action_pressed("p1_right") if player_id == 1 else Input.is_action_pressed("p2_right")
    var jump = Input.is_action_just_pressed("p1_jump") if player_id == 1 else Input.is_action_just_pressed("p2_jump")
    var attack = Input.is_action_just_pressed("p1_attack") if player_id == 1 else Input.is_action_just_pressed("p2_attack")
    var shield = Input.is_action_pressed("p1_shield") if player_id == 1 else Input.is_action_pressed("p2_shield")
    var down = Input.is_action_pressed("p1_down") if player_id == 1 else Input.is_action_pressed("p2_down")
    
    # Direction
    input_direction.x = 0
    if left:
        input_direction.x -= 1
    if right:
        input_direction.x += 1
    
    # Fast fall
    if down and not is_grounded and velocity.y > 0:
        is_fast_falling = true
    
    # Jump
    if jump:
        try_jump()
    
    # Shield
    if shield and not is_attacking:
        start_shield()
        return
    
    # Attack
    if attack and not is_attacking and attack_cooldown <= 0:
        perform_attack(input_direction)

func try_jump():
    if is_grounded:
        # Check for short hop
        if Input.is_action_just_released("p1_jump"):
            velocity.y = SHORT_HOP_FORCE
        else:
            velocity.y = JUMP_FORCE
        jumps_remaining = 1
    elif jumps_remaining > 0:
        # Double jump
        velocity.y = DOUBLE_JUMP_FORCE
        jumps_remaining -= 1
        
        # Double jump animation effect
        spawn_jump_effect()

func apply_gravity(delta):
    var gravity = GRAVITY
    
    if is_fast_falling:
        velocity.y = move_toward(velocity.y, FAST_FALL_SPEED, gravity * delta * 2)
    else:
        velocity.y += gravity * delta
        
        # Terminal velocity
        if velocity.y > MAX_FALL_SPEED:
            velocity.y = MAX_FALL_SPEED

func apply_movement(delta):
    if is_grounded:
        # Ground movement
        if abs(input_direction.x) > 0:
            # Check for dash
            if abs(velocity.x) < 50 and input_direction.x != 0:
                velocity.x = input_direction.x * DASH_SPEED
                is_dashing = true
            else:
                velocity.x = move_toward(velocity.x, input_direction.x * WALK_SPEED, 2000 * delta)
    else:
        # Air movement (limited control)
        if abs(input_direction.x) > 0:
            velocity.x += input_direction.x * 1000 * delta
            velocity.x = clamp(velocity.x, -MAX_AIR_SPEED, MAX_AIR_SPEED)

func apply_friction(delta):
    if is_grounded and abs(input_direction.x) < 0.1:
        velocity.x *= GROUND_FRICTION
    elif not is_grounded:
        velocity.x *= AIR_FRICTION

func update_facing():
    if velocity.x > 50:
        facing_right = true
    elif velocity.x < -50:
        facing_right = false
    
    # Scale sprite based on facing
    $Visuals.scale.x = 1 if facing_right else -1

func update_visuals():
    # Flash if invincible
    if invincibility_frames > 0:
        invincibility_frames -= 1
        $Visuals.modulate.a = 0.5 if invincibility_frames % 10 < 5 else 1.0
    else:
        $Visuals.modulate.a = 1.0
    
    # Update attack cooldown
    if attack_cooldown > 0:
        attack_cooldown -= 1

func handle_attack(_delta):
    # Attack is being handled by the async perform_* functions
    # This just prevents other actions during attack
    velocity *= 0.9  # Slow down during attack
    
func start_shield():
    is_shielding = true
    velocity = Vector2.ZERO

func handle_shield(delta):
    var shield_input = Input.is_action_pressed("p1_shield") if player_id == 1 else Input.is_action_pressed("p2_shield")
    
    if not shield_input:
        is_shielding = false
        return
    
    # Shield shrinks over time
    shield_health -= 20 * delta
    if shield_health <= 0:
        shield_break()
        return
    
    # Shield visual
    $Visuals.modulate = Color(0.5, 0.5, 1, 0.7)

func shield_break():
    is_shielding = false
    shield_health = 0
    in_hitstun = true
    hitstun_frames = 120  # 2 seconds at 60fps
    # Play shield break sound/effect

func perform_attack(direction: Vector2):
    is_attacking = true
    velocity *= 0.5  # Slow movement during attack
    
    # Determine attack type based on direction
    if abs(direction.y) > abs(direction.x):
        if direction.y < 0:
            perform_up_tilt()
        else:
            perform_down_tilt()
    else:
        if direction.x != 0:
            perform_forward_tilt()
        else:
            perform_jab()

func perform_jab():
    # Quick punch
    attack_cooldown = 15
    activate_hitbox(JAB_DAMAGE, JAB_KNOCKBACK, JAB_ANGLE, 8)
    
    # Jab visual
    $Visuals/Body.color = Color(1, 1, 0.5, 1)
    await get_tree().create_timer(0.1).timeout
    $Visuals/Body.color = Color(0.2, 0.6, 1, 1) if player_id == 1 else Color(1, 0.2, 0.2, 1)
    
    is_attacking = false

func perform_forward_tilt():
    # Stronger forward attack
    attack_cooldown = 25
    activate_hitbox(FORWARD_TILT_DAMAGE, FORWARD_TILT_KNOCKBACK, FORWARD_TILT_ANGLE, 12)
    
    # Forward tilt visual
    $Visuals/Body.color = Color(1, 0.8, 0.2, 1)
    await get_tree().create_timer(0.15).timeout
    $Visuals/Body.color = Color(0.2, 0.6, 1, 1) if player_id == 1 else Color(1, 0.2, 0.2, 1)
    
    is_attacking = false

func perform_up_tilt():
    # Upward attack
    attack_cooldown = 20
    activate_hitbox(UP_TILT_DAMAGE, UP_TILT_KNOCKBACK, UP_TILT_ANGLE, 10)
    
    # Up tilt visual
    $Visuals/Body.color = Color(0.8, 1, 0.2, 1)
    await get_tree().create_timer(0.12).timeout
    $Visuals/Body.color = Color(0.2, 0.6, 1, 1) if player_id == 1 else Color(1, 0.2, 0.2, 1)
    
    is_attacking = false

func perform_down_tilt():
    # Low attack
    attack_cooldown = 20
    activate_hitbox(5, 200, -30, 10)  # Slightly downward angle
    is_attacking = false

func activate_hitbox(damage: int, knockback: float, angle: float, frames: int):
    attack_hitbox.monitorable = true
    attack_hitbox.monitoring = true
    
    # Store attack data in hitbox
    attack_hitbox.set_meta("damage", damage)
    attack_hitbox.set_meta("knockback", knockback)
    attack_hitbox.set_meta("angle", angle)
    attack_hitbox.set_meta("player_id", player_id)
    
    # Position hitbox based on facing
    var hitbox_offset = 50 if facing_right else -50
    attack_hitbox.position = Vector2(hitbox_offset, 0)
    
    # Deactivate after frames
    await get_tree().create_timer(frames / 60.0).timeout
    attack_hitbox.monitorable = false
    attack_hitbox.monitoring = false

func _on_attack_hit(body):
    if body is SmashPlayer and body.player_id != player_id:
        var damage = attack_hitbox.get_meta("damage", 0)
        var knockback = attack_hitbox.get_meta("knockback", 0.0)
        var angle = attack_hitbox.get_meta("angle", 45.0)
        
        body.take_damage(damage, knockback, angle, facing_right)

func take_damage(damage: int, base_knockback: float, angle: float, hit_from_right: bool):
    if invincibility_frames > 0:
        return
    
    # Add damage
    damage_percent += damage
    damage_percent = clamp(damage_percent, 0, 999)
    
    # Calculate knockback (Smash formula: higher % = more knockback)
    var knockback_scaling = 1.0 + (damage_percent / 100.0) * 0.5
    var final_knockback = base_knockback * knockback_scaling
    
    # Apply angle
    var radians = deg_to_rad(angle)
    if not hit_from_right:
        radians = PI - radians  # Flip angle
    
    velocity = Vector2(cos(radians), -sin(radians)) * final_knockback
    
    # Enter hitstun
    in_hitstun = true
    hitstun_frames = int(10 + damage_percent * 0.5)  # More damage = longer stun
    
    # Brief invincibility
    invincibility_frames = 30
    
    # Screen shake could be triggered here
    get_viewport().get_camera_2d().shake(5.0)

func _on_hitbox_entered(body):
    pass  # Handled by attack hit

func _on_hurtbox_entered(area):
    pass  # Handled by take_damage

func spawn_jump_effect():
    # Placeholder for jump dust effect
    pass

func respawn():
    if stocks > 0:
        stocks -= 1
        damage_percent = 0
        position = Vector2(960, 400) if player_id == 1 else Vector2(960, 400)
        velocity = Vector2.ZERO
        invincibility_frames = 120  # 2 seconds spawn protection
    else:
        # Game over for this player
        pass

func _on_blast_zone_entered(area):
    # Check if in blast zone
    if area.name.begins_with("Blast"):
        stocks = 0  # Instant KO on blast zone
        respawn()
