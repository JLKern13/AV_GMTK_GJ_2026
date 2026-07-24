class_name HUD
extends CanvasLayer

@onready var day_label: Label = $Control/TopLeftContainer/VBoxContainer/DayLabel
@onready var blood_sprite: Sprite2D = $Control/TopLeftContainer/VBoxContainer/BloodBar
@onready var reserve_label: Label = $Control/TopRightContainer/VBoxContainer/ReserveLabel
@onready var time_label: Label = $Control/TopRightContainer/VBoxContainer/TimeLabel

const TOTAL_FRAMES: int = 23 # 24 frames total (0 to 23)

func update_blood_display(current_blood: float, max_blood: float) -> void:
	# 200 = Full Red (Frame 0)
	# 100 = Empty Red / Full Grey (Frame 11)
	# 0   = Fully Destroyed / Death (Frame 23)
	var blood_pct: float = clamp(current_blood / max_blood, 0.0, 1.0)
	var frame_index: int = int((1.0 - blood_pct) * TOTAL_FRAMES)
	blood_sprite.frame = clamp(frame_index, 0, TOTAL_FRAMES)

func update_day_display(current_day: int, total_days: int = 30) -> void:
	day_label.text = "DAY %02d / %02d" % [current_day, total_days]

func update_reserve_display(reserve_amount: float) -> void:
	reserve_label.text = "RESERVE: %d PTS" % int(reserve_amount)

func update_time_display(seconds_remaining: float) -> void:
	var minutes: int = int(floor(seconds_remaining) / 60)
	var seconds: int = int(seconds_remaining) % 60
	time_label.text = "DAWN IN: %02d:%02d" % [minutes, seconds]
