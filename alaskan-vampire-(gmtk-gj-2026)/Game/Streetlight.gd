extends Node2D

@onready var light_zone: Area2D = $LightZone
@onready var light: PointLight2D = $PointLight2D
@onready var notifier: VisibleOnScreenNotifier2D = $PointLight2D/VisibleOnScreenNotifier2D

func _ready() -> void:
	light_zone.body_entered.connect(_on_light_zone_body_entered)
	light_zone.body_exited.connect(_on_light_zone_body_exited)
	light.enabled = notifier.is_on_screen()
	notifier.screen_entered.connect(func(): light.enabled = true)
	notifier.screen_exited.connect(func(): light.enabled = false)

func _on_light_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		# Stepping into streetlight reveals player!
		body.is_in_shadow = false

func _on_light_zone_body_exited(body: Node2D) -> void:
	if body is Player:
		# Leaving light returns player to the safety of shadows
		body.is_in_shadow = true
