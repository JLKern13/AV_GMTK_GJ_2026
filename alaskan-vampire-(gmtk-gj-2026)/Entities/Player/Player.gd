class_name Player
extends BaseEntity

signal blood_gained(amount: int)
signal player_caught

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

var is_feeding: bool = false
var is_damaged: bool = false

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
		if direction.x != 0:
			animated_sprite.flip_h = (direction.x < 0)
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
	is_feeding = true
	velocity = Vector2.ZERO
	
	# Play dust cloud animation
	animated_sprite.play("Feeding")
	
	# Tell the NPC to lock up / enter "being fed on" state
	target_npc.on_being_eaten()
	
	# Wait for NPC's required drain duration (e.g., 3.0s for civilian, 4.5s for police)
	await get_tree().create_timer(target_npc.drain_duration).timeout
	
	# Check if player was interrupted (e.g., caught by a cop during the timer)
	if is_feeding:
		blood_gained.emit(target_npc.blood_value)
		target_npc.queue_free() # Remove NPC from scene
		is_feeding = false
		animated_sprite.play("Idle")

func take_damage(_damage_time_loss: int) -> void:
	if is_damaged:
		return
		
	is_damaged = true
	is_feeding = false # Interrupt feeding if shot/hit
	animated_sprite.play("Damaged")
	
	# Knock off blood/time budget here
	
	await get_tree().create_timer(0.5).timeout
	is_damaged = false
