class_name VictorySplash
extends CanvasLayer

@onready var anim_sprite: AnimatedSprite2D = $Control/AnimatedSprite2D
@onready var status_label: Label = $Control/StatusLabel
@onready var music_player: AudioStreamPlayer2D = $Control/MusicPlayer 
@onready var laugh_sfx_player: AudioStreamPlayer2D = $Control/LaughSFXPlayer # Add your path here

func _ready() -> void:
	visible = false

## Cleanly check the event itself so it only fires exactly ONCE when pressed
#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("ui_home"):
		#play_victory("Test!")

func play_victory(message_text: String) -> void:
	visible = true
	status_label.text = message_text
	
	if music_player and music_player.stream:
		music_player.play()
		
	# 1. Start the looping nap (Do NOT await animation_finished here!)
	anim_sprite.play("VictoryNap")
	
	# 2. Let Vampy sleep for 4 seconds
	await get_tree().create_timer(4.0).timeout
	
	# 3. Wake up and trigger the evil laugh
	anim_sprite.play("Awakening")
	if laugh_sfx_player and laugh_sfx_player.stream:
		laugh_sfx_player.play()
	
	# 4. Wait for the laugh/awakening to finish
	await get_tree().create_timer(1.5).timeout
	
	# 5. Clean up and transition
	visible = false
	music_player.stop()
	
	# Route back to the Title Screen 
	get_tree().change_scene_to_file("res://Game/TitleScreen.tscn")
