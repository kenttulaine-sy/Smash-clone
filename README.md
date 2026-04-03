# Smash Clone

A Super Smash Bros style platform fighter built with Godot 4.

## Features

- **1v1 Combat System** - 11 different attacks (jab, tilts, smashes, aerials)
- **Frame Data** - Startup, active, recovery frames for precise timing
- **Knockback System** - Damage-based knockback scaling
- **Double Jump & Fast Fall** - Classic platform fighter movement
- **3D Character Models** - Fortnite-style characters with procedural animation

## Controls

### Player 1
- **A / D** - Move Left/Right
- **W** - Jump (double tap for double jump)
- **S** - Fast Fall
- **J** - Attack

### Player 2
- **← / →** - Move Left/Right
- **↑** - Jump
- **↓** - Fast Fall
- **K** - Attack

## Attack Variations
- **J alone** - Jab (quick punch)
- **A/D + J** - Forward tilt
- **W + J** - Up tilt
- **S + J** - Down tilt

## Technical Details

- **Engine:** Godot 4.6.2
- **Language:** GDScript
- **Architecture:** State machine based player controller
- **Combat:** Modular CombatSystem with configurable constants

## Project Structure

```
scenes/         - Game scenes
scripts/        - GDScript files
assets/         - Models, textures, sounds
memory/         - Development logs
```

## Development

This project is actively developed. Check `memory/` for detailed development logs.

## License

MIT License - See LICENSE file
