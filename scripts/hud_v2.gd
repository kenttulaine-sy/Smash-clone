extends CanvasLayer

var player1: Node = null
var player2: Node = null

@onready var p1_percent = $P1Percent
@onready var p1_stocks = $P1Stocks
@onready var p2_percent = $P2Percent
@onready var p2_stocks = $P2Stocks
@onready var controls = $Controls
@onready var winner_text = $WinnerText

# Damage colors (like Smash)
const DAMAGE_COLORS = {
	0: Color(1.0, 1.0, 1.0),	  # White (0%)
	25: Color(1.0, 1.0, 0.5),	 # Yellow (25%)
	50: Color(1.0, 0.7, 0.0),	 # Orange (50%)
	75: Color(1.0, 0.4, 0.0),	 # Red-Orange (75%)
	100: Color(1.0, 0.0, 0.0),	# Red (100%)
	150: Color(0.8, 0.0, 0.8),	# Purple (150%+)
	200: Color(0.5, 0.0, 0.5)	 # Dark Purple (200%+)
}

func _ready():
	await get_tree().process_frame
	
	player1 = get_node_or_null("../Player1")
	player2 = get_node_or_null("../Player2")
	
	if winner_text:
		winner_text.visible = false
	
	# Style the HUD
	style_hud()

func style_hud():
	"""Apply visual polish to HUD elements"""
	# Add shadows/outline to text for readability
	if p1_percent:
		p1_percent.add_theme_color_override("font_shadow_color", Color.BLACK)
		p1_percent.add_theme_constant_override("shadow_outline_size", 2)
	
	if p2_percent:
		p2_percent.add_theme_color_override("font_shadow_color", Color.BLACK)
		p2_percent.add_theme_constant_override("shadow_outline_size", 2)

func _process(_delta):
	update_display()

func update_display():
	if player1 != null and is_instance_valid(player1):
		var p1_dmg = player1.get("damage_percent")
		var p1_stock = player1.get("stock_count")
		if p1_percent and p1_dmg != null:
			p1_percent.text = str(int(p1_dmg)) + "%"
			p1_percent.add_theme_color_override("font_color", get_damage_color(p1_dmg))
			
			# Shake effect at high damage
			if p1_dmg > 100:
				p1_percent.position.x = 50 + randf_range(-2, 2)
		if p1_stocks and p1_stock != null:
			p1_stocks.text = format_stocks(p1_stock)
	
	if player2 != null and is_instance_valid(player2):
		var p2_dmg = player2.get("damage_percent")
		var p2_stock = player2.get("stock_count")
		if p2_percent and p2_dmg != null:
			p2_percent.text = str(int(p2_dmg)) + "%"
			p2_percent.add_theme_color_override("font_color", get_damage_color(p2_dmg))
			
			# Shake effect at high damage
			if p2_dmg > 100:
				p2_percent.position.x = 1720 + randf_range(-2, 2)
		if p2_stocks and p2_stock != null:
			p2_stocks.text = format_stocks(p2_stock)

func get_damage_color(damage: float) -> Color:
	"""Get color based on damage percentage (Smash-style)"""
	if damage >= 200:
		return DAMAGE_COLORS[200]
	elif damage >= 150:
		return DAMAGE_COLORS[150]
	elif damage >= 100:
		return DAMAGE_COLORS[100]
	elif damage >= 75:
		return DAMAGE_COLORS[75]
	elif damage >= 50:
		return DAMAGE_COLORS[50]
	elif damage >= 25:
		return DAMAGE_COLORS[25]
	return DAMAGE_COLORS[0]

func format_stocks(stocks: int) -> String:
	"""Format stocks as icons instead of text"""
	if stocks <= 0:
		return "☠️"
	var icons = ""
	for i in range(stocks):
		icons += "❤️"
	return icons

func show_winner(winner_id: int) -> void:
	if not winner_text:
		return
	
	if winner_id == -1:
		winner_text.text = "DRAW!"
	elif winner_id == 0:
		winner_text.text = "GAME OVER"
	else:
		winner_text.text = "PLAYER " + str(winner_id) + " WINS!"
	
	winner_text.visible = true
	
	# Animate winner text
	var tween = create_tween()
	tween.tween_property(winner_text, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(winner_text, "scale", Vector2(1.0, 1.0), 0.3)

func hide_winner() -> void:
	if winner_text:
		winner_text.visible = false

func update_player_display(player_id: int, damage: float, stocks: int) -> void:
	# Extended for multiple players (called by match manager)
	match player_id:
		1:
			if p1_percent:
				p1_percent.text = str(int(damage)) + "%"
			if p1_stocks:
				p1_stocks.text = format_stocks(stocks)
		2:
			if p2_percent:
				p2_percent.text = str(int(damage)) + "%"
			if p2_stocks:
				p2_stocks.text = format_stocks(stocks)
