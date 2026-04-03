# Match Manager v2 - Multiplayer Support
# Extends existing functionality to support 2-4 players
# Works with dynamic player spawning (MultiplayerManager)

extends Node
class_name MatchManagerV2

# Player tracking
var players: Dictionary = {}  # player_id -> player_node
var active_player_ids: Array = []
var hud: CanvasLayer = null

# Match state
var match_active: bool = true
var winner: int = 0
var match_timer: float = 0.0

# Match settings
const MATCH_TIME_LIMIT: float = -1.0  # -1 = no time limit
const STOCKS_PER_PLAYER: int = 3

func _ready():
	print("MatchManagerV2 initialized")
	call_deferred("setup_match")

func setup_match() -> void:
	hud = get_node_or_null("../HUD")
	
	# Find all players in scene (works with static or dynamically spawned)
	find_all_players()
	
	# Connect to player defeat signals
	connect_player_signals()
	
	print("Match ready with ", players.size(), " players")
	print("Player IDs: ", active_player_ids)

func find_all_players() -> void:
	# Clear existing
	players.clear()
	active_player_ids.clear()
	
	# Look for players in parent node
	for child in get_parent().get_children():
		if child is CharacterBody2D:
			# Check if it's a player by looking for player_id property
			var pid = child.get("player_id")
			if pid != null and pid is int and pid > 0:
				players[pid] = child
				active_player_ids.append(pid)
				print("Found Player ", pid, " at ", child.position)
	
	active_player_ids.sort()

func connect_player_signals() -> void:
	for player_id in players:
		var player = players[player_id]
		if player.has_signal("player_defeated"):
			# Disconnect first to avoid duplicates
			if player.is_connected("player_defeated", _on_player_defeated):
				player.disconnect("player_defeated", _on_player_defeated)
			player.connect("player_defeated", _on_player_defeated)

func _process(delta: float) -> void:
	if not match_active:
		return
	
	match_timer += delta
	
	# Check win conditions
	check_win_conditions()

func check_win_conditions() -> void:
	# Count alive players (those with stocks > 0)
	var alive_players = []
	var alive_count = 0
	
	for player_id in active_player_ids:
		var player = players.get(player_id)
		if player == null or not is_instance_valid(player):
			continue
		
		var stocks = player.get("stock_count")
		if stocks == null:
			continue
		
		if stocks > 0:
			alive_players.append(player_id)
			alive_count += 1
	
	# Win condition: only one player left with stocks
	if alive_count == 1 and alive_players.size() == 1:
		declare_winner(alive_players[0])
	elif alive_count == 0:
		# Draw - everyone eliminated at same time
		declare_winner(0)  # 0 = draw

func _on_player_defeated(defeated_id: int) -> void:
	if not match_active:
		return
	
	print("Player ", defeated_id, " defeated!")
	
	# Check if this player is actually out
	var player = players.get(defeated_id)
	if player == null:
		return
	
	var stocks = player.get("stock_count")
	if stocks == null or stocks > 0:
		return  # Still has stocks, will respawn
	
	# Player is eliminated
	print("Player ", defeated_id, " ELIMINATED!")

func declare_winner(winner_id: int) -> void:
	match_active = false
	self.winner = winner_id
	
	if winner_id == 0:
		print("MATCH ENDED - DRAW!")
	else:
		print("WINNER: Player ", winner_id, "!")
	
	# Show winner on HUD
	if hud and hud.has_method("show_winner"):
		if winner_id == 0:
			hud.show_winner(-1)  # -1 = draw
		else:
			hud.show_winner(winner_id)
	
	# Pause briefly then offer restart
	await get_tree().create_timer(3.0).timeout
	show_restart_prompt()

func show_restart_prompt() -> void:
	# This could trigger a UI element
	print("Press R to restart match")

func reset_match() -> void:
	print("Resetting match...")
	
	match_active = true
	winner = 0
	match_timer = 0.0
	
	# Re-find players (in case they were respawned)
	find_all_players()
	
	# Reset all players
	for player_id in active_player_ids:
		var player = players.get(player_id)
		if player == null or not is_instance_valid(player):
			continue
		
		# Reset stocks and damage
		player.set("stock_count", STOCKS_PER_PLAYER)
		player.set("damage_percent", 0.0)
		
		# Reset position based on player_id
		var spawn_pos = get_spawn_position(player_id)
		player.position = spawn_pos
		
		# Reset state machine
		var sm = player.get("state_machine")
		if sm and sm.has_method("change_state"):
			sm.change_state(PlayerStateMachine.State.IDLE)
		
		player.visible = true
	
	# Hide winner display
	if hud and hud.has_method("hide_winner"):
		hud.hide_winner()
	
	print("Match reset complete")

func get_spawn_position(player_id: int) -> Vector2:
	# Spawn positions for up to 4 players
	if player_id == 1:
		return Vector2(560, 500)   # Left side
	elif player_id == 2:
		return Vector2(1360, 500)  # Right side
	elif player_id == 3:
		return Vector2(760, 400)   # Mid-left
	elif player_id == 4:
		return Vector2(1160, 400)  # Mid-right
	else:
		return Vector2(960, 500)    # Center fallback

func get_player_count() -> int:
	return players.size()

func get_alive_player_count() -> int:
	var count = 0
	for player_id in active_player_ids:
		var player = players.get(player_id)
		if player == null:
			continue
		var stocks = player.get("stock_count")
		if stocks != null and stocks > 0:
			count += 1
	return count

func is_match_active() -> bool:
	return match_active

func get_winner() -> int:
	return winner

func get_match_time() -> float:
	return match_timer
