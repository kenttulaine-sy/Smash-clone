# Model3DManager
# Safely integrates 3D GLB model into existing 2D player setup
# Preserves all gameplay systems: movement, combat, hit detection

extends Node2D
class_name Model3DManager

# Model configuration
@export var model_path: String = "res://assets/2d_fortnite.glb"
@export var model_scale: Vector3 = Vector3(0.5, 0.5, 0.5)
@export var model_offset: Vector3 = Vector3(0, -30, 0)
@export var use_3d_model: bool = true

# References
var model_instance: Node3D = null
var original_visuals: Node2D = null
var parent_player: CharacterBody2D = null

func _ready():
	parent_player = get_parent() as CharacterBody2D
	if parent_player == null:
		push_error("Model3DManager must be child of CharacterBody2D")
		return
	
	# Store reference to original 2D visuals
	original_visuals = parent_player.get_node_or_null("Visuals")
	
	if use_3d_model:
		integrate_3d_model()
	else:
		print("Model3DManager: Using original 2D visuals")

func integrate_3d_model() -> void:
	print("Model3DManager: Loading 3D model from ", model_path)
	
	# Load the GLB model
	var model_scene = load(model_path)
	if model_scene == null:
		push_error("Failed to load model: " + model_path)
		return
	
	# Instantiate the model
	model_instance = model_scene.instantiate()
	if model_instance == null:
		push_error("Failed to instantiate model")
		return
	
	# Hide original 2D visuals but keep for fallback
	if original_visuals:
		original_visuals.visible = false
		print("Model3DManager: Original visuals hidden")
	
	# Add model as child of this manager
	add_child(model_instance)
	
	# Apply configuration
	configure_model()
	
	print("Model3DManager: 3D model integrated successfully")

func configure_model() -> void:
	if model_instance == null:
		return
	
	# Apply scale
	model_instance.scale = model_scale
	
	# Apply offset (move model so feet align with player position)
	model_instance.position = model_offset
	
	# Ensure model faces right (positive X) initially
	model_instance.rotation_degrees = Vector3(0, 0, 0)
	
	print("Model3DManager: Model configured - scale:", model_scale, " offset:", model_offset)

func update_facing(facing_right: bool) -> void:
	"""Update model orientation based on facing direction"""
	if model_instance == null:
		return
	
	# Flip model by scaling X (negative = left, positive = right)
	var target_scale_x = abs(model_scale.x) if facing_right else -abs(model_scale.x)
	model_instance.scale.x = target_scale_x

func set_model_visible(is_visible: bool) -> void:
	"""Toggle model visibility (for death/respawn)"""
	if model_instance:
		model_instance.visible = is_visible
	if original_visuals:
		original_visuals.visible = is_visible and not use_3d_model

func flash_color(color: Color, duration: float) -> void:
	"""Flash model color for hit feedback (simplified)"""
	if model_instance == null:
		return
	
	# For now, just print - full material flashing requires async handling
	# TODO: Implement material emission flash with timer callback
	print("Model3DManager: Flash color ", color, " for ", duration, "s")

func _on_flash_timeout(mesh: MeshInstance3D, original_color: Color) -> void:
	"""Reset mesh color after flash"""
	if is_instance_valid(mesh) and mesh.material_override:
		mesh.material_override.emission = original_color

func find_mesh_instances(node: Node) -> Array:
	"""Recursively find all MeshInstance3D nodes"""
	var meshes = []
	if node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		meshes.append_array(find_mesh_instances(child))
	
	return meshes

func get_model_bounds() -> AABB:
	"""Get the 3D model bounds for hitbox alignment"""
	if model_instance == null:
		return AABB()
	
	var aabb = AABB()
	var first_mesh = true
	
	for mesh in find_mesh_instances(model_instance):
		if first_mesh:
			aabb = mesh.get_aabb()
			first_mesh = false
		else:
			aabb = aabb.merge(mesh.get_aabb())
	
	return aabb
