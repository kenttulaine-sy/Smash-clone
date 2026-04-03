# Hitbox System
# Manages active hit detection during attacks

extends Area2D
class_name SmashHitbox

signal hit_connected(target, damage, knockback, angle)

var attack_data: AttackData = null
var active: bool = false
var player_owner: Node = null
var facing_right: bool = true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Set up collision layers
	collision_layer = 4  # Hitbox layer
	collision_mask = 8   # Hurtbox layer
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	monitoring = false
	monitorable = false

func activate(data: AttackData, owner_player: Node, facing: bool) -> void:
	attack_data = data
	player_owner = owner_player
	facing_right = facing
	active = true
	
	# Position hitbox based on facing direction
	var direction = 1 if facing_right else -1
	position = data.hitbox_offset * Vector2(direction, 1)
	
	# Set collision shape size
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = data.hitbox_size
	
	monitoring = true
	monitorable = true

func deactivate() -> void:
	active = false
	monitoring = false
	monitorable = false
	attack_data = null

func _on_area_entered(area: Area2D) -> void:
	if not active or not attack_data:
		return
	
	# Check if we hit a hurtbox
	if area is SmashHurtbox:
		var target = area.get_parent()
		if target == player_owner:
			return  # Don't hit yourself
		
		# Apply hit
		var damage = attack_data.base_damage
		var knockback = attack_data.base_knockback
		var angle = attack_data.knockback_angle
		
		# Flip angle if facing left
		if not facing_right:
			angle = 180 - angle
		
		# Emit hit signal
		hit_connected.emit(target, damage, knockback, angle)
		
		# Create hit effects
		create_hit_effect(area.global_position)
		
		# Apply hit pause
		Engine.time_scale = 0.1
		await get_tree().create_timer(attack_data.hit_pause_frames / 600.0).timeout
		Engine.time_scale = 1.0

func create_hit_effect(pos: Vector2) -> void:
	# Create visual hit effect
	var effect = ColorRect.new()
	effect.color = Color(1, 1, 0.5, 0.8)
	effect.size = Vector2(30, 30)
	effect.position = pos - effect.size / 2
	get_tree().root.add_child(effect)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.2)
	tween.tween_property(effect, "scale", Vector2(2, 2), 0.2)
	await tween.finished
	effect.queue_free()
