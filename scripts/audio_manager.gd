# Audio Manager
# Modular sound effects system - does NOT modify existing gameplay code
# Plays sounds via signals and function calls

extends Node
class_name AudioManager

# Sound effect library
var sounds: Dictionary = {}

# Audio players (pool for concurrent sounds)
var audio_players: Array = []
const MAX_CONCURRENT_SOUNDS: int = 8

func _ready():
	print("AudioManager initialized")
	setup_audio_pool()
	create_placeholder_sounds()

func setup_audio_pool() -> void:
	# Create pool of audio players for concurrent sounds
	for i in range(MAX_CONCURRENT_SOUNDS):
		var player = AudioStreamPlayer.new()
		player.name = "AudioPlayer_" + str(i)
		add_child(player)
		audio_players.append(player)

func create_placeholder_sounds() -> void:
	# Create synthesized placeholder sounds using Godot's generator
	# These can be replaced with real WAV/OGG files later
	
	# Jump sound - short ascending beep
	sounds["jump"] = create_tone_sound(440.0, 0.15, 0.3)  # A4 note
	
	# Attack sound - quick noise burst
	sounds["attack"] = create_tone_sound(220.0, 0.08, 0.4)  # A3 note
	
	# Hit sound - impact thud
	sounds["hit"] = create_tone_sound(110.0, 0.1, 0.5)  # A2 note
	
	# Strong hit - heavier impact
	sounds["hit_strong"] = create_tone_sound(80.0, 0.15, 0.6)  # Low thud
	
	# Death/KO - descending tone
	sounds["death"] = create_tone_sound(150.0, 0.4, 0.5)  # Descending
	
	# Landing - soft thud
	sounds["land"] = create_tone_sound(200.0, 0.05, 0.2)  # Quick bump
	
	print("Created ", sounds.size(), " placeholder sounds")

func create_tone_sound(frequency: float, duration: float, volume_db: float) -> AudioStream:
	# Create a simple tone using Godot's AudioStreamGenerator
	# This is a placeholder - replace with actual sound files later
	
	var sample_rate = 44100
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit = 2 bytes per sample
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		# Simple sine wave with quick attack/decay
		var envelope = 1.0 - (float(i) / num_samples)  # Linear decay
		var sample = sin(t * frequency * TAU) * envelope * 0.5
		
		# Convert to 16-bit
		var value = int(sample * 32767)
		data.encode_s16(i * 2, value)
	
	stream.data = data
	return stream

func play_sound(sound_name: String) -> void:
	# Play a sound by name
	if not sounds.has(sound_name):
		return
	
	# Find available audio player
	for player in audio_players:
		if not player.playing:
			player.stream = sounds[sound_name]
			player.play()
			return

func play_jump() -> void:
	play_sound("jump")

func play_attack() -> void:
	play_sound("attack")

func play_hit(strong: bool = false) -> void:
	if strong:
		play_sound("hit_strong")
	else:
		play_sound("hit")

func play_death() -> void:
	play_sound("death")

func play_land() -> void:
	play_sound("land")

# Public API for external systems
func on_player_jump(_player_id: int) -> void:
	play_jump()

func on_player_attack(_player_id: int) -> void:
	play_attack()

func on_player_hit(_player_id: int, damage: float) -> void:
	play_hit(damage > 10.0)

func on_player_death(_player_id: int) -> void:
	play_death()

func on_player_land(_player_id: int) -> void:
	play_land()
