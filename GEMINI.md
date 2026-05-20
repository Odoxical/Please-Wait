# Project: Please Wait

"Please Wait" is a 3D Godot-based game project focused on a quadruped robot with manual control over its locomotion. The core gameplay revolves around manipulating individual feet using Inverse Kinematics (IK) to navigate the environment.

## Project Overview

- **Engine:** Godot Engine 4.x (targeting 4.6 features)
- **Physics:** Powered by **Jolt Physics** (via the Godot Jolt plugin).
- **Core Mechanic:** Manual foot placement. The player selects a foot, lifts it, moves it in 3D space, and places it. The robot's body automatically re-centers itself based on the centroid of its grounded feet.
- **Secondary Mechanic:** A "Grabber" hand controlled by mouse input, featuring a "panic mode" that alters its speed and reach.

## Architecture & Key Components

### Locomotion System
- **`FootController` (`scripts/foot_controller.gd`):** Manages selection and movement of the four feet (FL, FR, RL, RR). It handles input for foot selection and movement vectors.
- **`FootTarget` (`scripts/foot_target.gd`):** Represents an individual foot's target position for the IK system. Manages states like `GROUNDED`, `LIFTED`, and `PLACING`.
- **`SkeletonIK3D`:** Used within the robot's skeleton to align the mesh legs with the `FootTarget` markers.
- **Centroid-Based Movement:** The body position is updated via a `Tween` to the average position of all feet whenever a foot is placed.

### Interaction System
- **`Grabber` (`scripts/Grabber.gd`):** A mouse-controlled hand/grabber. It uses mouse motion for X/Z movement and scroll wheel for Y (height) control. Features a "panic" toggle that doubles speed and reach.

### Configuration
- **`FootConfig` (`resources/foot_config.gd`):** A `Resource` class defining constants like `move_speed`, `lift_height`, and `max_reach`.
- **`foot_config.tres`:** The actual resource instance used by the controllers.

## Directory Structure

- `scenes/`: Godot scene files (`.tscn`).
    - `Main.tscn`: Likely the primary entry point or testing environment.
    - `Body.tscn`: The quadruped robot assembly.
    - `Hand.tscn`: The grabber assembly.
- `scripts/`: GDScript logic files.
- `Models/`: 3D assets in `.glb` format.
- `resources/`: Custom Godot resources (`.tres`) and their script definitions.

## Building and Running

### Requirements
- **Godot Engine 4.x** (Preferably 4.6+)
- **Godot Jolt** physics plugin.

### Execution
1. Open the project in the Godot Editor:
   ```bash
   godot --editor --path .
   ```
2. Run the main scene:
   ```bash
   godot --path .
   ```

## Development Conventions

- **Type Safety:** Use GDScript 2.0 static typing (`: Type`, `-> void`) where possible.
- **Decoupling:** Use `Resource` files for configuration instead of hardcoding values in scripts.
- **Communication:** Prefer Signals for upward communication (e.g., `foot_placed` signal) and direct calls for downward communication.
- **IK Management:** Ensure `SkeletonIK3D` nodes are started in `_ready()` or when needed.
- **Input Map:** Input actions are defined in `project.godot`. Key actions include `move_forward/back/left/right`, `select_foot_1-4`, `move_up/down`, and `panic`.

## TODO / Future Work
- [ ] Implement collision detection for foot placement to prevent clipping.
- [ ] Refine "panic mode" visual feedback.
- [ ] Expand the `Foods.tscn` system (possibly items for the grabber to interact with).
