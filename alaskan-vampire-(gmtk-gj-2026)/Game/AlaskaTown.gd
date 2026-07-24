extends Node2D

@export var night_duration_seconds: float = 90.0 
@export var current_day: int = 1
@export var max_days: int = 30
@export var sleep_cost: float = 50.0 

var reserve_bank: float = 0.0
var time_remaining: float = 0.0
var is_night_active: bool = true

@onready var player: Player = $Player
@onready var hud: HUD = $HUD
@onready var start_point: Marker2D = $StartingPoint
@onready var day_splash: DaySplash = $HUD/DaySplash

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
		
	# 1. Nighttime Starvation Check
	if player.current_blood <= 0.0:
		trigger_game_over("VAMPY STARVED IN THE NIGHT!")
		return
		
	# Tick down the night timer
	time_remaining -= delta
	time_remaining = max(time_remaining, 0.0)
	hud.update_time_display(time_remaining)
	
	if time_remaining <= 0.0:
		on_dawn_arrived()

func on_dawn_arrived() -> void:
	is_night_active = false
	
	# 2. Daytime Starvation Check
	if player.current_blood < sleep_cost:
		trigger_game_over("VAMPY STARVED DURING THE DAY!")
		return
		
	# Process Reserves and Day Transitions (See Section 2 below)
	process_dawn_reserves()

func start_next_day() -> void:
	# 1. Wipe all active NPCs off the map
	get_tree().call_group("npcs", "queue_free")
	
	# 2. Reset Player Position to StartingPoint Marker2D
	if start_point:
		player.global_position = start_point.global_position
		player.velocity = Vector2.ZERO
		
	# 3. Reset night clock & game state
	time_remaining = night_duration_seconds
	is_night_active = true
	
	# 4. Update UI
	hud.update_day_display(current_day, max_days)
	hud.update_blood_display(player.current_blood, player.max_blood)
	
	# (Optional) Show your Day Summary Splash overlay here before starting!
	print("Starting Night %d at Starting Point!" % current_day)

func evaluate_win_condition() -> void:
	if reserve_bank >= 750:
		print("VICTORY! Stored %.1f blood and survived the winter!" % reserve_bank)
	else:
		print("GAME OVER: Only banked %.1f blood (Needed 750)." % reserve_bank)

func on_player_caught() -> void:
	is_night_active = false
	player.show_coffin_death()
	
	# Wait 2.5 seconds with the coffin on screen
	await get_tree().create_timer(2.5).timeout
	
	trigger_game_over("BUSTED BY THE POLICE!")

func trigger_game_over(reason_text: String) -> void:
	is_night_active = false
	var display_title = "GAME OVER\n" + reason_text
	
	# Calls DaySplash, which waits for animation then reloads TitleScreen!
	day_splash.play_transition(display_title, true)

func process_dawn_reserves() -> void:
	# 1. Bank any blood above neutral (100.0) into reserves
	if player.current_blood > 100.0:
		var surplus: float = player.current_blood - 100.0
		reserve_bank += surplus
		player.current_blood = 100.0 # Cap starting health back to neutral
	
	# 2. Deduct daytime sleep cost for next night's starting health
	player.current_blood = max(0.0, player.current_blood - sleep_cost)
	
	# 3. Refresh HUD displays
	hud.update_reserve_display(reserve_bank)
	hud.update_blood_display(player.current_blood, player.max_blood)
	
	print("Reserves Total: %.1f | Next Night Start Blood: %.1f" % [reserve_bank, player.current_blood])
	
	# 4. Check Win / Transition conditions
	if current_day >= max_days:
		if reserve_bank >= 750:
			trigger_game_over("VICTORY! SURVIVED THE WINTER!\nReserves: %d" % int(reserve_bank))
		else:
			trigger_game_over("WINTER CAME: STARVED!\nReserves: %d / 750" % int(reserve_bank))
	else:
		day_splash.play_transition("NIGHT %d SURVIVED!\nPREPARE FOR NIGHT %d" % [current_day, current_day + 1])
		await day_splash.splash_finished
		
		current_day += 1
		start_next_day()
