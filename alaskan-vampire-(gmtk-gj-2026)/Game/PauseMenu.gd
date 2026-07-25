extends CanvasLayer

func _ready() -> void:
	# Make sure the menu is hidden when the game starts
	hide()

func _input(event: InputEvent) -> void:
	# ui_cancel handles both ESC and controller Start/Menu buttons by default
	if event.is_action_pressed("ui_cancel"):
		# Toggle the paused state of the entire game tree
		get_tree().paused = not get_tree().paused
		
		# Show or hide the dark overlay and text based on the pause state
		visible = get_tree().paused
