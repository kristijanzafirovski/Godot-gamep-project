# RecycleBoy

> This project was developed as a **FINKI course project** (Faculty of Computer Science and Engineering, Ss. Cyril and Methodius University in Skopje). It is a Godot game built as a homework assignment.

RecycleBoy is a 3D action game made in Godot 4. The player explores a polluted landscape, collects scattered trash, and then activates a purifier. Pollution rises over time, and the environment changes as it does.

## Gameplay

- Each game spawns between 5 and 15 pieces of trash in a random layout across the map, so no two games are the same.
- The pollution level increases every second. Collecting trash reduces it slightly.
- The purifier can only be activated after every piece of trash has been collected. Otherwise a warning is shown.
- As pollution grows, the fog thickens, the sky and water darken, and the lighting shifts toward a dirty palette.
- The game is **lost** if pollution reaches 100%, and **won** when all trash is collected and the purifier is activated.

## Features

- Procedurally scattered trash and terrain vegetation.
- A lake in the middle of the terrain with animated waves.
- Swimming mechanics: the player can swim in the water.
- A camera that follows the player on a dedicated pivot.
- A HUD with the pollution bar, remaining trash count and elapsed time.

## Built with

- **Godot 4** (Forward+ renderer)
- **[Terrain3D](https://github.com/TokisanGames/Terrain3D)**: sculpted terrain with multiple regions and mountains
- **Proton Scatter**: rule-based placement of trees, rocks and bushes
- **Mixamo**: the player character and its animations. The bundled `mixamo_animation_retargeter` add-on retargets these animations to a standard Godot skeleton.

## Getting started

1. Install Godot 4.6 or later.
2. Clone the repository and open `project.godot` in Godot.
3. Make sure the add-ons under `addons/` are enabled in **Project → Project Settings → Plugins**.
4. Press **F5** to run the game. The main scene is `Scenes/Main.tscn`.

## Project structure

```
├── Scenes/          # Main scene, player, trash, purifier
├── Scripts/Game/    # GameManager (main.gd), trash, purifier, TrashSpawner
├── Animations/      # Retargeted character animations
├── assets/          # Models and textures (trash, purifier)
└── addons/          # Terrain3D, Proton Scatter, Mixamo retargeter
```

Each bundled add-on keeps its own license file.

## License

The original game code is released under the GNU GPL v3. See [LICENSE](LICENSE). The bundled add-ons, models and textures are subject to their own licenses.

## Author

**Kristijan Zafirovski**
