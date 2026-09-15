class_name CompetenceCatalog

## Toutes les compétences, **le seul endroit qui les liste**. Un identifiant disparu
## rend null plutôt que de faire échouer un chargement.

## Les attaques de départ, que personne n'apprend : les seuls identifiants cités par
## le code.
const ID_ATTAQUE := "attaque"
const ID_TIR := "tir"

## Ce qu'on sait sans l'avoir appris, dans l'ordre du menu de la barre.
const DE_DEPART := [ID_ATTAQUE, ID_TIR]

const ALL := [
	preload("res://resources/competences/attaque.tres"),
	preload("res://resources/competences/tir.tres"),

	# Chaque manuel, dans l'ordre de ses cases.
	preload("res://resources/competences/eclair_vif.tres"),
	preload("res://resources/competences/chaine_d_eclairs.tres"),
	preload("res://resources/competences/nuage_d_orage.tres"),
	preload("res://resources/competences/nova_de_foudre.tres"),

	preload("res://resources/competences/boule_de_feu.tres"),
	preload("res://resources/competences/serpent_infernal.tres"),
	preload("res://resources/competences/immolation.tres"),

	# Le chevalier : les compétences apprises qui suivent la cadence de l'arme.
	preload("res://resources/competences/frappe_lourde.tres"),
	preload("res://resources/competences/coup_en_croix.tres"),
	preload("res://resources/competences/epee_spirale.tres"),
]


static func est_de_depart(id: String) -> bool:
	return DE_DEPART.has(id)


## Null pour un identifiant retiré du projet, qu'une barre sauvegardée peut citer.
## Balayage linéaire : le catalogue se compte en unités.
static func by_id(id: String) -> Competence:
	for c in ALL:
		if c.id == id:
			return c
	return null
