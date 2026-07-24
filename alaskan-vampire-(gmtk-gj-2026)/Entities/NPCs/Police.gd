class_name Police
extends BaseNPC

signal player_caught_by_police

@export var chase_speed: float = 140.0
# CatchArea is now on the root node, not inside VisionPivot!
@onready var catch_area: Area2D = $CatchArea
@onready var flashlight: PointLight2D = $VisionPivot/Flashlight
@onready var notifier: VisibleOnScreenNotifier2D = $VisionPivot/Flashlight/VisibleOnScreenNotifier2D

func _ready() -> void:
	super._ready()
	add_to_group("police") # Added to police group
	blood_value = 35 
	drain_duration = 4.5 
	
	notifier.screen_entered.connect(func(): flashlight.enabled = true)
	notifier.screen_exited.connect(func(): flashlight.enabled = false)
	flashlight.enabled = notifier.is_on_screen()
	
	catch_area.body_entered.connect(_on_catch_body_entered)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if current_state == State.ALERT and target_player:
		animated_sprite.play("Walking")
		
		var chase_direction = (target_player.global_position - global_position).normalized()
		velocity = chase_direction * chase_speed
		
		if chase_direction.x < 0:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
			
		move_and_slide()

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

func alert_to_location(_spot_position: Vector2, player_ref: Player) -> void:
	if current_state != State.BEING_EATEN:
		trigger_alert(player_ref)

func _on_catch_body_entered(body: Node2D) -> void:
	if body is Player:
		if current_state == State.ALERT:
			print("Busted! Cop caught Vampy!")
			player_caught_by_police.emit()
			
			# FAILSAFE: Direct call to AlaskaTown game over sequence!
			var main_scene = get_tree().current_scene
			if main_scene.has_method("trigger_game_over"):
				main_scene.trigger_game_over("BUSTED BY THE POLICE!")
		else:
			# If player bumps into cop body in darkness while wandering, alert him!
			trigger_alert(body)
