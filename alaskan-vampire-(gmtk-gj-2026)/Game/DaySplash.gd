class_name DaySplash
extends CanvasLayer

signal splash_finished

@onready var anim_sprite: AnimatedSprite2D = $Control/AnimatedSprite2D
@onready var status_label: Label = $Control/StatusLabel
@onready var rooster_audio: AudioStreamPlayer2D = $Control/RoosterAudio

func _ready() -> void:
	visible = false

func play_transition(message_text: String, is_game_over: bool = false) -> void:
	visible = true
	status_label.text = message_text
	
	# Play rooster sound effect
	if rooster_audio and rooster_audio.stream:
		rooster_audio.play()
		
	# Play the sunrise sprite animation created by your daughter
	anim_sprite.play("Sunrise")
	await anim_sprite.animation_finished
	
	# Brief pause so player can read the text
	await get_tree().create_timer(1.5).timeout
	
	visible = false
	splash_finished.emit()
	
	if is_game_over:
		# Return back to the Title Screen after Game Over
		get_tree().change_scene_to_file("res://Game/TitleScreen.tscn")
