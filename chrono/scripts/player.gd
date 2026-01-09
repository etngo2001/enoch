extends CharacterBody2D


const SPEED = 120.0
const JUMP_VELOCITY = -300.0
const REWIND_DURATION = 4.0
var ghost_timer := 0.0
const GHOST_INTERVAL := 0.05

@onready var animated_sprite = $AnimatedSprite2D

@export var ghost_scene: PackedScene

var state_history: Array = []
var is_rewinding := false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY	

	# Get the input direction
	var direction := Input.get_axis("move_left", "move_right")
	
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

	# Flip sprite based on directional input
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	record_state()
	handle_rewind()
	
	ghost_timer += delta

	if ghost_timer >= GHOST_INTERVAL:
		ghost_timer = 0.0
		spawn_ghost()


func record_state():
	# Save a snapshot of the player's current state
	# We store enough data to fully restore the player later
	state_history.append({
		"position": global_position,                  # Where the player was
		"velocity": velocity,                         # How fast they were moving
		"animation": animated_sprite.animation,       # Which animation was playing
		"flip_h": animated_sprite.flip_h,             # Which way the sprite was facing
		"time": Time.get_ticks_msec()                  # When this snapshot was taken
	})

	# Calculate the oldest time we want to keep (now - rewind duration)
	var cutoff_time = Time.get_ticks_msec() - int(REWIND_DURATION * 1000)

	# Remove any snapshots older than the rewind window
	# This keeps memory usage small and predictable
	while state_history.size() > 0 and state_history[0]["time"] < cutoff_time:
		state_history.pop_front()

func handle_rewind():
	# Only trigger rewind when the button is pressed (not held)
	if Input.is_action_just_pressed("time_rewind"):
		rewind_player()

func rewind_player():
	# If we have no history, there is nothing to rewind to
	if state_history.is_empty():
		return

	# Temporarily disable physics and input
	is_rewinding = true

	# Target time we want to rewind to
	var target_time = Time.get_ticks_msec() - int(REWIND_DURATION * 1000)

	# Find the first saved state that occurred AFTER the target time
	# This gives us the closest possible rewind position
	for state in state_history:
		if state["time"] >= target_time:
			global_position = state["position"]
			velocity = state["velocity"]
			animated_sprite.play(state["animation"])
			animated_sprite.flip_h = state["flip_h"]
			break

	# Clear history so rewind can't be instantly spammed
	state_history.clear()

	# Re-enable physics and input
	is_rewinding = false

func spawn_ghost():
	# Safety check in case the scene isn't assigned
	if ghost_scene == null:
		return

	# Create a new ghost instance
	var ghost = ghost_scene.instantiate()

	# Place it exactly where the player is right now
	ghost.global_position = global_position

	# Copy visual state from the player
	var ghost_sprite: AnimatedSprite2D = ghost.get_node("AnimatedSprite2D")

	ghost_sprite.sprite_frames = animated_sprite.sprite_frames
	ghost_sprite.play(animated_sprite.animation)
	ghost_sprite.frame = animated_sprite.frame
	ghost_sprite.flip_h = animated_sprite.flip_h

	# Optional: tint ghost slightly blue
	ghost_sprite.modulate = Color(0.6, 0.8, 1.0, 0.5)

	# Add ghost to the scene (same parent as player)
	get_parent().add_child(ghost)
