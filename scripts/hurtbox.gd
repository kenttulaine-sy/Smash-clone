# Hurtbox System
# Receives hits from hitboxes

extends Area2D
class_name SmashHurtbox

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	collision_layer = 8   # Hurtbox layer
	collision_mask = 0    # Don't detect anything, just receive
	monitoring = false
	monitorable = true

func set_size(size: Vector2) -> void:
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = size
