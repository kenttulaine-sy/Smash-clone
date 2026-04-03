# Visual Effects Manager
# Handles particles, screen shake, and other visual feedback

extends Node2D
class_name VisualEffects

# Particle colors
const HIT_SPARK_COLOR = Color(1.0, 0.9, 0.3, 1.0)  # Yellow-orange
const HIT_BLOOD_COLOR = Color(0.9, 0.2, 0.2, 0.8)   # Red
const SHIELD_HIT_COLOR = Color(0.3, 0.6, 1.0, 0.8) # Blue

# Trail settings
const TRAIL_LENGTH = 8
const TRAIL_DELAY = 0.016  # ~60fps

func _ready():
	pass

func spawn_hit_sparks(position: Vector2, direction: float, intensity: float = 1.0) -> void:
	"""Spawn hit spark particles at position"""
	var particle_count = int(5 * intensity)
	
	for i in range(particle_count):
		var spark = ColorRect.new()
		spark.color = HIT_SPARK_COLOR
		spark.size = Vector2(4, 4)
		spark.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		add_child(spark)
		
		# Animate spark
		var velocity = Vector2(cos(direction + randf_range(-0.5, 0.5)), 
						 sin(direction + randf_range(-0.5, 0.5))) * randf_range(100, 200)
		animate_spark(spark, velocity)

func spawn_hit_burst(position: Vector2, knockback: float) -> void:
	"""Spawn burst effect on strong hits"""
	var burst = ColorRect.new()
	burst.color = HIT_BLOOD_COLOR
	burst.size = Vector2(20, 20)
	burst.position = position - Vector2(10, 10)
	add_child(burst)
	
	# Expand and fade
	var tween = create_tween()
	tween.tween_property(burst, "scale", Vector2(3, 3), 0.15)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, 0.15)
	tween.tween_callback(burst.queue_free)

func spawn_shield_hit(position: Vector2) -> void:
	"""Spawn shield impact particles"""
	for i in range(8):
		var particle = ColorRect.new()
		particle.color = SHIELD_HIT_COLOR
		particle.size = Vector2(6, 6)
		particle.position = position
		add_child(particle)
		
		var angle = (i / 8.0) * TAU
		var velocity = Vector2(cos(angle), sin(angle)) * 150
		animate_spark(particle, velocity)

func animate_spark(spark: ColorRect, velocity: Vector2) -> void:
	"""Animate a spark particle"""
	var duration = 0.3
	var elapsed = 0.0
	
	while elapsed < duration and is_instance_valid(spark):
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
		velocity.y += 500 * get_process_delta_time()  # Gravity
		spark.position += velocity * get_process_delta_time()
		spark.modulate.a = 1.0 - (elapsed / duration)
	
	if is_instance_valid(spark):
		spark.queue_free()

func spawn_trail(parent: Node2D, color: Color) -> Node2D:
	"""Create a trail effect for fast-moving characters"""
	var trail = Node2D.new()
	trail.name = "TrailEffect"
	parent.add_child(trail)
	
	# Spawn trail segments
	for i in range(TRAIL_LENGTH):
		var segment = ColorRect.new()
		segment.color = color
		segment.color.a = 0.3 * (1.0 - float(i) / TRAIL_LENGTH)
		segment.size = Vector2(30, 50)
		segment.position = Vector2(-i * 5, 0)
		trail.add_child(segment)
	
	return trail

func spawn_impact_lines(position: Vector2, angle: float) -> void:
	"""Spawn impact lines ( Smash-style white lines )"""
	for i in range(3):
		var line = ColorRect.new()
		line.color = Color.WHITE
		line.size = Vector2(30, 4)
		line.position = position
		line.rotation = angle + randf_range(-0.3, 0.3)
		add_child(line)
		
		# Animate line shooting out
		var tween = create_tween()
		var direction = Vector2(cos(line.rotation), sin(line.rotation))
		tween.tween_property(line, "position", position + direction * 60, 0.1)
		tween.parallel().tween_property(line, "modulate:a", 0.0, 0.1)
		tween.tween_callback(line.queue_free)

func spawn_landing_dust(position: Vector2) -> void:
	"""Spawn dust particles on landing"""
	for i in range(5):
		var dust = ColorRect.new()
		dust.color = Color(0.8, 0.8, 0.7, 0.6)
		dust.size = Vector2(8, 8)
		dust.position = position + Vector2(randf_range(-20, 20), 0)
		add_child(dust)
		
		var tween = create_tween()
		tween.tween_property(dust, "position:y", dust.position.y - 30, 0.3)
		tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.3)
		tween.tween_callback(dust.queue_free)

func spawn_charge_effect(position: Vector2, player_id: int) -> void:
	"""Spawn charging particles for smash attacks"""
	var color = Color(1.0, 0.5, 0.0, 0.7) if player_id == 1 else Color(0.0, 0.5, 1.0, 0.7)
	for i in range(3):
		var particle = ColorRect.new()
		particle.color = color
		particle.size = Vector2(6, 6)
		var angle = randf() * TAU
		var dist = randf_range(20, 40)
		particle.position = position + Vector2(cos(angle), sin(angle)) * dist
		add_child(particle)
		
		var tween = create_tween()
		tween.tween_property(particle, "position", position, 0.2)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.2)
		tween.tween_callback(particle.queue_free)

func spawn_shield_break_effect(position: Vector2) -> void:
	"""Spawn shield break explosion"""
	for i in range(12):
		var shard = ColorRect.new()
		shard.color = Color(0.3, 0.6, 1.0, 0.9)
		shard.size = Vector2(8, 8)
		shard.position = position
		add_child(shard)
		
		var angle = (i / 12.0) * TAU
		var velocity = Vector2(cos(angle), sin(angle)) * randf_range(200, 400)
		
		var tween = create_tween()
		tween.tween_property(shard, "position", position + velocity * 0.3, 0.3)
		tween.parallel().tween_property(shard, "rotation", randf_range(-PI, PI), 0.3)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.3)
		tween.tween_callback(shard.queue_free)

func spawn_spawn_flash(position: Vector2) -> void:
	"""Spawn respawn flash effect"""
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.8)
	flash.size = Vector2(100, 100)
	flash.position = position - Vector2(50, 50)
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "scale", Vector2(3, 3), 0.4)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.4)
	tween.tween_callback(flash.queue_free)
