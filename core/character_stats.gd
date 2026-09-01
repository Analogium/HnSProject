class_name CharacterStats
extends Resource

@export var max_health: float = 100.0
@export var move_speed: float = 90.0

@export_group("Combat")
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 0.45
@export var attack_range: float = 28.0
@export var knockback_force: float = 180.0
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0
