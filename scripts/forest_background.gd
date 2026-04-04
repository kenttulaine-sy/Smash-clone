# Forest Background Loader
# Loads parallax forest layers from Free Pixel Art Forest

extends Node2D
class_name ForestBackground

const LAYER_PATH = "res://assets/Free Pixel Art Forest/PNG/Background layers/"
const LAYERS = [
	"Layer_0011_0.png",  # Sky (furthest)
	"Layer_0010_1.png",  # Distant mountains
	"Layer_0009_2.png",  # Mountains
	"Layer_0008_3.png",  # Trees back
	"Layer_0007_Lights.png",  # Lights
	"Layer_0006_4.png",  # Trees mid
	"Layer_0005_5.png",  # Trees front
	"Layer_0004_Lights.png",  # Front lights
	"Layer_0003_6.png",  # Ground back
	"Layer_0002_7.png",  # Ground mid
	"Layer_0001_8.png",  # Ground front
	"Layer_0000_9.png"   # Foreground (closest)
]

const PARALLAX_SPEEDS = [
	0.05,  # Sky - very slow
	0.1,   # Distant mountains
	0.15,  # Mountains
	0.2,   # Trees back
	0.25,  # Lights
	0.3,   # Trees mid
	0.35,  # Trees front
	0.4,   # Front lights
	0.5,   # Ground back
	0.6,   # Ground mid
	0.7,   # Ground front
	0.8    # Foreground
]

var camera: Camera2D = null
var layer_sprites: Array = []

func _ready():
	print("ForestBackground: Loading parallax forest...")
	
	# Find camera
	camera = get_node_or_null("../Camera2D")
	if not camera:
		print("ForestBackground: Camera not found, using static background")
	
	load_background_layers()

func load_background_layers():
	"""Load each forest layer as a sprite"""
	
	for i in range(LAYERS.size()):
		var layer_file = LAYERS[i]
		var layer_path = LAYER_PATH + layer_file
		
		# Load image
		var image = Image.new()
		var err = image.load(layer_path)
		
		if err != OK:
			push_error("Failed to load forest layer: " + layer_path)
			continue
		
		# Create texture
		var texture = ImageTexture.create_from_image(image)
		if not texture:
			push_error("Failed to create texture from: " + layer_path)
			continue
		
		# Create sprite for this layer
		var sprite = Sprite2D.new()
		sprite.name = "ForestLayer_" + str(i)
		sprite.texture = texture
		sprite.centered = false  # Top-left origin
		sprite.position = Vector2(0, 0)
		
		# Scale to fit screen height
		var screen_height = 1080.0
		var scale = screen_height / texture.get_height()
		sprite.scale = Vector2(scale, scale)
		
		# Store layer info for parallax
		layer_sprites.append({
			"sprite": sprite,
			"speed": PARALLAX_SPEEDS[i],
			"base_x": 0.0
		})
		
		# Add to scene (furthest first)
		add_child(sprite)
		
		print("ForestBackground: Loaded layer ", i, " - ", layer_file)
	
	print("ForestBackground: Loaded ", layer_sprites.size(), " layers")

func _process(delta):
	"""Apply parallax scrolling based on camera position"""
	if not camera:
		return
	
	var camera_pos = camera.global_position
	var camera_zoom = camera.zoom.x if camera else 1.0
	
	for layer_info in layer_sprites:
		var sprite = layer_info.sprite
		var speed = layer_info.speed
		var base_x = layer_info.base_x
		
		# Calculate parallax position for X (horizontal scrolling)
		var parallax_x = base_x - (camera_pos.x * speed)
		
		# Wrap X for seamless horizontal scrolling
		var texture_width = sprite.texture.get_width() * sprite.scale.x
		while parallax_x > 0:
			parallax_x -= texture_width
		while parallax_x < -texture_width:
			parallax_x += texture_width
		
		# For Y: Keep background vertically aligned with camera so it stays visible
		# Background layers should follow camera Y but stay centered vertically
		var texture_height = sprite.texture.get_height() * sprite.scale.y
		var parallax_y = camera_pos.y - (texture_height / 2.0)
		
		sprite.position = Vector2(parallax_x, parallax_y)
		
		# Compensate for camera zoom - background shouldn't scale with zoom
		# Actually, let it scale naturally with zoom for depth effect
		# sprite.scale = Vector2(original_scale / camera_zoom, original_scale / camera_zoom)

func update_parallax(camera_position: Vector2):
	"""Manual update if needed"""
	for layer_info in layer_sprites:
		var sprite = layer_info.sprite
		var speed = layer_info.speed
		
		var texture_width = sprite.texture.get_width() * sprite.scale.x
		var parallax_x = -(camera_position.x * speed)
		
		# Wrap
		while parallax_x > 0:
			parallax_x -= texture_width
		while parallax_x < -texture_width:
			parallax_x += texture_width
		
		sprite.position.x = parallax_x
