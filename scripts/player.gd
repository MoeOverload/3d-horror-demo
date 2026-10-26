#move script
# Tells Godot this script controls a CharacterBody3D node.
# CharacterBody3D is useful for player movement and collision.
extends CharacterBody3D


# @export makes these variables editable in Godot's Inspector.
# This lets us adjust movement without changing the code.
@export var move_speed: float = 5.0

# Controls how quickly the mouse turns the player and camera.
@export var mouse_sensitivity: float = 0.002


# Finds the node named "Head" when the scene loads.
# The Head will rotate up and down independently of the player body.
@onready var head: Node3D = $Head


# Acceleration caused by gravity, in meters per second squared.
# We'll use this to pull the player down when they're airborne.
var gravity: float = 9.8


# Runs once when the player enters the active scene.
func _ready() -> void:
    # Locks the mouse to the game window for first-person camera control.
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Handles input events such as mouse movement and key presses.
func _unhandled_input(event: InputEvent) -> void:

    # Check whether the current event is mouse movement.
    if event is InputEventMouseMotion:

        # Rotate the entire player left and right.
        # Rotating the body changes the direction WASD movement faces.
        rotate_y(-event.relative.x * mouse_sensitivity)

        # Rotate only the Head up and down.
        # This allows us to look around without tilting the player's body.
        head.rotate_x(-event.relative.y * mouse_sensitivity)

        # Limit vertical camera rotation so we can't look endlessly
        # over our head or flip upside down.
        head.rotation.x = clamp(
            head.rotation.x,
            deg_to_rad(-85),
            deg_to_rad(85)
        )

    # Godot's built-in ui_cancel action is Escape by default.
    if event.is_action_pressed("ui_cancel"):

        # Unlock the mouse so we can interact with the editor or window.
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

    # If we click a mouse button, capture the mouse again.
    if event is InputEventMouseButton and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Runs during physics updates.
# We handle movement here because Godot's physics engine updates collisions
# on a fixed timestep.
func _physics_process(delta: float) -> void:

    # If the player isn't standing on a surface, apply gravity.
    if not is_on_floor():
        # delta is the time since the previous physics update.
        # Multiplying by delta makes gravity consistent across updates.
        velocity.y -= gravity * delta

    # If we're on the floor and still moving downward, stop that movement.
    if is_on_floor() and velocity.y < 0:
        velocity.y = 0


    # Read the movement actions and turn them into a 2D direction.
    # The result has an X value (left/right) and a Y value (forward/back).
    # The order here is left, right, forward, backward.
    var input_dir := Input.get_vector(
        "move_left",
        "move_right",
        "move_forward",
        "move_back"
    )


    # Convert the input direction into the player's facing direction.
    # transform.basis represents the player's rotation and orientation.
    # This makes W move forward relative to where the player is looking.
    # Vector3(input_dir.x, 0, input_dir.y) keeps movement horizontal.
    var direction := (
        transform.basis * Vector3(input_dir.x, 0, input_dir.y)
    ).normalized()


    # If the player is pressing a movement key...
    if direction:

        # Set horizontal velocity based on the direction and movement speed.
        # velocity.x is side-to-side movement.
        # velocity.z is forward-and-backward movement.
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed

    else:
        # If no movement key is pressed, gradually slow horizontal movement
        # until the player stops.
        # move_toward() moves a value toward a target without overshooting.
        velocity.x = move_toward(velocity.x, 0, move_speed)
        velocity.z = move_toward(velocity.z, 0, move_speed)


    # Apply velocity and handle collisions with the environment.
    # Godot updates the CharacterBody3D's position through this call.
    move_and_slide()
