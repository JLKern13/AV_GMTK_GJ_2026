class_name BaseNPC
extends BaseEntity

# Simple State Machine
enum State { IDLE, WANDER, PANIC, ALERT, BEING_EATEN }
var current_state: State = State.IDLE

@export var blood_value: int = 20
@export var drain_duration: float = 3.0
@export var panic_speed: float = 220.0
@export var normal_speed: float = 80.0

var is_alert: bool = false
var target_player: Player = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

func _ready() -> void:
	move_speed = normal_speed
	# Connect detection signals
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			animated_sprite.play("idle")
			
		State.WANDER:
			animated_sprite.play("moving")
			move_entity(velocity.normalized())
			
		State.PANIC:
			animated_sprite.play("moving")
			if target_player:
				# Run directly AWAY from player
				var flee_direction = (global_position - target_player.global_position).normalized()
				velocity = flee_direction * panic_speed
				move_entity(flee_direction)
				
		State.ALERT:
			# Base cops/enemies will override this to chase/attack
			pass
			
		State.BEING_EATEN:
			velocity = Vector2.ZERO

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		# Only trigger panic/alert if the player is NOT hidden in shadows
		if not body.is_in_shadow:
			trigger_panic(body)

func _on_detection_body_exited(body: Node2D) -> void:
	if body is Player and target_player == body:
		# Player escaped line of sight
		if current_state == State.PANIC:
			# Keep fleeing for a second, then calm down or wander
			await get_tree().create_timer(2.0).timeout
			if current_state == State.PANIC:
				current_state = State.IDLE
				target_player = null

func trigger_panic(player_node: Player) -> void:
	if current_state == State.BEING_EATEN:
		return
		
	current_state = State.PANIC
	target_player = player_node
	move_speed = panic_speed

func on_being_eaten() -> void:
	current_state = State.BEING_EATEN
	velocity = Vector2.ZERO
	# Hide NPC sprite or pause animation while dust cloud plays over them
	animated_sprite.visible = false
