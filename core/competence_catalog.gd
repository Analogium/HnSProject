class_name CompetenceCatalog

## Toutes les compétences du jeu, et le seul endroit qui les liste — le pendant
## d'`ItemCatalog` pour ce qu'on lance plutôt que pour ce qu'on porte.
##
## Les sauvegardes ne contiennent que des identifiants : c'est ici qu'ils
## redeviennent des compétences, et c'est pourquoi un identifiant disparu rend
## null au lieu de faire échouer un chargement.

## Les deux attaques de départ ne viennent d'aucun manuel : elles sont là depuis
## le jalon 1 et personne ne les apprend. Ce sont les seuls identifiants de
## compétence que du code cite par leur nom — partout ailleurs ils viennent d'un
## manuel ou d'un fichier de sauvegarde.
const ID_ATTAQUE := "attaque"
const ID_TIR := "tir"

const ALL := [
	preload("res://resources/competences/attaque.tres"),
	preload("res://resources/competences/tir.tres"),

	# Le manuel de la foudre : quatre cases, de la plus simple à la plus chère.
	# Elles se distinguent par ce qu'elles font, pas seulement par leurs nombres —
	# un trait, une salve, un coup lourd, une nova — sinon ce serait une seule
	# compétence à quatre réglages.
	preload("res://resources/competences/eclair_vif.tres"),
	preload("res://resources/competences/salve_d_eclairs.tres"),
	preload("res://resources/competences/fulguration.tres"),
	preload("res://resources/competences/nova_de_foudre.tres"),
]


## La compétence portant cet identifiant, ou null s'il n'existe plus. Le null
## n'est pas une erreur de programmation mais un cas de jeu : une barre
## sauvegardée peut citer une compétence retirée du projet depuis.
##
## Balayage linéaire : les appelants sont le chargement d'une sauvegarde,
## l'assignation d'une case et les tests — aucun n'est dans une boucle de jeu.
static func by_id(id: String) -> Competence:
	for c in ALL:
		if c.id == id:
			return c
	return null
