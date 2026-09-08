class_name DamageInfo
extends RefCounted

var amount: float
var source_position: Vector2
var knockback: float
var is_crit: bool
## La nature du coup. Physique par défaut : c'est ce que fait une lame, et un
## coup dont personne n'a choisi l'élément ne doit pas en inventer un.
var type: DamageType.Kind


func _init(
	p_amount: float,
	p_source: Vector2,
	p_knockback: float = 0.0,
	p_crit: bool = false,
	p_type: DamageType.Kind = DamageType.Kind.PHYSICAL
) -> void:
	amount = p_amount
	source_position = p_source
	knockback = p_knockback
	is_crit = p_crit
	type = p_type


## Ici et non chez celui qui dessine : le nombre flottant, la gerbe d'éclats et
## la ligne de résistance de la fiche doivent la partager.
func color() -> Color:
	return DamageType.COLORS[type]


static func roll(
	stats: CharacterStats,
	source: Vector2,
	type: DamageType.Kind = DamageType.Kind.PHYSICAL
) -> DamageInfo:
	var crit := Game.rng.randf() < stats.crit_chance
	var dmg := stats.attack_damage * (stats.crit_multiplier if crit else 1.0)
	return DamageInfo.new(dmg, source, stats.knockback_force, crit, type)
