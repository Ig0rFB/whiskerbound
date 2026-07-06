# Untitled Game

A 3D platformer game built with **Godot Engine 4.5** featuring a character controller with a comprehensive state machine, third-person camera system, and an interaction framework.

---

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Controls](#controls)
- [Systems](#systems)
  - [Player Character](#player-character)
  - [State Machine](#state-machine)
  - [Camera System](#camera-system)
  - [Interaction System](#interaction-system)
  - [NPC System](#npc-system)
- [Adding New Content](#adding-new-content)
- [Assets](#assets)

---

## Overview

This project is a 3D platformer template/game featuring:

- **State-based character controller** with walking, running, jumping, falling, and ragdoll states
- **Advanced jump mechanics** including coyote time, jump buffering, variable jump height, and multi-jump support
- **Third-person camera** with orbit controls, zoom, and aim modes
- **Interaction system** using raycasting for object/NPC interaction
- **Debug HUD** for real-time monitoring of character states and properties
- **Particle effects** and visual feedback (squash & stretch, dust particles)
- **Audio system** for footsteps and impact sounds

---

## Project Structure

```
untitled-game/
├── addons/                     # Third-party addons and character models
│   ├── gdquest_*/              # GDQuest character model packs
│   │   ├── *_skin.gd           # Character skin scripts
│   │   ├── *_skin.tscn         # Character skin scenes
│   │   └── materials/          # Character materials and textures
│   └── gdquest_model_viewer_3d/ # Model viewer plugin
│
├── Art/                        # Game art assets
│   ├── Fonts/                  # Custom fonts (Ticketing.ttf)
│   ├── GodotPlush/             # Default player character model
│   │   ├── CustomAnimations/   # Animation resources
│   │   ├── godot_plush_skin.*  # Main character skin
│   │   └── Material/           # Character shader and textures
│   ├── Images/                 # UI and misc images
│   ├── Materials/              # Shared materials (colours, grid)
│   └── Sounds/                 # Audio files (footsteps, jingles)
│
├── NPCs/                       # Non-player character system
│   ├── BaseNPC.tscn            # Reusable NPC template scene
│   └── NPCBody.gd              # NPC physics script
│
├── Player/                     # Player character system
│   ├── Camera/                 # Camera control system
│   │   ├── orbit_view.gd       # Camera orbit/aim logic
│   │   └── orbit_view.tscn     # Camera rig scene
│   ├── Debug/                  # Debug overlay
│   │   └── DebugHUDScript.gd   # Debug HUD controller
│   ├── PlayerCharacterScene.tscn # Main player scene
│   ├── StateMachine/           # Character state machine
│   │   ├── state_script.gd     # Base State class
│   │   ├── state_machine_script.gd # State machine controller
│   │   ├── player_character_script.gd # Main character script
│   │   ├── idle_state_script.gd
│   │   ├── walk_state_script.gd
│   │   ├── run_state_script.gd
│   │   ├── jump_state_script.gd
│   │   ├── inair_state_script.gd
│   │   └── ragdoll_state_script.gd
│   └── VFX/                    # Visual effects
│       ├── jump_particles.tscn
│       ├── land_particles.tscn
│       └── particles_manager_script.gd
│
├── Scenes/                     # Game scenes
│   └── TestMapScene.tscn       # Main test/development scene
│
├── Systems/                    # Game systems
│   ├── Interactions/           # Interaction framework
│   │   └── Interactable.gd     # Base interactable class
│   └── Tools/                  # Utility scripts
│
├── UI/                         # User interface
│   └── InteractionPrompt.tscn  # "[E] Interact" prompt
│
└── project.godot               # Godot project configuration
```

---

## Controls

| Action | Key/Input | Description |
|--------|-----------|-------------|
| Move Forward | `W` | Move character forward |
| Move Backward | `S` | Move character backward |
| Move Left | `A` | Strafe left |
| Move Right | `D` | Strafe right |
| Jump | `Space` | Jump (hold for higher jump) |
| Run | `Shift` | Toggle/hold to run |
| Ragdoll | `R` | Toggle ragdoll mode |
| Interact | `E` | Interact with objects/NPCs |
| Toggle Mouse | `Escape` | Release/capture mouse cursor |
| Aim Mode | `Right Mouse Button` | Toggle aim/shoulder camera |
| Switch Aim Side | `T` | Switch between left/right shoulder |
| Pan Camera | `Arrow Keys` | Pan camera with keyboard |
| Zoom In | `=` | Zoom camera in |
| Zoom Out | `-` | Zoom camera out |

---

## Systems

### Player Character

The player character (`PlayerCharacterScene.tscn`) is a `CharacterBody3D` with the following components:

**Movement Properties:**
- Configurable walk/run speeds, acceleration, and deceleration
- Smooth movement interpolation using `lerp()`
- Camera-relative movement direction

**Jump Properties:**
- Physics-based jump using calculated velocity and gravity
- **Coyote Time**: Grace period to jump after leaving a platform
- **Jump Buffering**: Queue jumps before landing
- **Variable Jump Height**: Release jump early for shorter jumps
- **Multi-Jump**: Configurable number of air jumps

**Visual Feedback:**
- Squash and stretch effects on jump/land
- Dust particles when running
- Jump and landing particle effects

### State Machine

The state machine (`StateMachine/`) implements a classic state pattern:

**Base Class (`state_script.gd`):**
```gdscript
class_name State
extends Node

signal transitioned

func enter(_char_reference: CharacterBody3D): pass
func exit(): pass
func update(_delta: float): pass
func physics_update(_delta: float): pass
```

**Available States:**

| State | Description |
|-------|-------------|
| `IdleState` | Character standing still, no input |
| `WalkState` | Character moving at walk speed |
| `RunState` | Character moving at run speed (with dust particles) |
| `JumpState` | Character ascending from a jump |
| `InairState` | Character falling/descending |
| `RagdollState` | Character in ragdoll physics mode |

**State Transitions:**
- States emit the `transitioned` signal with the new state name
- The `StateMachine` handles transitions via `on_state_child_transition()`
- Each state manages its own transition logic based on input and physics

### Camera System

The camera (`orbit_view.gd`) extends `SpringArm3D` for collision handling:

**Features:**
- Mouse-controlled orbit rotation
- Keyboard pan controls (arrow keys)
- Zoom in/out with clamping
- Two camera modes:
  - **Default Mode**: Standard third-person follow
  - **Aim Mode**: Over-the-shoulder view (switchable sides)
- Automatic collision avoidance via `SpringArm3D`

**Key Properties:**
```gdscript
@export var mouse_sens: float       # Mouse sensitivity
@export var min_limit_x: float      # Minimum vertical rotation
@export var max_limit_x: float      # Maximum vertical rotation
@export var aim_cam_pos: Vector3    # Offset for aim mode
```

### Interaction System

The interaction system uses raycasting to detect interactable objects:

**How It Works:**
1. A `RayCast3D` node is attached to the player, synced with camera rotation
2. Every physics frame, the ray checks for collisions
3. If a collision occurs, it checks for an `Interactable` child node
4. If found, the interaction prompt appears
5. Pressing `E` calls `interact()` on the target

**Creating Interactable Objects:**

1. Add a `StaticBody3D` (or similar) with a `CollisionShape3D`
2. Set the collision layer to `2` (interactable layer)
3. Add a child `Node` with the `Interactable.gd` script

**Extending Interactable (`Systems/Interactions/Interactable.gd`):**
```gdscript
class_name Interactable
extends Node

func interact(_user: Node):
    print("Interacted with ", get_parent().name)
    # Override this method for custom behaviour
```

**Example Custom Interactable:**
```gdscript
extends Interactable

func interact(user: Node):
    print("Chest opened by ", user.name)
    # Add item to inventory, play animation, etc.
```

### NPC System

NPCs use a reusable template (`NPCs/BaseNPC.tscn`):

**BaseNPC Structure:**
```
BaseNPC (CharacterBody3D)
├── CollisionShape3D (CapsuleShape3D)
└── Interactable (Node with Interactable.gd)
```

**NPCBody.gd Features:**
- `motion_type` enum: `GROUNDED` or `FLOATING`
- Automatic gravity application for grounded NPCs
- Compatible with any character skin

**Creating a New NPC:**
1. Instance `BaseNPC.tscn` in your scene
2. Add a character skin scene as a child (e.g., `gdbot_skin.tscn`)
3. Position the NPC in the world
4. Optionally set `motion_type` to `FLOATING` for flying NPCs

---

## Adding New Content

### Adding a New State

1. Create a new script in `Player/StateMachine/`:
```gdscript
extends State

class_name MyNewState

var state_name: String = "MyNew"
var cR: CharacterBody3D

func enter(char_ref: CharacterBody3D):
    cR = char_ref
    # Initialisation logic

func physics_update(delta: float):
    # State logic
    # Transition example:
    if some_condition:
        transitioned.emit(self, "IdleState")
```

2. Add the state as a child of `StateMachine` in `PlayerCharacterScene.tscn`
3. Add transitions to/from this state in relevant state scripts

### Adding a New Character Skin

1. Import your 3D model with animations
2. Create a skin script extending `Node3D`:
```gdscript
extends Node3D

signal footstep(intensity: float)

@onready var animation_tree = $AnimationTree

func set_state(state_name: String):
    # Set animation based on state
    pass
```

3. Create a `.tscn` scene with the model and script
4. Replace `%GodotPlushSkin` reference in `PlayerCharacterScene.tscn`

### Adding New Interactable Types

1. Create a new script extending `Interactable`:
```gdscript
extends Interactable

@export var item_name: String = "Unknown Item"

func interact(user: Node):
    print(user.name, " picked up ", item_name)
    # Add to inventory, destroy object, etc.
    queue_free()
```

2. Attach to a `Node` child of your interactable object

---

## Assets

This project includes character models from **GDQuest**:
- GDBot
- Gobot  
- Sophia
- Bee Bot
- Beetle Bot
- Round Bat

The default player character is the **Godot Plush** model with custom animations.

**Audio:**
- Footstep sounds (concrete)
- Impact/landing sounds
- Jingle sound effects

**Materials:**
- Colour materials (red, blue, green, yellow)
- Grid material for level design

---

## Debug HUD

The debug overlay displays real-time information:

| Label | Description |
|-------|-------------|
| Current State | Active state machine state |
| Velocity | Character movement speed |
| Jumps In Air | Remaining air jumps |
| Jump Buffer | Jump buffer status |
| Coyote Time | Remaining coyote time |
| Model Orientation | Camera follower or independent |
| Camera Mode | Default or aim mode |
| FPS | Frames per second |
| Interact Target | Currently targeted interactable |

---

## Collision Layers

| Layer | Purpose |
|-------|---------|
| 1 | NPCs and characters |
| 2 | Environment and interactables |

The player's collision mask is set to `3` (both layers) to collide with NPCs and environment.

---

## Known Issues

- The `round_bat_skin.tscn` file may have parsing errors if modified incorrectly
- Some character skins require a `footstep` signal for audio integration

---

## Licence

See `LICENSE` and `license.md` for licensing information.


