class_name TalentLine
extends Resource

## Ce qu'un point donne, dans un nœud comme dans un passif : une statistique et sa
## valeur **par point**, mise en ligne par `StatMod.from_definition()`.

## Sans portée sur un nœud, c'est un nombre de `SkillStats` ; sans portée
## sur un passif, un champ de `CharacterStats` présent dans `StatMod.LABELS`.
@export var stat: String = ""

## Le mot-clé visé : **toujours vide sur un nœud**, qui ne vise que sa compétence.
@export var scope: String = ""

@export var percentage: bool = false

## Par point ; la borne haute laissée à zéro vaut la basse.
@export var value_per_point: float = 0.0
@export var value_max_per_point: float = 0.0


## La ligne que ces points donnent, ou **null à zéro point** : une ligne nulle
## s'appliquerait sans rien changer, mais s'afficherait comme un bonus acquis.
func modifier(points: int) -> StatMod:
	if points <= 0:
		return null
	var n := float(points)
	return StatMod.from_definition(
		stat,
		percentage,
		value_per_point * n,
		maxf(value_max_per_point, value_per_point) * n,
		scope
	)
