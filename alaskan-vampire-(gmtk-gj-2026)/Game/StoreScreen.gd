extends Control

@onready var coins_label: Label = $VBoxContainer/CoinsLabel

# The [+] Buttons
@onready var btn_blood: Button = $VBoxContainer/RowBlood/BuyButton
@onready var btn_stamina: Button = $VBoxContainer/RowStamina/BuyButton
@onready var btn_speed: Button = $VBoxContainer/RowSpeed/BuyButton
@onready var btn_detsub: Button = $VBoxContainer/RowDetsub/BuyButton

# Labels that need text updates
@onready var speed_label: Label = $VBoxContainer/RowSpeed/NameLabel
@onready var detsub_label: Label = $VBoxContainer/RowDetsub/NameLabel

func _ready() -> void:
	# Wire up the button clicks
	btn_blood.pressed.connect(_on_buy_blood)
	btn_stamina.pressed.connect(_on_buy_stamina)
	btn_speed.pressed.connect(_on_buy_speed)
	btn_detsub.pressed.connect(_on_buy_detsub)
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	
	# Initial UI refresh
	update_ui()

func update_ui() -> void:
	# Update the main coin counter
	coins_label.text = "----- Total Soul Coins: %d -----" % StoreManager.soul_coins
	
	# Update Blood & Stamina button states (Infinite upgrades, just check cost)
	btn_blood.disabled = StoreManager.soul_coins < 20
	btn_stamina.disabled = StoreManager.soul_coins < 10
	
	# Update Speed Text and Button State
	speed_label.text = "Speed Upgrade (%d/10)" % StoreManager.speed_upgrade_level
	if StoreManager.speed_upgrade_level >= 10:
		btn_speed.disabled = true
		btn_speed.text = "[MAX]"
	else:
		btn_speed.disabled = StoreManager.soul_coins < 10
		btn_speed.text = "[+]"
		
	# Update DETSUB Text and Button State
	detsub_label.text = "DETSUB (%d/2)" % StoreManager.detsub_level
	if StoreManager.detsub_level >= 2:
		btn_detsub.disabled = true
		btn_detsub.text = "[MAX]"
	else:
		btn_detsub.disabled = StoreManager.soul_coins < 100
		btn_detsub.text = "[+]"

# --- PURCHASE LOGIC ---

func _on_buy_blood() -> void:
	if StoreManager.soul_coins >= 20:
		StoreManager.soul_coins -= 20
		StoreManager.blood_upgrade_level += 1
		update_ui()

func _on_buy_stamina() -> void:
	if StoreManager.soul_coins >= 10:
		StoreManager.soul_coins -= 10
		StoreManager.stamina_upgrade_level += 1
		update_ui()

func _on_buy_speed() -> void:
	if StoreManager.soul_coins >= 10 and StoreManager.speed_upgrade_level < 10:
		StoreManager.soul_coins -= 10
		StoreManager.speed_upgrade_level += 1
		update_ui()

func _on_buy_detsub() -> void:
	if StoreManager.soul_coins >= 100 and StoreManager.detsub_level < 2:
		StoreManager.soul_coins -= 100
		StoreManager.detsub_level += 1
		update_ui()

func _on_continue_pressed() -> void:
	# Transition back to the game to start the next run!
	# UPDATE THIS PATH to match your actual main scene file
	get_tree().change_scene_to_file("res://Game/AlaskaTown.tscn")
