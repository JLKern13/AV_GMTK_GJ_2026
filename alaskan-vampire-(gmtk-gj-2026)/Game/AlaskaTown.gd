extends Node2D

@export var night_duration_seconds: float = 90.0 # 1.5 minutes per night
@export var current_day: int = 1
@export var max_days: int = 10                   # 10 days total (~15 min playthrough)
@export var sleep_cost: float = 70.0             # Daytime sleep cost
@export var win_reserve_target: float = 250.0    # Reserve goal for 10 days

const MAX_BLOOD: float = 230.0
const NEUTRAL_BLOOD: float = 90.0
const RESERVE_THRESHOLD: float = 160.0           # 90 Neutral + 70 Sleep Cost

var reserve_bank: float = 0.0
var time_remaining: float = 0.0
var is_night_active: bool = true
var player_start_position: Vector2 = Vector2.ZERO
var is_game_over_triggered: bool = false

@onready var player: Player = $Player
@onready var hud: HUD = $HUD
@onready var day_splash: DaySplash = $HUD/DaySplash

func _ready() -> void:
	player_start_position = player.global_position
	
	time_remaining = night_duration_seconds
	
	player.max_blood = MAX_BLOOD
	player.current_blood = NEUTRAL_BLOOD
	
	player.blood_changed.connect(hud.update_blood_display)
	hud.update_day_display(current_day, max_days)
	hud.update_reserve_display(reserve_bank)
	hud.update_blood_display(player.current_blood, player.max_blood)

func _process(delta: float) -> void:
	if not is_night_active:
		return
		
	# Starvation Check in Night
	if player.current_blood <= 0.0:
		trigger_game_over("VAMPY STARVED IN THE NIGHT!")
		return
		
	time_remaining -= delta
	time_remaining = max(time_remaining, 0.0)
	hud.update_time_display(time_remaining)
	
	if time_remaining <= 0.0:
		on_dawn_arrived()

func on_dawn_arrived() -> void:
	is_night_active = false
	
	# 1. Daytime Starvation Check
	if player.current_blood < sleep_cost:
		trigger_game_over("VAMPY STARVED DURING THE DAY!")
		return
		
	# 2. Reserve Banking: Anything over 160 blood goes into reserves
	if player.current_blood > RESERVE_THRESHOLD:
		var surplus: float = player.current_blood - RESERVE_THRESHOLD
		reserve_bank += surplus
		player.current_blood = RESERVE_THRESHOLD # Cap at 160 so after sleep cost they start at 90 neutral
		
	# 3. Deduct Daytime Sleep Cost
	player.current_blood -= sleep_cost
	
	hud.update_reserve_display(reserve_bank)
	hud.update_blood_display(player.current_blood, player.max_blood)
	
	# 4. Check Win/Loss or Transition
	if current_day >= max_days:
		if reserve_bank >= win_reserve_target:
			trigger_game_over("VICTORY! SURVIVED THE WINTER!\nReserves: %d PTS" % int(reserve_bank))
		else:
			trigger_game_over("WINTER CAME: STARVED!\nReserves: %d / %d PTS" % [int(reserve_bank), int(win_reserve_target)])
	else:
		day_splash.play_transition("NIGHT %d SURVIVED!\nPREPARE FOR NIGHT %d" % [current_day, current_day + 1])
		await day_splash.splash_finished
		
		current_day += 1
		start_next_day()

func start_next_day() -> void:
	time_remaining = night_duration_seconds
	is_night_active = true
	
	# 1. Reset Vampy to starting spawn position
	player.global_position = player_start_position
	player.velocity = Vector2.ZERO
	
	# 2. Despawn all active NPCs from the previous night
	get_tree().call_group("npcs", "queue_free")
	
	# 3. Re-trigger house spawners for the new day
	# (Calls spawn logic on any spawner nodes in the 'spawners' group)
	get_tree().call_group("spawners", "spawn_for_day", current_day)
	
	# 4. Refresh HUD
	hud.update_day_display(current_day, max_days)
	hud.update_blood_display(player.current_blood, player.max_blood)
	
	print("Night %d Started! Vampy reset to spawn." % current_day)

func trigger_game_over(reason_text: String) -> void:
	if is_game_over_triggered:
		return
		
	is_game_over_triggered = true
	is_night_active = false
	
	var display_title = "GAME OVER\n" + reason_text
	day_splash.play_transition(display_title, true)
