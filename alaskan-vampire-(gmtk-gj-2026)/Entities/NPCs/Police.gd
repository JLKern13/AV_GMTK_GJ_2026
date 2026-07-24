class_name Police
extends BaseNPC

signal player_caught_by_police

@export var chase_speed: float = 95.0       # Slower than before so Vampy can out-sprint/outmaneuver
@export var chase_duration: float = 5.0     # Seconds police will chase before giving up

var chase_timer: float = 0.0

@onready var catch_area: Area2D = $CatchArea
@onready var flashlight: PointLight2D = $VisionPivot/Flashlight
@onready var notifier: VisibleOnScreenNotifier2D = $VisionPivot/Flashlight/VisibleOnScreenNotifier2D

func _ready() -> void:
	super._ready()
	add_to_group("police")
	blood_value = 35 
	drain_duration = 4.5 
	
	notifier.screen_entered.connect(func(): flashlight.enabled = true)
	notifier.screen_exited.connect(func(): flashlight.enabled = false)
	flashlight.enabled = notifier.is_on_screen()
	
	catch_area.body_entered.connect(_on_catch_body_entered)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# CHASE / ALERT behavior with timer
	if current_state == State.ALERT and target_player:
		chase_timer -= delta
		
		# If timer runs out, cop gives up chase and returns to wandering
		if chase_timer <= 0.0:
			give_up_chase()
			return

		animated_sprite.play("Walking")
		
		var chase_direction = (target_player.global_position - global_position).normalized()
		velocity = chase_direction * chase_speed
		
		if chase_direction.x < 0:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
			
		move_and_slide()

# Flashlight detection triggers the chase
func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		trigger_alert(body)

func trigger_panic(player_node: Player) -> void:
	trigger_alert(player_node)

func trigger_alert(player_node: Player) -> void:
	if current_state == State.BEING_EATEN:
		return
		
	current_state = State.ALERT
	is_alert = true
	target_player = player_node
	chase_timer = chase_duration # Reset 5-second chase clock
	
	# If player was caught inside catch_area when beam hit them, bust them immediately
	if catch_area and catch_area.overlaps_body(player_node):
		_catch_player()

func give_up_chase() -> void:
	current_state = State.IDLE
	is_alert = false
	target_player = null
	pick_new_wander_state() # Resets back to routine IDLE / WANDER

func _on_catch_body_entered(body: Node2D) -> void:
	# ONLY catch if cop is in ALERT state. 
	# Bumping into cop in dark shadows does NOT trigger alert or game over!
	if body is Player and current_state == State.ALERT:
		_catch_player()

func _catch_player() -> void:
	print("Busted! Cop caught Vampy!")
	player_caught_by_police.emit()
	
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("trigger_game_over"):
		main_scene.trigger_game_over("BUSTED BY THE POLICE!")
