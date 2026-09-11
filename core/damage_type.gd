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

## L'identifiant de chaque nature dans les données, sans accent : il forme le nom
## des statistiques de dégâts ajoutés — `degats_froid` — que les affixes visent
## et que les sauvegardes écrivent. **Il ne change jamais** (invariant 1) ; le nom
## lisible est dans NAMES.
const IDS := ["physique", "froid", "feu", "foudre", "necrotique", "sacre"]

## Les dégâts de chaque nature, tels qu'une ligne d'objet les écrit : « ajoute 3 à
## 7 **dégâts de froid** ». Distinct de NAMES, l'adjectif seul, parce que le
## français n'accorde pas « physiques » comme « de froid ».
const LIBELLES_DE_DEGATS := [
	"dégâts physiques",
	"dégâts de froid",
	"dégâts de feu",
	"dégâts de foudre",
	"dégâts nécrotiques",
	"dégâts sacrés",
]

## La couleur de chaque nature, utilisée partout où elle se montre : le tir, la
## gerbe d'éclats, les lignes de la fiche — mais pas le nombre qui s'envole, blanc
## parce qu'il est le total de toutes les parts. Une seule définition, sinon « le
## froid » finirait par être deux bleus différents selon l'endroit où on le
## regarde.
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


## Le nom d'une nature dans la langue du joueur. Les tables gardent leurs valeurs
## **françaises** : ce sont elles, les clés de traduction. Lire `NAMES` directement
## pour l'afficher donne un mot qui restera français en anglais.
static func nom(kind: int) -> String:
	return Textes.t(NAMES[kind])


static func libelle_de_degats(kind: int) -> String:
	return Textes.t(LIBELLES_DE_DEGATS[kind])


## Une part nulle par nature : la forme des dégâts d'un coup ou d'un lancer.
## Écrite ici pour que sa taille suive l'enum — une nature ajoutée à la fin de
## `Kind` agrandit toutes les parts du jeu sans qu'on ait à y penser.
static func parts_vides() -> Array[float]:
	var parts: Array[float] = []
	parts.resize(Kind.size())
	parts.fill(0.0)
	return parts


## La nature de la part la plus forte. À égalité, la première de l'enum : des
## parts toutes nulles restent physiques, comme un coup dont personne n'a choisi
## l'élément.
static func dominante(parts: Array[float]) -> Kind:
	var plus_forte := 0
	for i in parts.size():
		if parts[i] > parts[plus_forte]:
			plus_forte = i
	return plus_forte as Kind
