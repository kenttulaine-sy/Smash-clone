# Simple AI Controller
# Makes opponent follow and attack player

extends Node
class_name SimpleAI

var player: Node = null
var target: Node = null
var attack_cooldown: float = 0.0
const ATTACK_COOLDOWN: float = 1.5
const MOVE_SPEED: float = 0.7
const ATTACK_RANGE: float = 80.0
const JUMP_RANGE: float = 150.0

# Jump control
var jump_cooldown: float = 0.0
const JUMP_COOLDOWN_TIME: float = 1.0

func _ready():
	# Find players
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("players")
	if players.size() >= 2:
		player = players[1]
		target = players[0]
		print("AI: Targeting Player 1")

func _process(delta: float) -> void:
	if not player or not target or not is_instance_valid(player) or not is_instance_valid(target):
		return
	
	# Update cooldowns
	attack_cooldown -= delta
	jump_cooldown -= delta
	
	# Don't override certain states
	var current_state = player.state_machine.current_state
	if current_state in [player.PlayerStateMachine.State.HITSTUN, 
						 player.PlayerStateMachine.State.GRABBED,
						 player.PlayerStateMachine.State.DEAD,
						 player.PlayerStateMachine.State.ATTACK_GROUND,
						 player.PlayerStateMachine.State.ATTACK_AIR]:
		return
	
	# If in air, let physics handle it - only control when grounded
	if not player.is_on_floor():
		return
	
	var distance = player.global_position.distance_to(target.global_position)
	var direction = sign(target.global_position.x - player.global_position.x)
	var height_diff = target.global_position.y - player.global_position.y
	
	# Face target - use player's update_facing() instead of setting directly
	# This preserves deadzone logic and prevents flicker
	if direction != 0 and player.has_method("update_facing"):
		# Only update if we're outside deadzone (prevents jitter)
		var distance_to_target = target.global_position.x - player.global_position.x
		if abs(distance_to_target) > 10.0:  # 10px deadzone
			var should_face_right = distance_to_target > 0
			if player.facing_right != should_face_right:
				player.facing_right = should_face_right
				player.update_facing()  # Call proper facing update
	
	# Jump if target is significantly above and close
	if height_diff < -80 and jump_cooldown <= 0 and distance < JUMP_RANGE:
		perform_jump()
		return
	
	# Move toward target
	if distance > ATTACK_RANGE:
		# Walk toward target
		player.velocity.x = direction * player.RUN_SPEED * MOVE_SPEED
		player.state_machine.change_state(player.PlayerStateMachine.State.RUN)
	else:
		# In attack range - stop moving
		player.velocity.x = move_toward(player.velocity.x, 0, player.GROUND_DECEL * delta)
		
		# Attack if ready
		if attack_cooldown <= 0:
			attack_cooldown = ATTACK_COOLDOWN + randf_range(-0.3, 0.3)
			perform_attack()
		else:
			# Idle while waiting to attack
			if abs(player.velocity.x) < 10:
				player.state_machine.change_state(player.PlayerStateMachine.State.IDLE)
	
	player.move_and_slide()

func perform_jump() -> void:
	"""Execute a jump toward target"""
	jump_cooldown = JUMP_COOLDOWN_TIME
	player.velocity.y = player.JUMP_FORCE
	player.jumps_remaining -= 1
	player.state_machine.change_state(player.PlayerStateMachine.State.AIRBORNE)
	print("AI: Jumped")

func perform_attack() -> void:
	"""Execute an attack"""
	if not player or not is_instance_valid(player):
		return
	
	# Only attack when on floor
	if not player.is_on_floor():
		return
	
	var attack_type = randi() % 3
	
	match attack_type:
		0:
			player.start_attack(player.attacks["jab"])
		1:
			player.start_attack(player.attacks["forward_tilt"])
		2:
			player.try_grab()
