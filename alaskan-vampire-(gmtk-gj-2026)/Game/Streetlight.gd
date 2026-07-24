extends Node2D

@onready var light_zone: Area2D = $LightZone

func _ready() -> void:
	light_zone.body_entered.connect(_on_light_zone_body_entered)
	light_zone.body_exited.connect(_on_light_zone_body_exited)

func _on_light_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		# Stepping into streetlight reveals player!
		body.is_in_shadow = false

func _on_light_zone_body_exited(body: Node2D) -> void:
	if body is Player:
		# Leaving light returns player to the safety of shadows
		body.is_in_shadow = true
