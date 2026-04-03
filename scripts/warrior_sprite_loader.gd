# Warrior Sprite Loader
# Loads Tiny Swords PNGs at runtime and creates animated sprites

extends Node2D
class_name WarriorSpriteLoader

@export var warrior_color: String = "blue"  # blue or red
@export var sprite_scale: float = 3.0

var animated_sprite: AnimatedSprite2D = null
var sprite_frames: SpriteFrames = null

func _ready():
	create_animated_sprite()
	load_warrior_sprites()

func create_animated_sprite():
	"""Create the AnimatedSprite2D node"""
	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite2D"
	animated_sprite.scale = Vector2(sprite_scale, sprite_scale)
	animated_sprite.position = Vector2(0, -50)  # Offset so feet are at origin
	add_child(animated_sprite)
	
	sprite_frames = SpriteFrames.new()
	animated_sprite.frames = sprite_frames

func load_warrior_sprites():
	"""Load PNG files at runtime and create animations"""
	var base_path = "res://assets/warrior_" + warrior_color + "/"
	
	# Load Idle animation
	load_animation_from_sheet(base_path + "Warrior_Idle.png", "idle", 4, 8.0)
	
	# Load Run animation  
	load_animation_from_sheet(base_path + "Warrior_Run.png", "run", 6, 12.0)
	
	# Load Attack animation
	load_animation_from_sheet(base_path + "Warrior_Attack1.png", "attack", 4, 10.0)
	
	# Load Guard animation (for shield)
	load_animation_from_sheet(base_path + "Warrior_Guard.png", "guard", 3, 6.0)
	
	# Start with idle
	animated_sprite.play("idle")
	print("Warrior sprites loaded for ", warrior_color)

func load_animation_from_sheet(image_path: String, anim_name: String, frame_count: int, fps: float):
	"""Load a sprite sheet and split it into animation frames"""
	
	# Load image using Image class
	var image = Image.new()
	var err = image.load(image_path)
	
	if err != OK:
		push_error("Failed to load image: " + image_path + " Error: " + str(err))
		return
	
	# Create texture from image
	var texture = ImageTexture.create_from_image(image)
	
	if not texture:
		push_error("Failed to create texture from: " + image_path)
		return
	
	# Calculate frame dimensions
	var frame_width = texture.get_width() / frame_count
	var frame_height = texture.get_height()
	
	# Add animation to SpriteFrames
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_speed(anim_name, fps)
	sprite_frames.set_animation_loop(anim_name, anim_name != "attack")  # Attack doesn't loop
	
	# Create AtlasTexture for each frame
	for i in range(frame_count):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		
		# Center the texture
		atlas.margin = Rect2(0, 0, 0, 0)
		
		sprite_frames.add_frame(anim_name, atlas)
	
	print("Loaded animation '", anim_name, "' with ", frame_count, " frames from ", image_path)

func play_idle():
	if animated_sprite and animated_sprite.animation != "idle":
		animated_sprite.play("idle")

func play_run():
	if animated_sprite and animated_sprite.animation != "run":
		animated_sprite.play("run")

func play_attack():
	if animated_sprite:
		animated_sprite.play("attack")

func play_guard():
	if animated_sprite and animated_sprite.animation != "guard":
		animated_sprite.play("guard")

func set_facing_right(facing_right: bool):
	if animated_sprite:
		animated_sprite.flip_h = not facing_right

func is_playing_attack() -> bool:
	return animated_sprite and animated_sprite.animation == "attack" and animated_sprite.is_playing()
