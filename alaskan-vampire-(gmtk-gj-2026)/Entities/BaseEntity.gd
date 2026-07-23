class_name BaseEntity
extends CharacterBody2D

@export var move_speed: float = 150.0
var is_in_shadow: bool = false

# Shared function to handle basic 2D movement
func move_entity(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed)
	
	move_and_slide()
