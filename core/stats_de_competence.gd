class_name StatsDeCompetence
extends RefCounted

## Ce qu'un lancer fait vraiment : les nombres de la compétence, une fois
## appliqués les modificateurs dont elle porte le mot-clé.
##
## **Le résultat d'un lancer, pas un état.** Elle naît à chaque appel de
## `Competence.resoudre()` et meurt avec lui ; rien ne la garde, donc rien ne peut
## la laisser périmer après un changement d'équipement.
##
## Pas dans `CharacterStats` : la fiche décrit un corps, et « nombre de
## projectiles » n'est pas une propriété du personnage mais d'un geste. Deux
## compétences lancées par le même personnage n'en ont pas le même nombre.

## Ce qu'un modificateur a le droit de viser, et le nom qu'il porte à l'écran.
##
## Le coût et l'intervalle n'y sont pas : ils ont déjà leurs voies — la réserve,
## et les vitesses d'attaque et d'incantation de la fiche — et une seconde voie
## vers le même nombre obligerait à se demander laquelle s'applique d'abord.
##
## « nombre de projectiles » et non « projectile » : la ligne se lit
## « valeur + nom », comme « +25 armure », et un « +2 projectile » au singulier
## serait faux dès le second palier.
const LABELS := {
	"degats": "dégâts",
	"projectiles": "nombre de projectiles",
	"vitesse_de_projectile": "vitesse de projectile",
}

## L'écart minimal entre deux traits voisins, en degrés.
##
## Sans lui, un « +1 projectile » sur un trait droit en ferait partir deux **l'un
## sur l'autre** : on en verrait un seul, qui frapperait deux fois la même cible.
## Huit degrés les séparent d'une largeur d'ennemi à cent pixels, sans en faire un
## éventail. Une salve déjà plus large que ça garde la sienne.
const ECART_MINIMAL := 8.0

var degats := 0.0
## Un réel pendant la résolution, arrondi à la fin par `conclure()`. Un « +50 % »
## sur trois projectiles donne 4,5 ; arrondir à chaque modificateur ferait
## dépendre le résultat de leur ordre. Et un champ entier tronquerait en silence
## ce que `set()` y écrit.
var projectiles := 1.0
var dispersion_en_degres := 0.0
var vitesse_de_projectile := 0.0
var cout_en_mana := 0.0
var intervalle := 0.0


func nombre_de_projectiles() -> int:
	return int(projectiles)


## Les bornes, une fois **tous** les modificateurs appliqués et jamais avant.
##
## La dispersion est bornée au tour complet : au-delà, le lanceur prendrait un
## éventail très large pour une couronne et répartirait les traits comme telle.
func conclure() -> void:
	var n := maxi(roundi(projectiles), 1)
	projectiles = float(n)
	dispersion_en_degres = clampf(
		maxf(dispersion_en_degres, ECART_MINIMAL * float(n - 1)), 0.0, 360.0
	)
