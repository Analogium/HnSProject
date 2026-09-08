class_name DamageType

## Les natures de dégâts du jeu, et la couleur par laquelle chacune s'annonce.
##
## Une classe à part, et non un enum posé dans DamageInfo : CharacterStats doit
## nommer ses résistances par nature, et DamageInfo nomme déjà CharacterStats.
## Les deux se référenceraient en rond, ce que le compilateur GDScript refuse.
## Ici, rien ne dépend de rien — c'est la feuille de l'arbre de dépendances.

enum Kind { PHYSICAL, COLD, FIRE, LIGHTNING, NECROTIC, HOLY }

## Indexés par Kind. Un tableau et non un dictionnaire : l'enum est déjà une
## suite d'entiers à partir de zéro, et l'indexation directe évite un accès haché
## à chaque coup porté.
const NAMES := ["physique", "froid", "feu", "foudre", "nécrotique", "sacré"]

## La couleur de chaque nature, utilisée partout où elle se montre : le nombre
## qui s'envole, la gerbe d'éclats, la ligne de résistance de la fiche. Une seule
## définition, sinon « le froid » finirait par être deux bleus différents selon
## l'endroit où on le regarde.
##
## Choisies pour se distinguer en 32 px par la **valeur** autant que par la
## teinte. Aucune n'approche l'or, qui reste réservé aux critiques et aux élites.
const COLORS := [
	Color(1.00, 0.98, 0.88),   # physique : le blanc chaud de la lame
	Color(0.50, 0.88, 1.00),   # froid : cyan clair
	Color(1.00, 0.48, 0.18),   # feu : orange franc
	Color(0.72, 0.56, 1.00),   # foudre : violet électrique, pas le jaune de l'or
	Color(0.52, 0.78, 0.32),   # nécrotique : vert acide
	Color(1.00, 0.72, 0.80),   # sacré : rose pâle lumineux
]

## Le champ de CharacterStats qui résiste à chaque nature. Le physique a une
## chaîne vide : il ne passe pas par un pourcentage mais par l'armure, dont la
## règle est tout autre. C'est la seule exception, et elle est ici plutôt que
## dans un `if` recopié à chaque endroit qui interroge une résistance.
const RESIST_FIELDS := [
	"",
	"res_cold",
	"res_fire",
	"res_lightning",
	"res_necrotic",
	"res_holy",
]
