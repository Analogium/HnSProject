class_name DamageInfo
extends RefCounted

## Un coup : ce qu'il porte **par nature**, d'où il vient, et s'il est critique.
##
## Une part par nature et non un montant et une nature : un sort de foudre qui
## porte trois points de froid doit perdre sa foudre contre un ennemi qui y résiste
## et **garder son froid**. Réduire le tout par une seule résistance ferait mentir
## l'élément écrit sur l'objet qui a donné ce froid.

## Indexées par `DamageType.Kind`, comme les tables de `DamageType` : l'enum est
## déjà une suite d'entiers à partir de zéro. `Hurtbox` les réduit une à une.
var parts: Array[float] = []
var source_position: Vector2
var knockback: float
var is_crit: bool

## Le total des parts : ce que la vie perd et ce que le nombre affiche. Calculé et
## non rangé à côté des parts, sinon la mitigation devrait tenir deux vérités à
## jour, et l'une des deux finirait par mentir.
var amount: float:
	get:
		var total := 0.0
		for part in parts:
			total += part
		return total

## La nature de la part la plus forte, qui donne sa couleur à la gerbe d'éclats.
var type: DamageType.Kind:
	get:
		return DamageType.dominante(parts)


## Un coup d'une seule nature : celui des ennemis, qui n'ont qu'un corps pour
## frapper. Physique par défaut : c'est ce que fait une lame.
func _init(
	p_amount: float,
	p_source: Vector2,
	p_knockback: float = 0.0,
	p_crit: bool = false,
	p_type: DamageType.Kind = DamageType.Kind.PHYSICAL
) -> void:
	parts = DamageType.parts_vides()
	parts[p_type] = p_amount
	source_position = p_source
	knockback = p_knockback
	is_crit = p_crit


## Un coup en plusieurs parts, dans l'ordre de `DamageType.Kind`. Les parts sont
## recopiées : `Hurtbox` écrit dedans, et le lanceur ne doit pas voir la
## mitigation d'un ennemi revenir dans son sort.
static func en_parts(
	p_parts: Array[float], p_source: Vector2, p_knockback: float = 0.0, p_crit: bool = false
) -> DamageInfo:
	var info := DamageInfo.new(0.0, p_source, p_knockback, p_crit)
	for i in mini(p_parts.size(), info.parts.size()):
		info.parts[i] = p_parts[i]
	return info


## La couleur de la gerbe d'éclats. Ici et non chez celui qui dessine, pour que
## « la part la plus forte » ne s'écrive qu'à un endroit.
func color() -> Color:
	return DamageType.COLORS[type]


## Un coup porté par le joueur : les **parts** viennent de l'appelant — du geste
## résolu et déjà tiré — et c'est ici, et nulle part ailleurs, que le critique
## s'applique. Il multiplie toutes les parts : un critique ne choisit pas sa
## nature.
##
## **Un seul tirage, quel que soit le résultat** (invariant 3) : `Game.rng` est le
## fil des tirages de la partie, et un coup qui consommerait tantôt un nombre
## tantôt zéro décalerait tous les tirages suivants.
static func roll(stats: CharacterStats, source: Vector2, p_parts: Array[float]) -> DamageInfo:
	var crit := Game.rng.randf() < stats.crit_chance
	var info := DamageInfo.en_parts(p_parts, source, stats.knockback_force, crit)
	if crit:
		for i in info.parts.size():
			info.parts[i] *= stats.crit_multiplier
	return info
