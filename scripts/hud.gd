extends CanvasLayer

var player1: Node = null
var player2: Node = null

@onready var p1_percent = $P1Percent
@onready var p1_stocks = $P1Stocks
@onready var p2_percent = $P2Percent
@onready var p2_stocks = $P2Stocks
@onready var controls = $Controls

func _ready():
    await get_tree().process_frame
    
    player1 = get_node("../../Player1")
    player2 = get_node("../../Player2")
    
    # Set up UI positions
    if p1_percent:
        p1_percent.position = Vector2(50, 50)
    if p2_percent:
        p2_percent.position = Vector2(1720, 50)
    if p1_stocks:
        p1_stocks.position = Vector2(50, 100)
    if p2_stocks:
        p2_stocks.position = Vector2(1720, 100)
    
    if controls:
        controls.position = Vector2(960, 1000)
        controls.text = "P1: WASD + J(Attack) K(Special) L(Shield) | P2: Arrows + Numpad 1/2/3"

func _process(_delta):
    update_display()

func update_display():
    if player1 and is_instance_valid(player1):
        if p1_percent:
            p1_percent.text = str(int(player1.damage_percent)) + "%"
        if p1_stocks:
            p1_stocks.text = "Stocks: " + str(player1.stocks)
    
    if player2 and is_instance_valid(player2):
        if p2_percent:
            p2_percent.text = str(int(player2.damage_percent)) + "%"
        if p2_stocks:
            p2_stocks.text = "Stocks: " + str(player2.stocks)
