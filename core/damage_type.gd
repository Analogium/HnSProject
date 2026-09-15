class_name DamageType

## Les natures de dégâts et leur couleur. Une feuille sans dépendance :
## CharacterStats et DamageInfo la nomment toutes deux.

enum Kind { PHYSICAL, COLD, FIRE, LIGHTNING, NECROTIC, HOLY }

## Indexés par Kind.
const NAMES := ["physique", "froid", "feu", "foudre", "nécrotique", "sacré"]

## L'identifiant sans accent, qui forme `degats_froid` : **définitif** (invariant 1).
const IDS := ["physique", "froid", "feu", "foudre", "necrotique", "sacre"]

## « ajoute 3 à 7 **dégâts de froid** » : distinct de NAMES, le français n'accordant
## pas « physiques » comme « de froid ».
const LIBELLES_DE_DEGATS := [
	"dégâts physiques",
	"dégâts de froid",
	"dégâts de feu",
	"dégâts de foudre",
	"dégâts nécrotiques",
	"dégâts sacrés",
]

## La couleur de chaque nature, partout sauf le nombre qui s'envole — blanc, c'est un
## total. Distinctes par la valeur autant que la teinte ; aucune n'approche l'or.
const COLORS := [
	Color(1.00, 0.98, 0.88),   # physique : le blanc chaud de la lame
	Color(0.50, 0.88, 1.00),   # froid : cyan clair
	Color(1.00, 0.48, 0.18),   # feu : orange franc
	Color(0.72, 0.56, 1.00),   # foudre : violet électrique, pas le jaune de l'or
	Color(0.52, 0.78, 0.32),   # nécrotique : vert acide
	Color(1.00, 0.72, 0.80),   # sacré : rose pâle lumineux
]

## Le champ qui résiste à chaque nature ; vide pour le physique, qui passe par
## l'armure.
const RESIST_FIELDS := [
	"",
	"res_cold",
	"res_fire",
	"res_lightning",
	"res_necrotic",
	"res_holy",
]


## Dans la langue du joueur : les tables françaises sont les clés.
static func nom(kind: int) -> String:
	return Textes.t(NAMES[kind])


static func libelle_de_degats(kind: int) -> String:
	return Textes.t(LIBELLES_DE_DEGATS[kind])


## Une part nulle par nature, de la taille de l'enum.
static func parts_vides() -> Array[float]:
	var parts: Array[float] = []
	parts.resize(Kind.size())
	parts.fill(0.0)
	return parts


## À égalité, la première : des parts nulles restent physiques.
static func dominante(parts: Array[float]) -> Kind:
	var plus_forte := 0
	for i in parts.size():
		if parts[i] > parts[plus_forte]:
			plus_forte = i
	return plus_forte as Kind
