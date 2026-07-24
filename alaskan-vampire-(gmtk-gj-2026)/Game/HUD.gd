class_name HUD
extends CanvasLayer

@onready var day_label: Label = $Control/TopLeftContainer/VBoxContainer/DayLabel
@onready var time_label: Label = $Control/TopRightContainer/TimeLabel
@onready var blood_sprite: Sprite2D = $Control/TopLeftContainer/VBoxContainer/BloodBar

# Assuming the top row of the blood sheet has 8 frames of draining blood
const MAX_BLOOD_FRAMES: int = 24 

func update_blood_display(current_blood: float, max_blood: float) -> void:
	# Calculate blood percentage (0.0 to 1.0)
	var blood_pct: float = clamp(current_blood / max_blood, 0.0, 1.0)
	
	# Map percentage to the sprite frame (Full = Frame 0, Empty = Frame 7)
	var frame_index: int = int((1.0 - blood_pct) * MAX_BLOOD_FRAMES)
	blood_sprite.frame = clamp(frame_index, 0, MAX_BLOOD_FRAMES)

func update_day_display(current_day: int, total_days: int = 30) -> void:
	day_label.text = "DAY %02d / %02d" % [current_day, total_days]

func update_time_display(seconds_remaining: float) -> void:
	var minutes: int = int(seconds_remaining) / 60
	var seconds: int = int(seconds_remaining) % 60
	time_label.text = "DAWN IN: %02d:%02d" % [minutes, seconds]
