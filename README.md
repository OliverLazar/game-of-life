# Game of Life

A digital adaptation of the classic board game "The Game of Life" built with Godot Engine 4.3.

## About

This project was created as a student group project and represents our first experience working with Godot Engine!  We set out to recreate the beloved board game "The Game of Life" in digital form, learning game development along the way.  Through this project, we explored 3D modeling, GDScript programming, scene management, collaborative development, and general game design.

## Features

- 🎮 Interactive gameplay based on the classic board game
- 🎨 Custom 3D models and stylized graphics
- 🗺️ Dynamic game map system
- 🎯 Main menu interface
- 🎲 Turn-based gameplay mechanics

## Tech Stack

- **Engine**: Godot 4.3 (Forward Plus renderer)
- **Language**: GDScript
- **Platform**: Cross-platform support

## Project Structure

```
game-of-life/
├── Cards/          # Game card assets and definitions
├── Media/          # Audio and video resources
├── Models/         # 3D models and assets
├── Scenes/         # Godot scene files
├── Scripts/        # GDScript game logic
│   ├── Main Menu/  # Main menu functionality
│   ├── Map/        # Game map systems
│   ├── ball boink/ # Physics/interaction systems
│   └── movement_test/ # Movement testing
├── Textures/       # Texture assets
└── stylized bush/  # Environment assets
```

## Getting Started

### Playing the Game

1. Go to the [Releases page](https://github.com/OliverLazar/game-of-life/releases)
2. Download the latest release ZIP file
3. Extract the ZIP file to a folder of your choice
4. Run the `.exe` file to start playing! 

### Development Setup

If you want to modify or develop the project:

1. Clone the repository: 
   ```bash
   git clone https://github.com/OliverLazar/game-of-life.git
   ```

2. Open the project in Godot: 
   - Download and install [Godot Engine 4.3](https://godotengine.org/download) or later
   - Launch Godot Engine
   - Click "Import"
   - Navigate to the cloned directory
   - Select the `project.godot` file
   - Click "Import & Edit"

3. Run the project:
   - Press `F5` or click the "Play" button in Godot

## Development

### Running the Game

The main scene is located at `res://Scenes/Main Menu.tscn` and will launch automatically when running the project.

## License

This project is provided as-is. Please ensure compliance with the original "Game of Life" board game's intellectual property rights if using this commercially.
