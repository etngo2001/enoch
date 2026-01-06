extends CharacterBody2D


const SPEED = 120.0
const JUMP_VELOCITY = -300.0
const REWIND_DURATION := 4.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var rewind_buffer: Array = []
@onready var is_rewinding := false
@onready var rewind_index := 0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("rewind") and rewind_buffer.size() < 0:
		start_rewind()

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

	record_state(delta)

func record_state(delta: float) -> void:
	rewind_buffer.append({
		"position": global_position,
		"velocity": velocity,
		"flip": animated_sprite.flip_h,
	})

	# Keep only last 4 seconds worth of data
	var max_frames := int(REWIND_DURATION / delta)
	if rewind_buffer.size() > max_frames:
		rewind_buffer.pop_front()

func start_rewind() -> void:
	is_rewinding = true
	rewind_index = rewind_buffer.size() - 1

func rewind_step() -> void:
	if rewind_index < 0:
		stop_rewind()
		return

	var state = rewind_buffer[rewind_index]
	global_position = state.position
	velocity = state.velocity
	animated_sprite.flip_h = state.flip

	rewind_index -= 1

func stop_rewind() -> void:
	is_rewinding = false
	rewind_buffer.clear()
