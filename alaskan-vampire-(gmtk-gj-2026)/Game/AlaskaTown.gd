extends Node2D

@export var night_duration_seconds: float = 120.0 # 2 minutes per night
@export var current_day: int = 1
@export var max_days: int = 30

var time_remaining: float = 0.0
var is_night_active: bool = true

@onready var player: Player = $Player
@onready var hud: HUD = $HUD

func _ready() -> void:
	time_remaining = night_duration_seconds
	
	# Connect HUD signals
	player.blood_changed.connect(hud.update_blood_display)
	hud.update_day_display(current_day, max_days)

func _process(delta: float) -> void:
	if not is_night_active:
		return
		
	# Tick down the night timer
	time_remaining -= delta
	time_remaining = max(time_remaining, 0.0)
	hud.update_time_display(time_remaining)
	
	# Check for Dawn (Player survived the night!)
	if time_remaining <= 0.0:
		on_dawn_arrived()

func on_dawn_arrived() -> void:
	is_night_active = false
	print("Dawn has broken! Day %d survived!" % current_day)
	
	# Check if Vampy has enough blood stored to survive or move to next day
	if current_day < max_days:
		current_day += 1
		# Trigger end-of-day sequence or reset scene for next night
	else:
		print("YOU SURVIVED THE ALASKAN WINTER! WIN GAME!")
