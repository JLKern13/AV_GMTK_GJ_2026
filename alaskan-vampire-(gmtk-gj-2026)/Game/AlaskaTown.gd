extends Node2D

@export var night_duration_seconds: float = 120.0 
@export var current_day: int = 1
@export var max_days: int = 30
@export var sleep_cost: float = 50.0 

var reserve_bank: float = 0.0
var time_remaining: float = 0.0
var is_night_active: bool = true

@onready var player: Player = $Player
@onready var hud: HUD = $HUD

func _ready() -> void:
	time_remaining = night_duration_seconds
	
	# Configure Player 0-200 Scale & Neutral Start
	player.max_blood = 200.0
	player.current_blood = 100.0 # Neutral start (Frame 11/12)
	
	# Connect HUD
	player.blood_changed.connect(hud.update_blood_display)
	hud.update_day_display(current_day, max_days)
	hud.update_reserve_display(reserve_bank)

func _process(delta: float) -> void:
	if not is_night_active:
		return
		
	time_remaining -= delta
	time_remaining = max(time_remaining, 0.0)
	hud.update_time_display(time_remaining)
	
	if time_remaining <= 0.0:
		on_dawn_arrived()

func on_dawn_arrived() -> void:
	is_night_active = false
	
	# Check if player has enough blood to pay daytime sleep cost
	if player.current_blood < sleep_cost:
		print("GAME OVER: Vampy froze/starved during the day!")
		# Trigger Game Over sequence
		return
		
	# Deduct daytime sleep cost
	player.current_blood -= sleep_cost
	
	# Any blood remaining ABOVE the 100 neutral mark gets banked into the 30-Day Reserve Goal
	if player.current_blood > 100.0:
		var surplus: float = player.current_blood - 100.0
		reserve_bank += surplus
		# Reset current blood back down to neutral cap for reserve calculation math
		player.current_blood = 100.0
	
	hud.update_reserve_display(reserve_bank)
	print("Night Survived! Reserves Banked: %.1f | Starting next night with: %.1f blood" % [reserve_bank, player.current_blood])
	
	if current_day >= max_days:
		evaluate_win_condition()
	else:
		current_day += 1
		start_next_day()

func start_next_day() -> void:
	time_remaining = night_duration_seconds
	is_night_active = true
	
	hud.update_day_display(current_day, max_days)
	hud.update_blood_display(player.current_blood, player.max_blood)
	
	print("Starting Night %d!" % current_day)

func evaluate_win_condition() -> void:
	if reserve_bank >= 750:
		print("VICTORY! Stored %.1f blood and survived the winter!" % reserve_bank)
	else:
		print("GAME OVER: Only banked %.1f blood (Needed 750)." % reserve_bank)
