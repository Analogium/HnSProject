class_name LigneDeTalent
extends Resource

## Ce qu'un point donne, dans un nœud d'arbre comme dans un passif : une
## statistique et sa valeur **par point**.
##
## La même forme qu'un palier d'affixe, et c'est `StatMod.depuis_definition()`
## qui en fait une ligne : un talent et un objet qui donnent tous deux « +1
## projectile » l'appliquent, l'affichent et l'arrondissent pareil. Une seconde
## forme de modificateur aurait surtout été une seconde façon de l'écrire à
## l'écran.

## Sans portée sur un nœud, c'est un nombre de `StatsDeCompetence` ; sans portée
## sur un passif, un champ de `CharacterStats` présent dans `StatMod.LABELS`.
@export var stat: String = ""

## Le mot-clé visé. **Toujours vide sur un nœud d'arbre** : il ne vise que sa
## propre compétence, et rien n'a à le dire. Sur un passif, c'est la portée d'un
## affixe, avec les mêmes règles — vide pour la fiche du personnage.
@export var portee: String = ""

@export var pourcentage: bool = false

## La valeur d'un point, et sa borne haute pour ce qui se donne en fourchette —
## des dégâts ajoutés. Laissée à zéro, la haute vaut la basse : c'est le cas de
## tout ce qui n'est pas une fourchette.
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
