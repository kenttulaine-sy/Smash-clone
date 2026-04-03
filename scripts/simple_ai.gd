# Simple AI Controller
# Makes opponent follow and attack player

extends Node
class_name SimpleAI

var player: Node = null
var target: Node = null
var attack_cooldown: float = 0.0
const ATTACK_COOLDOWN: float = 1.5
const MOVE_SPEED: float = 0.7  # Slower than human reaction
const ATTACK_RANGE: float = 80.0
const JUMP_RANGE: float = 150.0

func _ready():
	# Find players
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("players")
	if players.size() >= 2:
		# Assume this AI is attached to player 2
		player = players[1]
		target = players[0]
		print("AI: Targeting Player 1")

func _process(delta: float) -> void:
	if not player or not target or not is_instance_valid(player) or not is_instance_valid(target):
		return
	
	# Don't control if player is in certain states
	if player.state_machine.current_state in [player.PlayerStateMachine.State.HITSTUN, 
											 player.PlayerStateMachine.State.GRABBED,
											 player.PlayerStateMachine.State.DEAD]:
		return
	
	attack_cooldown -= delta
	
	var distance = player.global_position.distance_to(target.global_position)
	var direction = sign(target.global_position.x - player.global_position.x)
	var height_diff = target.global_position.y - player.global_position.y
	
	# Face target
	if direction != 0:
		player.facing_right = direction > 0
	
	# Jump if target is above and we're on floor
	if height_diff < -50 and player.is_on_floor() and distance < JUMP_RANGE:
		# Simulate jump input
		player.velocity.y = player.JUMP_FORCE
		player.jumps_remaining -= 1
		player.state_machine.change_state(player.PlayerStateMachine.State.AIRBORNE)
		return
	
	# Move toward target
	if distance > ATTACK_RANGE:
		player.velocity.x = direction * player.RUN_SPEED * MOVE_SPEED
		if player.is_on_floor():
			player.state_machine.change_state(player.PlayerStateMachine.State.RUN)
	else:
		# In attack range
		player.velocity.x = move_toward(player.velocity.x, 0, player.GROUND_DECEL * delta)
		
		# Attack if cooldown is ready
		if attack_cooldown <= 0:
			attack_cooldown = ATTACK_COOLDOWN + randf_range(-0.3, 0.3)  # Randomize timing
			perform_attack()
	
	# Apply movement
	player.move_and_slide()

func perform_attack() -> void:
	"""Execute an attack"""
	if not player or not is_instance_valid(player):
		return
	
	var attack_type = randi() % 3  # Random attack
	
	match attack_type:
		0:	# Jab
			if player.is_on_floor():
				player.start_attack(player.attacks["jab"])
		1:	# Forward tilt
			if player.is_on_floor():
				player.start_attack(player.attacks["forward_tilt"])
		2:	# Grab
			if player.is_on_floor():
				player.try_grab()
