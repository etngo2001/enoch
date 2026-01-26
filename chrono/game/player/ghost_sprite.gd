extends Node2D

# How long the ghost stays visible before disappearing
@export var lifetime := 0.4

func _ready():
	# Make the ghost semi-transparent
	modulate.a = 0.5

	# Automatically remove the ghost after its lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()
