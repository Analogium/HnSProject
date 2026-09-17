class_name DamageInfo
extends RefCounted

## Un coup : ses parts **par nature**, sa source, son critique. Par nature, pour qu'un
## sort de foudre chargé de froid perde sa foudre et garde son froid.

## Indexées par `DamageType.Kind` ; `Hurtbox` les réduit une à une.
var parts: Array[float] = []
var source_position: Vector2
var knockback: float
var is_crit: bool
## Les états de qui a porté le coup : sa bénédiction l'affaiblit, et la pourriture
## qu'il pose le soigne. Null pour un coup sans auteur — le mannequin, les tests.
var author: StatusEffects
## Le lancer d'où vient le coup, pour ses dégâts contre un état ; null pour un coup
## d'ennemi. Jamais modifié après sa résolution : le partager ne ment pas.
var cast: SkillStats

## Le total des parts, calculé et jamais rangé : une seule vérité.
var amount: float:
	get:
		var total := 0.0
		for part in parts:
			total += part
		return total

## La nature de la part la plus forte, qui donne sa couleur à la gerbe d'éclats.
var type: DamageType.Kind:
	get:
		return DamageType.dominant(parts)


## Un coup d'une seule nature, physique par défaut : celui des ennemis.
func _init(
	p_amount: float,
	p_source: Vector2,
	p_knockback: float = 0.0,
	p_crit: bool = false,
	p_type: DamageType.Kind = DamageType.Kind.PHYSICAL
) -> void:
	parts = DamageType.empty_parts()
	parts[p_type] = p_amount
	source_position = p_source
	knockback = p_knockback
	is_crit = p_crit


## Les parts sont recopiées : la mitigation d'un ennemi ne revient pas dans le sort.
static func as_parts(
	p_parts: Array[float], p_source: Vector2, p_knockback: float = 0.0, p_crit: bool = false
) -> DamageInfo:
	var info := DamageInfo.new(0.0, p_source, p_knockback, p_crit)
	for i in mini(p_parts.size(), info.parts.size()):
		info.parts[i] = p_parts[i]
	return info


## « La part la plus forte » ne s'écrit qu'ici.
func color() -> Color:
	return DamageType.COLORS[type]


## Toutes les parts du même facteur : un critique ne choisit pas sa nature, un
## engourdissement non plus.
func multiplier(factor: float) -> void:
	if factor == 1.0:
		return
	for i in parts.size():
		parts[i] *= factor


## Un coup d'un lancer — attaque ou sort : **le critique ne s'applique qu'ici**, un
## tirage par coup. Sans lancer, un coup d'ennemi, ni critique ni tirage (invariant 3).
static func roll(
	cast: SkillStats, source: Vector2, p_parts: Array[float], p_knockback: float = 0.0
) -> DamageInfo:
	var crit := cast != null and Game.rng.randf() < cast.crit_chance
	var info := DamageInfo.as_parts(p_parts, source, p_knockback, crit)
	info.cast = cast
	if crit:
		info.multiplier(cast.crit_multiplier)
	return info
