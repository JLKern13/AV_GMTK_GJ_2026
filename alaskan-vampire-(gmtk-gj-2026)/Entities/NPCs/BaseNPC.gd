class_name BaseNPC
extends BaseEntity

enum State { IDLE, WANDER, PANIC, ALERT, BEING_EATEN }
var current_state: State = State.IDLE

@export var blood_value: int = 20
@export var drain_duration: float = 3.0
@export var panic_speed: float = 80.0
@export var normal_speed: float = 40.0
@export var panic_screams: Array[AudioStream] = []
@export var panic_spread_radius: float = 140.0 # Distance panic/screams travel

var is_alert: bool = false
var target_player: Player = null

# Wander logic variables
var wander_direction: Vector2 = Vector2.ZERO
var state_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $VisionPivot/VisionCone
@onready var vision_pivot: Node2D = $VisionPivot 
@onready var scream_player: AudioStreamPlayer2D = $SFXPlayer
@onready var obstacle_ray: RayCast2D = $VisionPivot/RayCast2D

func _ready() -> void:
	add_to_group("npcs")
	move_speed = normal_speed
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	
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
			# Bounce wander_direction cleanly if hitting obstacles
			wander_direction = get_bounced_direction(wander_direction)
			velocity = wander_direction * normal_speed
			
			animated_sprite.play("Walking")
			animated_sprite.flip_h = wander_direction.x >= 0
			move_and_slide()
			
		State.PANIC:
			animated_sprite.play("Panicking")
			if target_player:
				var flee_direction = (global_position - target_player.global_position).normalized()
				# Bounce flee_direction so panicking NPCs don't run into walls
				flee_direction = get_bounced_direction(flee_direction)
				
				velocity = flee_direction * panic_speed
				animated_sprite.flip_h = flee_direction.x >= 0
				move_and_slide()
				
		State.BEING_EATEN:
			velocity = Vector2.ZERO

	# Smoothly update vision cone rotation ONLY when actively moving!
	update_vision_cone_rotation(delta)

# --- DRY HELPER FUNCTION FOR WALL BOUNCING ---
func get_bounced_direction(current_dir: Vector2) -> Vector2:
	if obstacle_ray.is_colliding() or is_on_wall():
		var wall_normal = Vector2.ZERO
		if obstacle_ray.is_colliding():
			wall_normal = obstacle_ray.get_collision_normal()
		elif is_on_wall():
			wall_normal = get_wall_normal()
			
		if wall_normal != Vector2.ZERO:
			return current_dir.bounce(wall_normal).normalized()
			
	return current_dir

func update_vision_cone_rotation(delta: float) -> void:
	if velocity.length() > 10.0:
		var target_angle = velocity.angle()
		vision_pivot.rotation = lerp_angle(vision_pivot.rotation, target_angle, 12.0 * delta)

func pick_new_wander_state() -> void:
	if randf() > 0.4:
		current_state = State.WANDER
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		state_timer = randf_range(2.0, 4.0)
	else:
		current_state = State.IDLE
		state_timer = randf_range(1.0, 3.0)

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		if not body.is_in_shadow:
			trigger_panic(body)

func _on_detection_body_exited(body: Node2D) -> void:
	if body is Player and target_player == body:
		if current_state == State.PANIC:
			await get_tree().create_timer(randf_range(2.5,4.5)).timeout
			if current_state == State.PANIC:
				pick_new_wander_state()
				target_player = null

func trigger_panic(player_node: Player) -> void:
	if current_state == State.BEING_EATEN:
		return
		
	var was_panicking: bool = (current_state == State.PANIC)
	
	current_state = State.PANIC
	target_player = player_node

	# Only play scream and spread panic ONCE when initially entering panic!
	if not was_panicking:
		play_random_scream()
		spread_panic(player_node)

func spread_panic(player_node: Player) -> void:
	if not player_node:
		return
		
	# Find all active NPCs on the map
	var all_npcs = get_tree().get_nodes_in_group("npcs")
	for npc in all_npcs:
		if npc == self or not is_instance_valid(npc):
			continue
			
		var dist = global_position.distance_to(npc.global_position)
		if dist <= panic_spread_radius:
			# If it's a cop, tip them off to Vampy's location!
			if npc is Police:
				if npc.current_state != State.ALERT:
					npc.trigger_alert(player_node)
			# If it's another civilian, pass the panic forward!
			elif npc is BaseNPC:
				if npc.current_state != State.PANIC:
					npc.trigger_panic(player_node)

func play_random_scream() -> void:
	if panic_screams.is_empty():
		return
		
	var random_scream = panic_screams.pick_random()
	scream_player.stream = random_scream
	scream_player.pitch_scale = randf_range(0.9, 1.1)
	scream_player.play()

func on_being_eaten() -> void:
	current_state = State.BEING_EATEN
	velocity = Vector2.ZERO
	animated_sprite.visible = false
