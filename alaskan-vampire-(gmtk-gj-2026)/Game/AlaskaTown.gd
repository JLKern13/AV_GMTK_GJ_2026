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
@onready var victory_splash: VictorySplash = $HUD/VictorySplash
@onready var music_player: AudioStreamPlayer2D = $MusicPlayer
@onready var stamina_bar: ProgressBar = $HUD/StaminaBar

func _ready() -> void:
	player_start_position = player.global_position
	
	time_remaining = night_duration_seconds
	
	player.max_blood = MAX_BLOOD
	player.current_blood = NEUTRAL_BLOOD
	if player and stamina_bar:
		player.stamina_updated.connect(_on_player_stamina_updated)
	player.blood_changed.connect(hud.update_blood_display)
	hud.update_day_display(current_day, max_days)
	hud.update_reserve_display(reserve_bank)
	hud.update_blood_display(player.current_blood, player.max_blood)
	music_player.play()

func _process(delta: float) -> void:
	if not is_night_active:
		return
		
	# Starvation Check in Night
	if player.current_blood <= 0.0:
		trigger_game_over("VAMPY STARVED IN THE NIGHT!\nNights Survived: %d\nTotal Banked: %d / %d PTS\nSoul Coins: %d" % [int(current_day-1), int(reserve_bank), int(win_reserve_target), StoreManager.soul_coins])
		return
		
	time_remaining -= delta
	time_remaining = max(time_remaining, 0.0)
	hud.update_time_display(time_remaining)
	
	if time_remaining <= 0.0:
		on_dawn_arrived()

func _on_player_stamina_updated(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current

func on_dawn_arrived() -> void:
	is_night_active = false
	
	if player and player.has_method("cancel_feeding"):
		player.cancel_feeding()
	
	# IMMEDIATELY clear active NPCs when dawn breaks so cops can't catch Vampy during splash!
	get_tree().call_group("npcs", "queue_free")
	
	# 1. Daytime Starvation Check
	if player.current_blood < sleep_cost:
		trigger_game_over("VAMPY STARVED DURING THE DAY!\nNights Survived: %d\nFinal Reserves: %d PTS\nSoul Coins: %d" % [int(current_day - 1), int(reserve_bank), StoreManager.soul_coins])
		return
		
	# 2. Reserve Banking Calculation
	var surplus_banked: float = 0.0
	if player.current_blood > RESERVE_THRESHOLD:
		surplus_banked = player.current_blood - RESERVE_THRESHOLD
		reserve_bank += surplus_banked
		player.current_blood = RESERVE_THRESHOLD # Cap at 160 so Vampy wakes at 90 neutral
		
	# 3. Deduct Daytime Sleep Cost
	player.current_blood -= sleep_cost
	
	hud.update_reserve_display(reserve_bank)
	hud.update_blood_display(player.current_blood, player.max_blood)
	
	# 4. Check Win / Loss / Transition
	if current_day >= max_days:
		if reserve_bank >= win_reserve_target:
			# ROUTE TO VICTORY SCREEN INSTEAD OF GAME OVER
			trigger_victory("SURVIVED THE WINTER!\nNights Survived: %d\nTotal Banked: %d / %d PTS\nSoul Coins: %d" % [int(current_day), int(reserve_bank), int(win_reserve_target), StoreManager.soul_coins])
		else:
			trigger_game_over("WINTER CAME: STARVED!\nNights Survived: %d\nTotal Banked: %d / %d PTS\nSoul Coins: %d" % [int(current_day), int(reserve_bank), int(win_reserve_target), StoreManager.soul_coins])
	else:
		# Detailed Nightly Report Splash
		var splash_text: String = "NIGHT %d SURVIVED!\n\nBanked Tonight: +%d PTS\nTotal Reserves: %d / %d PTS\nSoul Coins: %d\n\nPREPARE FOR NIGHT %d" % [
			current_day,
			int(surplus_banked),
			int(reserve_bank),
			int(win_reserve_target),
			StoreManager.soul_coins,
			current_day + 1
		]
		
		day_splash.play_transition(splash_text)
		await day_splash.splash_finished
		
		current_day += 1
		start_next_day()

func start_next_day() -> void:
	time_remaining = night_duration_seconds
	is_night_active = true
	
	# 1. Reset Vampy to starting spawn position
	player.global_position = player_start_position
	player.velocity = Vector2.ZERO
	music_player.play()

	# 2. Re-trigger house spawners for the new day
	get_tree().call_group("spawners", "spawn_for_day", current_day)
	
	# 3. Refresh HUD
	hud.update_day_display(current_day, max_days)
	hud.update_blood_display(player.current_blood, player.max_blood)
	
	print("Night %d Started! Vampy reset to spawn." % current_day)

# HELPER: Formats police bust screen with stats
func trigger_busted_game_over() -> void:
	var busted_text: String = "BUSTED BY THE POLICE!\nNights Survived: %d\nTotal Banked: %d / %d PTS\nSoul Coins: %d" % [
		int(current_day - 1),
		int(reserve_bank),
		int(win_reserve_target),
		StoreManager.soul_coins
	]
	trigger_game_over(busted_text)

func trigger_game_over(reason_text: String) -> void:
	music_player.stop()
	if is_game_over_triggered:
		return
		
	is_game_over_triggered = true
	is_night_active = false
	
	var display_title = "GAME OVER\n" + reason_text
	day_splash.play_transition(display_title, true)

func trigger_victory(reason_text: String) -> void:
	music_player.stop()
	if is_game_over_triggered:
		return
		
	is_game_over_triggered = true
	is_night_active = false
	
	var display_title = "VICTORY!\n" + reason_text
	victory_splash.play_victory(display_title)
