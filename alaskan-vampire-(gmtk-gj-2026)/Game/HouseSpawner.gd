class_name HouseSpawner
extends Marker2D

@export var civilian_scene: PackedScene
@export var police_scene: PackedScene

# How many seconds between spawns at this house
@export var spawn_interval: float = 12.0 
var spawn_timer: float = 0.0

func _process(delta: float) -> void:
	# Only spawn during active gameplay nights
	var town = get_tree().current_scene
	if not town or not town.is_night_active:
		return
		
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(spawn_interval * 0.8, spawn_interval * 1.2)
		spawn_human(town.current_day)

func spawn_human(current_day: int) -> void:
	if not civilian_scene or not police_scene:
		return

	# Calculate police spawn chance based on Day 1 to Day 30
	# Day 1 = 5% Cops, Day 30 = 90% Cops
	var day_progress: float = clamp(float(current_day - 1) / 29.0, 0.0, 1.0)
	var cop_chance: float = lerp(0.05, 0.90, day_progress)

	var entity_to_spawn: BaseNPC
	if randf() < cop_chance:
		entity_to_spawn = police_scene.instantiate()
	else:
		entity_to_spawn = civilian_scene.instantiate()

	# Spawn at door position
	entity_to_spawn.global_position = global_position
	
	# Add to main scene tree
	get_parent().add_child(entity_to_spawn)
