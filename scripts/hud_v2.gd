extends CanvasLayer

var player1: Node = null
var player2: Node = null

@onready var p1_percent = $P1Percent
@onready var p1_stocks = $P1Stocks
@onready var p2_percent = $P2Percent
@onready var p2_stocks = $P2Stocks
@onready var controls = $Controls
@onready var winner_text = $WinnerText

func _ready():
	await get_tree().process_frame
	
	player1 = get_node_or_null("../Player1")
	player2 = get_node_or_null("../Player2")
	
	if winner_text:
		winner_text.visible = false

func _process(_delta):
	update_display()

func update_display():
	if player1 != null and is_instance_valid(player1):
		var p1_dmg = player1.get("damage_percent")
		var p1_stock = player1.get("stock_count")
		if p1_percent and p1_dmg != null:
			p1_percent.text = str(int(p1_dmg)) + "%"
		if p1_stocks and p1_stock != null:
			p1_stocks.text = "Stocks: " + str(p1_stock)
	
	if player2 != null and is_instance_valid(player2):
		var p2_dmg = player2.get("damage_percent")
		var p2_stock = player2.get("stock_count")
		if p2_percent and p2_dmg != null:
			p2_percent.text = str(int(p2_dmg)) + "%"
		if p2_stocks and p2_stock != null:
			p2_stocks.text = "Stocks: " + str(p2_stock)

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
				p1_stocks.text = "Stocks: " + str(stocks)
		2:
			if p2_percent:
				p2_percent.text = str(int(damage)) + "%"
			if p2_stocks:
				p2_stocks.text = "Stocks: " + str(stocks)
