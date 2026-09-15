class_name LigneDeTalent
extends Resource

## Ce qu'un point donne, dans un nœud comme dans un passif : une statistique et sa
## valeur **par point**, mise en ligne par `StatMod.depuis_definition()`.

## Sans portée sur un nœud, c'est un nombre de `StatsDeCompetence` ; sans portée
## sur un passif, un champ de `CharacterStats` présent dans `StatMod.LABELS`.
@export var stat: String = ""

## Le mot-clé visé : **toujours vide sur un nœud**, qui ne vise que sa compétence.
@export var portee: String = ""

@export var pourcentage: bool = false

## Par point ; la borne haute laissée à zéro vaut la basse.
@export var valeur_par_point: float = 0.0
@export var valeur_max_par_point: float = 0.0


## La ligne que ces points donnent, ou **null à zéro point** : une ligne nulle
## s'appliquerait sans rien changer, mais s'afficherait comme un bonus acquis.
func modificateur(points: int) -> StatMod:
	if points <= 0:
		return null
	var n := float(points)
	return StatMod.depuis_definition(
		stat,
		pourcentage,
		valeur_par_point * n,
		maxf(valeur_max_par_point, valeur_par_point) * n,
		portee
	)
