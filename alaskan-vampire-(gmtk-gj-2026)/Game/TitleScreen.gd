class_name TitleScreen
extends Control

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var start_label: Label = $StartPromptLabel

var is_starting: bool = false

func _ready() -> void:
	# Loop the sleeping snow animation (Frames 0 to 2)
	anim_sprite.play("Idle")

func _unhandled_input(event: InputEvent) -> void:
	if is_starting:
		return
		
	if event.is_action_pressed("ui_accept") or event is InputEventMouseButton:
		start_game()

func start_game() -> void:
	is_starting = true
	start_label.visible = false
	
	# Play the wake-up animation (vampy opens eyes, snow falls off)
	anim_sprite.play("GameStart")
	
	# Wait for animation to finish before loading AlaskaTown
	await anim_sprite.animation_finished
	get_tree().change_scene_to_file("res://Game/AlaskaTown.tscn")
