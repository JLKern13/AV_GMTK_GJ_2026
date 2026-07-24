class_name Police
extends BaseNPC

signal player_caught_by_police

@export var chase_speed: float = 140.0
@onready var flashlight: PointLight2D = $VisionPivot/Flashlight
@onready var catch_area: Area2D = $VisionPivot/CatchArea
@onready var notifier: VisibleOnScreenNotifier2D = $VisionPivot/Flashlight/VisibleOnScreenNotifier2D

func _ready() -> void:
	super._ready()
	blood_value = 35 # High reward if snuck up on!
	drain_duration = 4.5 # Takes longer to eat
	notifier.screen_entered.connect(func(): flashlight.enabled = true)
	notifier.screen_exited.connect(func(): flashlight.enabled = false)
	flashlight.enabled = notifier.is_on_screen()
	catch_area.body_entered.connect(_on_catch_body_entered)

func _physics_process(delta: float) -> void:
	# Keep BaseNPC logic for IDLE, WANDER, BEING_EATEN
	super._physics_process(delta)
	
	# Override CHASE / ALERT behavior
	if current_state == State.ALERT and target_player:
		animated_sprite.play("Walking") # Matches BaseNPC animation naming!
		
		var chase_direction = (target_player.global_position - global_position).normalized()
		velocity = chase_direction * chase_speed
		
		if chase_direction.x < 0:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
			
		move_and_slide()

# OVERRIDE: Cops see the player in their flashlight EVEN IN THE DARK!
func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		trigger_alert(body)

# OVERRIDE: Redirect panic triggers (e.g. from BaseNPC calls) directly to ALERT
func trigger_panic(player_node: Player) -> void:
	trigger_alert(player_node)

func trigger_alert(player_node: Player) -> void:
	if current_state == State.BEING_EATEN:
		return
		
	current_state = State.ALERT
	is_alert = true
	target_player = player_node

func alert_to_location(spot_position: Vector2, player_ref: Player) -> void:
	if current_state != State.BEING_EATEN:
		trigger_alert(player_ref)

func _on_catch_body_entered(body: Node2D) -> void:
	if body is Player:
		if current_state == State.ALERT:
			print("Busted! Cop caught Vampy!")
			player_caught_by_police.emit()
		else:
			# If player bumps into flashlight/catch area in darkness while cop wanders, alert him immediately!
			trigger_alert(body)
