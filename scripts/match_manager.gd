# Match Manager - Fixed references

extends Node
class_name MatchManager

var player1: Node = null
var player2: Node = null
var hud: CanvasLayer = null

var match_active: bool = true
var winner: int = 0

func _ready():
	# Deferred setup to ensure nodes exist
	call_deferred("setup_players")
	print("Match started! First to lose all stocks loses!")

func setup_players():
	player1 = get_node_or_null("../Player1")
	player2 = get_node_or_null("../Player2")
	hud = get_node_or_null("../HUD")
	
	# Safe signal connection using strings
	if player1 and player1.has_signal("player_defeated"):
		player1.connect("player_defeated", _on_player_defeated)
	if player2 and player2.has_signal("player_defeated"):
		player2.connect("player_defeated", _on_player_defeated)

func _process(_delta):
	if not match_active:
		return
	
	if player1 == null or player2 == null:
		return
	
	# Check for winner using safe property access
	var p1_stocks = player1.get("stock_count")
	var p2_stocks = player2.get("stock_count")
	
	if p1_stocks != null and p1_stocks <= 0:
		declare_winner(2)
	elif p2_stocks != null and p2_stocks <= 0:
		declare_winner(1)

func _on_player_defeated(defeated_id: int) -> void:
	print("Player ", defeated_id, " defeated!")
	
	if player1 == null or player2 == null:
		return
	
	var p1_stocks = player1.get("stock_count")
	var p2_stocks = player2.get("stock_count")
	
	if defeated_id == 1 and p1_stocks != null and p1_stocks <= 0:
		declare_winner(2)
	elif defeated_id == 2 and p2_stocks != null and p2_stocks <= 0:
		declare_winner(1)

func declare_winner(winner_id: int) -> void:
	match_active = false
	winner = winner_id
	
	print("WINNER: Player ", winner_id, "!")
	
	if hud and hud.has_method("show_winner"):
		hud.show_winner(winner_id)

func reset_match() -> void:
	match_active = true
	winner = 0
	
	if player1:
		player1.set("stock_count", 3)
		player1.set("damage_percent", 0)
		player1.position = Vector2(760, 500)
		var sm = player1.get("state_machine")
		if sm:
			sm.call_deferred("change_state", PlayerStateMachine.State.IDLE)
	
	if player2:
		player2.set("stock_count", 3)
		player2.set("damage_percent", 0)
		player2.position = Vector2(1160, 500)
		var sm = player2.get("state_machine")
		if sm:
			sm.call_deferred("change_state", PlayerStateMachine.State.IDLE)
	
	if hud and hud.has_method("hide_winner"):
		hud.hide_winner()
