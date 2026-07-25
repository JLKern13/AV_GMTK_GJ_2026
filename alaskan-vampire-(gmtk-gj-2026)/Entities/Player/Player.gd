class_name Player
extends BaseEntity

#signal blood_gained(amount: int)
signal blood_changed(current_blood: float, max_blood: float)
#signal player_caught

@export var max_blood: float = 200.0
@export var current_blood: float = 100.0
@export var blood_drain_rate: float = 2.0 # Drains 2 blood per second

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var bat_sfx_player: AudioStreamPlayer2D = $BatSFXPlayer

var is_feeding: bool = false
var is_damaged: bool = false

func _ready() -> void:
	is_in_shadow = true

func _process(delta: float) -> void:
	# Continuous blood drain over time
	if current_blood > 0:
		current_blood -= blood_drain_rate * delta
		current_blood = max(current_blood, 0.0)
		blood_changed.emit(current_blood, max_blood)
		
		if current_blood <= 0:
			on_starved()

func add_blood(amount: float) -> void:
	current_blood = min(current_blood + amount, max_blood)
	blood_changed.emit(current_blood, max_blood)

func on_starved() -> void:
	print("Vampy starved! Game Over.")
	# Handle death/game over transition here

func _physics_process(_delta: float) -> void:
	# Block movement if currently feeding or taking damage
	if is_feeding or is_damaged:
		return
		
	handle_movement_input()
	handle_feeding_input()

func handle_movement_input() -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Pass velocity calculation back to BaseEntity
	move_entity(direction)
	
	# Update sprite animations & flipping
	if direction != Vector2.ZERO:
		animated_sprite.play("Walking")
		if direction.x < 0:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
	else:
		animated_sprite.play("Idle")

func handle_feeding_input() -> void:
	# Press "Space" or "E" (ui_accept) to attempt feeding
	if Input.is_action_just_pressed("ui_accept"):
		try_feed()

func try_feed() -> void:
	var overlapping_areas = attack_area.get_overlapping_areas()
	
	for area in overlapping_areas:
		var target_npc = area.get_parent()
		
		# Check if target is a valid NPC and NOT currently in an alert state
		if target_npc is BaseNPC and not target_npc.is_alert:
			start_feeding(target_npc)
			break

func start_feeding(target_npc: BaseNPC) -> void:
	if not is_instance_valid(target_npc):
		return

	is_feeding = true
	velocity = Vector2.ZERO
	animated_sprite.play("Feeding")
	bat_sfx_player.play()
	
	target_npc.on_being_eaten()	
	await get_tree().create_timer(target_npc.drain_duration).timeout
	
	# RACE CONDITION FIX: Verify target_npc wasn't freed by dawn despawning during the await!
	if is_feeding and is_instance_valid(target_npc):
		add_blood(target_npc.blood_value)
		target_npc.queue_free()
		
	# Always reset state & animation cleanly
	is_feeding = false
	if animated_sprite and animated_sprite.animation == "Feeding":
		bat_sfx_player.stop()
		animated_sprite.play("Idle")

func cancel_feeding() -> void:
	is_feeding = false
	if animated_sprite and animated_sprite.animation == "Feeding":
		animated_sprite.play("Idle")
		bat_sfx_player.stop()

func take_damage(_damage_time_loss: int) -> void:
	if is_damaged:
		return
	is_damaged = true
	is_feeding = false # Interrupt feeding if shot/hit
	animated_sprite.play("Damaged")
	
	# Knock off blood/time budget here
	await get_tree().create_timer(0.5).timeout
	is_damaged = false

func show_coffin_death() -> void:
	# Disable movement & input
	is_feeding = true 
	velocity = Vector2.ZERO
	animated_sprite.play("Dead")
