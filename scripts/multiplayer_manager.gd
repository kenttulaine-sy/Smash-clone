# Multiplayer Manager
# Handles dynamic player spawning, match setup, and player management
# Extends existing MatchManager - does NOT replace it

extends Node
class_name MultiplayerManager

# Player spawn configurations
const MAX_PLAYERS: int = 4
const PLAYER_SCENE_PATH: String = "res://scenes/player.tscn"

# Spawn positions for 4 players (can be customized)
const SPAWN_POSITIONS: Array = [
	Vector2(560, 500),   # P1 - Left side
	Vector2(1360, 500),  # P2 - Right side  
	Vector2(760, 400),   # P3 - Mid-left
	Vector2(1160, 400)   # P4 - Mid-right
]

# Colors for each player (distinct)
const PLAYER_COLORS: Array = [
	Color(0.2, 0.6, 1.0),  # P1 - Blue
	Color(1.0, 0.2, 0.2),  # P2 - Red
	Color(0.2, 1.0, 0.2),  # P3 - Green
	Color(1.0, 0.8, 0.2)   # P4 - Yellow
]

# Currently active players
var active_players: Array = []
var player_count: int = 2  # Default to 2 players

# Player input mappings (matches existing project.godot)
const PLAYER_INPUTS: Dictionary = {
	1: {
		"left": "p1_left",
		"right": "p1_right",
		"up": "p1_up",
		"down": "p1_down",
		"jump": "p1_jump",
		"attack": "p1_attack",
		"shield": "p1_shield"
	},
	2: {
		"left": "p2_left",
		"right": "p2_right",
		"up": "p2_up",
		"down": "p2_down",
		"jump": "p2_jump",
		"attack": "p2_attack",
		"shield": "p2_shield"
	}
}

func _ready():
	print("MultiplayerManager initialized")
	# Spawn initial players
	spawn_match_players()

func spawn_match_players() -> void:
	# Clear existing players from scene
	clear_existing_players()
	
	# Spawn requested number of players
	for i in range(player_count):
		spawn_player(i + 1)
	
	print("Spawned ", player_count, " players")

func clear_existing_players() -> void:
	# Remove any existing player nodes
	for child in get_parent().get_children():
		if child is CharacterBody2D and child.has_method("take_damage"):
			child.queue_free()
	active_players.clear()

func spawn_player(player_id: int) -> Node:
	# Create player using existing player scene
	var player = CharacterBody2D.new()
	player.name = "Player" + str(player_id)
	player.position = SPAWN_POSITIONS[player_id - 1]
	player.collision_layer = 2
	player.collision_mask = 7
	
	# Add player script
	player.set_script(load("res://scripts/player_v2.gd"))
	
	# Configure player properties
	player.player_id = player_id
	player.stock_count = 3
	
	# Add to scene
	get_parent().add_child(player)
	
	# Setup visuals
	setup_player_visuals(player, player_id)
	
	# Setup hitboxes
	setup_player_hitboxes(player)
	
	active_players.append(player)
	
	print("Spawned Player ", player_id, " at ", player.position)
	
	return player

func setup_player_visuals(player: Node, player_id: int) -> void:
	# Create visuals node structure
	var visuals = Node2D.new()
	visuals.name = "Visuals"
	player.add_child(visuals)
	
	# Create body (colored rectangle)
	var body = ColorRect.new()
	body.name = "Body"
	body.offset_left = -20.0
	body.offset_top = -30.0
	body.offset_right = 20.0
	body.offset_bottom = 30.0
	body.color = PLAYER_COLORS[player_id - 1]
	visuals.add_child(body)
	
	# Create eyes
	var eye_left = ColorRect.new()
	eye_left.name = "EyeLeft"
	eye_left.offset_left = -12.0
	eye_left.offset_top = -20.0
	eye_left.offset_right = -4.0
	eye_left.offset_bottom = -12.0
	eye_left.color = Color(1, 1, 1, 1)
	visuals.add_child(eye_left)
	
	var eye_right = ColorRect.new()
	eye_right.name = "EyeRight"
	eye_right.offset_left = 4.0
	eye_right.offset_top = -20.0
	eye_right.offset_right = 12.0
	eye_right.offset_bottom = -12.0
	eye_right.color = Color(1, 1, 1, 1)
	visuals.add_child(eye_right)

func setup_player_hitboxes(player: Node) -> void:
	# Create collision shape
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(40, 60)
	player.add_child(collision)
	
	# Create hitbox
	var hitbox = Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 4
	hitbox.collision_mask = 8
	hitbox.set_script(load("res://scripts/hitbox.gd"))
	player.add_child(hitbox)
	
	# Create hurtbox
	var hurtbox = Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 8
	hurtbox.set_script(load("res://scripts/hurtbox.gd"))
	player.add_child(hurtbox)
	
	# Add collision shapes to hitbox/hurtbox
	var hitbox_shape = CollisionShape2D.new()
	hitbox.add_child(hitbox_shape)
	
	var hurtbox_shape = CollisionShape2D.new()
	hurtbox_shape.shape = RectangleShape2D.new()
	hurtbox_shape.shape.size = Vector2(40, 60)
	hurtbox.add_child(hurtbox_shape)

func set_player_count(count: int) -> void:
	player_count = clamp(count, 2, MAX_PLAYERS)

func get_active_players() -> Array:
	return active_players

func reset_match() -> void:
	for player in active_players:
		if is_instance_valid(player):
			player.stock_count = 3
			player.damage_percent = 0
			player.position = SPAWN_POSITIONS[player.player_id - 1]
			player.visible = true

func check_match_winner() -> int:
	# Return player ID of winner, or 0 if no winner yet
	var alive_players = []
	
	for player in active_players:
		if is_instance_valid(player) and player.stock_count > 0:
			alive_players.append(player)
	
	if alive_players.size() == 1:
		return alive_players[0].player_id
	
	return 0
