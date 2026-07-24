class_name HUD
extends CanvasLayer

@onready var day_label: Label = $Control/TopLeftContainer/VBoxContainer/DayLabel
@onready var blood_sprite: Sprite2D = $Control/TopLeftContainer/VBoxContainer/BloodBar
@onready var reserve_label: Label = $Control/TopRightContainer/VBoxContainer/ReserveLabel
@onready var time_label: Label = $Control/TopRightContainer/VBoxContainer/TimeLabel

const RED_FRAMES: int = 15   # Frames 0 to 14 (Range: 230 down to 90)
const GREY_FRAMES: int = 8   # Frames 15 to 22 (Range: 90 down to 0)

func update_blood_display(current_blood: float, _max_blood: float = 230.0) -> void:
	var frame_index: int = 0
	
	if current_blood >= 90.0:
		# Red Phase (230 -> 90 mapped to frames 0..14)
		var red_pct: float = clamp((current_blood - 90.0) / 140.0, 0.0, 1.0)
		frame_index = int((1.0 - red_pct) * (RED_FRAMES - 1))
	else:
		# Grey Phase (90 -> 0 mapped to frames 15..22)
		var grey_pct: float = clamp(current_blood / 90.0, 0.0, 1.0)
		frame_index = 15 + int((1.0 - grey_pct) * (GREY_FRAMES - 1))
		
	blood_sprite.frame = clamp(frame_index, 0, 22)

func update_day_display(current_day: int, total_days: int = 10) -> void:
	day_label.text = "DAY %02d / %02d" % [current_day, total_days]

func update_reserve_display(reserve_amount: float) -> void:
	reserve_label.text = "RESERVE: %d PTS" % int(reserve_amount)

func update_time_display(seconds_remaining: float) -> void:
	var minutes: int = int(floor(seconds_remaining) / 60)
	var seconds: int = int(seconds_remaining) % 60
	time_label.text = "DAWN IN: %02d:%02d" % [minutes, seconds]
