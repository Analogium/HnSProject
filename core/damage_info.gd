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


## Un coup porté par le joueur : le **montant** vient de l'appelant — de la
## compétence lancée depuis le jalon 6 — et c'est ici, et nulle part ailleurs,
## que le critique s'applique. Une compétence ne le retire ni ne le double.
##
## Le montant est demandé plutôt que déduit de `stats.attack_damage` : une
## compétence sur trois ne tape pas avec l'arme, et lire la fiche ici rendrait
## tous les sorts physiques sans qu'un seul appelant s'en aperçoive.
##
## **Un seul tirage, quel que soit le résultat** (invariant 3) : `Game.rng` est le
## fil des tirages de la partie, et un coup qui consommerait tantôt un nombre
## tantôt zéro décalerait toutes les graines de zone tirées ensuite.
static func roll(
	stats: CharacterStats,
	source: Vector2,
	montant: float,
	type: DamageType.Kind = DamageType.Kind.PHYSICAL
) -> DamageInfo:
	var crit := Game.rng.randf() < stats.crit_chance
	var dmg := montant * (stats.crit_multiplier if crit else 1.0)
	return DamageInfo.new(dmg, source, stats.knockback_force, crit, type)
