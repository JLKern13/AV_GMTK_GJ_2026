class_name Player
extends BaseEntity

#signal blood_gained(amount: int)
signal blood_changed(current_blood: float, max_blood: float)
signal stamina_updated(current_stamina: float, max_stamina: float)
#signal player_caught

@export_group("Blood and Blood Drain")
@export var max_blood: float = 200.0
@export var current_blood: float = 100.0
@export var blood_drain_rate: float = 2.0 # Drains 2 blood per second
@export_group("Movement & Stamina")
@export var walk_speed: float = 70.0       # Slower default speed
@export var run_speed: float = 135.0       # Fast sprint speed
@export var acceleration: float = 800.0    # How fast he reaches top speed
@export var friction: float = 1000.0       # How fast he stops
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 35.0 # Drains in ~3 seconds
@export var stamina_regen_rate: float = 20.0 # Regens in ~5 seconds

@export_group("Stamina Penalties")
@export var exhaustion_duration: float = 2.5            # Seconds before regen starts
@export var recovery_threshold_percent: float = 0.25    # Needs 25% stamina to sprint again

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var bat_sfx_player: AudioStreamPlayer2D = $BatSFXPlayer

var is_feeding: bool = false
var is_damaged: bool = false
var current_stamina: float = max_stamina
var is_exhausted: bool = false
var exhaustion_timer: float = 0.0

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

func _physics_process(delta: float) -> void:
	if is_feeding or is_damaged:
		return
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 1. Handle Exhaustion Timer & Recovery
	if exhaustion_timer > 0.0:
		exhaustion_timer -= delta
	else:
		# If the timer is done, check if we've regenerated enough to lift the exhaustion penalty
		if is_exhausted and current_stamina >= (max_stamina * recovery_threshold_percent):
			is_exhausted = false

	# 2. Handle Stamina Drain & Regen
	var is_trying_to_run = Input.is_action_pressed("run")
	var is_running = false
	
	# Only allow running if moving, NOT exhausted, and pressing run
	if is_trying_to_run and not is_exhausted and input_dir != Vector2.ZERO:
		is_running = true
		current_stamina -= stamina_drain_rate * delta
		
		# If we hit absolute 0, trigger the penalty!
		if current_stamina <= 0.0:
			current_stamina = 0.0
			is_exhausted = true
			exhaustion_timer = exhaustion_duration
	else:
		# Only allow regeneration if the exhaustion timer has finished ticking down
		if exhaustion_timer <= 0.0:
			current_stamina += stamina_regen_rate * delta
			
	# Clamp stamina so it stays between 0 and max
	current_stamina = clamp(current_stamina, 0.0, max_stamina)
	
	# Broadcast the current stamina to your HUD
	stamina_updated.emit(current_stamina, max_stamina)
	
	# 2. Calculate Target Speed
	var target_speed = run_speed if is_running else walk_speed
	var target_velocity = input_dir * target_speed
	
	# 3. Apply Acceleration and Friction
	if input_dir != Vector2.ZERO:
		# Accelerate towards target velocity
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		
		# Handle sprite flipping/animations
		animated_sprite.play("Walking")
		animated_sprite.flip_h = velocity.x > 0
	else:
		# Decelerate to a stop
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if not is_feeding: # Ensure we don't overwrite feeding anim
			animated_sprite.play("Idle")
	
	handle_feeding_input()
	move_and_slide()

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
