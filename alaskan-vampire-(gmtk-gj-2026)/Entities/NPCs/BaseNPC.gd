class_name BaseNPC
extends BaseEntity

enum State { IDLE, WANDER, PANIC, ALERT, BEING_EATEN }
var current_state: State = State.IDLE

@export var blood_value: int = 20
@export var drain_duration: float = 3.0
@export var panic_speed: float = 80.0
@export var normal_speed: float = 40.0
@export var panic_screams: Array[AudioStream] = []

var is_alert: bool = false
var target_player: Player = null

# Wander logic variables
var wander_direction: Vector2 = Vector2.ZERO
var state_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $VisionPivot/VisionCone
@onready var vision_pivot: Node2D = $VisionPivot # Ensure your pivot node is named VisionPivot
@onready var scream_player: AudioStreamPlayer2D = $SFXPlayer

func _ready() -> void:
	move_speed = normal_speed
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	
	# Start with a random state on spawn
	pick_new_wander_state()

func _physics_process(delta: float) -> void:
	# Handle state timer for routine wandering/idling
	if current_state == State.IDLE or current_state == State.WANDER:
		state_timer -= delta
		if state_timer <= 0:
			pick_new_wander_state()

	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			animated_sprite.play("Idle")
			
		State.WANDER:
			velocity = wander_direction * normal_speed
			animated_sprite.play("Walking")
			if wander_direction.x < 0:
				animated_sprite.flip_h = false
			else:
				animated_sprite.flip_h = true
			move_and_slide()
			
		State.PANIC:
			animated_sprite.play("Panicking")
			if target_player:
				var flee_direction = (global_position - target_player.global_position).normalized()
				velocity = flee_direction * panic_speed
				if flee_direction.x < 0:
					animated_sprite.flip_h = false
				else:
					animated_sprite.flip_h = true
				move_and_slide()
				
		State.BEING_EATEN:
			velocity = Vector2.ZERO

	# Smoothly update vision cone rotation ONLY when actively moving!
	update_vision_cone_rotation(delta)

func update_vision_cone_rotation(delta: float) -> void:
	if velocity.length() > 10.0:
		var target_angle = velocity.angle()
		
		# UNCOMMENT THE LINE BELOW if your cone was drawn pointing UP in the editor:
		# target_angle += deg_to_rad(90)
		
		vision_pivot.rotation = lerp_angle(vision_pivot.rotation, target_angle, 12.0 * delta)

func pick_new_wander_state() -> void:
	# Randomly choose between IDLE (pause) or WANDER (walk around)
	if randf() > 0.4:
		current_state = State.WANDER
		# Pick a random direction vector
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		state_timer = randf_range(2.0, 4.0) # Walk for 2-4 seconds
	else:
		current_state = State.IDLE
		state_timer = randf_range(1.0, 3.0) # Pause for 1-3 seconds

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		if not body.is_in_shadow:
			trigger_panic(body)

func _on_detection_body_exited(body: Node2D) -> void:
	if body is Player and target_player == body:
		if current_state == State.PANIC:
			await get_tree().create_timer(2.0).timeout
			if current_state == State.PANIC:
				pick_new_wander_state()
				target_player = null

func trigger_panic(player_node: Player) -> void:
	if current_state == State.BEING_EATEN:
		return
		
	# ONLY trigger the scream if they were NOT already panicking!
	if current_state != State.PANIC:
		play_random_scream()

	current_state = State.PANIC
	target_player = player_node

func play_random_scream() -> void:
	if panic_screams.is_empty():
		return
		
	# Pick a random audio clip from your fiancée's recordings!
	var random_scream = panic_screams.pick_random()
	
	scream_player.stream = random_scream
	# Slightly adjust pitch each time for extra natural variation (e.g., 0.9x to 1.1x speed/pitch)
	scream_player.pitch_scale = randf_range(0.9, 1.1)
	scream_player.play()

func on_being_eaten() -> void:
	current_state = State.BEING_EATEN
	velocity = Vector2.ZERO
	animated_sprite.visible = false
