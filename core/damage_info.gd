class_name DamageInfo
extends RefCounted

var amount: float
var source_position: Vector2
var knockback: float
var is_crit: bool


func _init(
	p_amount: float,
	p_source: Vector2,
	p_knockback: float = 0.0,
	p_crit: bool = false
) -> void:
	amount = p_amount
	source_position = p_source
	knockback = p_knockback
	is_crit = p_crit


static func roll(stats: CharacterStats, source: Vector2) -> DamageInfo:
	var crit := Game.rng.randf() < stats.crit_chance
	var dmg := stats.attack_damage * (stats.crit_multiplier if crit else 1.0)
	return DamageInfo.new(dmg, source, stats.knockback_force, crit)
