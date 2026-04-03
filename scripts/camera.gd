extends Camera2D

var target_players: Array = []
var zoom_level: float = 1.0
var shake_strength: float = 0.0

func _ready():
    # Find players
    await get_tree().process_frame
    target_players = get_tree().get_nodes_in_group("players")
    if target_players.size() == 0:
        # Add players to group manually if not auto-detected
        var p1 = get_node("../Player1")
        var p2 = get_node("../Player2")
        if p1:
            p1.add_to_group("players")
        if p2:
            p2.add_to_group("players")
        target_players = [p1, p2]

func _process(delta):
    if target_players.size() == 0:
        return
    
    # Calculate average position
    var avg_pos = Vector2.ZERO
    var valid_players = 0
    
    for player in target_players:
        if is_instance_valid(player):
            avg_pos += player.global_position
            valid_players += 1
    
    if valid_players > 0:
        avg_pos /= valid_players
        position = position.lerp(avg_pos, 5 * delta)
    
    # Calculate required zoom based on player distance
    if valid_players >= 2:
        var max_distance = 0.0
        for i in range(valid_players):
            for j in range(i + 1, valid_players):
                if is_instance_valid(target_players[i]) and is_instance_valid(target_players[j]):
                    var dist = target_players[i].global_position.distance_to(target_players[j].global_position)
                    max_distance = max(max_distance, dist)
        
        # Zoom out if players are far apart
        var target_zoom = clamp(1.0 / (max_distance / 800.0 + 0.5), 0.5, 1.2)
        zoom_level = lerp(zoom_level, target_zoom, 2 * delta)
        zoom = Vector2(zoom_level, zoom_level)
    
    # Apply screen shake
    if shake_strength > 0:
        offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
        shake_strength = lerp(shake_strength, 0.0, 5 * delta)
    else:
        offset = Vector2.ZERO

func shake(strength: float):
    shake_strength = strength
