class_name ItemBase
extends Resource

## Le *type* d'un objet, partagé par tous ses exemplaires (`Item`) et **jamais
## modifié** (invariant 2).

## L'identifiant de sauvegarde, jamais affiché et **définitif** (invariant 1). Pas le
## chemin du fichier : ranger `sword.tres` ailleurs ne doit pas effacer l'épée.
@export var id: String = ""

@export var display_name: String = ""

## Le dessin au sens de SpriteForge : l'icône d'une arme est la fonction qui la pose en
## main, les deux ne peuvent pas diverger.
@export var kind: String = "sword"

## La **famille** d'équipement, vide si l'objet ne s'équipe pas ; `EquipmentSlots`
## choisit l'emplacement.
@export var family: String = "weapon"

## Ce que la base est au-delà de sa famille — mêlée, incantation… — et sur quoi les
## affixes filtrent. Ni la famille (elle ne sépare pas l'épée de la baguette) ni
## l'identifiant (chaque base obligerait à rouvrir les affixes). **La famille en fait
## partie, en premier** ; un test le vérifie.
@export var tags: PackedStringArray = PackedStringArray()

## L'image de l'objet, ou null pour le dessin de `SpriteForge`. Un champ, comme
## pour une compétence, et non un fichier retrouvé par son identifiant : un nom mal
## tapé donnerait une case vide sans que rien ne le dise.
@export var icon: Texture2D

## Encombrement dans le sac, en cases.
@export var grid_size: Vector2i = Vector2i(1, 1)

## La lignée : le même objet à plusieurs âges, unité de la relève. Un emplacement peut
## en avoir plusieurs (torse lourd, torse léger).
@export var lineage: String = ""

## Le rang dans la lignée ; un palier supérieur demande un niveau **et** un implicite
## supérieurs (test de monotonie).
@export var tier: int = 1

## Le niveau de zone d'où elle tombe. Pas de plafond : le palier suivant la chasse
## (`ItemCatalog.drop_window`). Le premier palier vaut 1, pour habiller un
## personnage dès la première zone.
@export var required_level: int = 1

## La seule famille sans emplacement : une base porte un archétype **si et seulement
## si** elle en est.
const MANUAL_FAMILY := "manual"

## L'archétype qu'ouvre cette base, ou null : un champ ici plutôt qu'un second
## catalogue qui divergerait.
@export var manual: ManualArchetype

@export_group("Implicite")
## Le bonus de toute la famille, sans tirage. Des champs simples, un par base ;
## `implicit_stat` vide pour aucun.
@export var implicit_stat: String = ""
@export var implicit_percent: bool = false
@export var implicit_value: float = 0.0
## La borne haute d'un implicite de dégâts ajoutés — « ajoute 2 à **6** dégâts
## physiques aux attaques ». Ignorée pour tout le reste.
@export var implicit_value_max: float = 0.0
## Le mot-clé visé, comme pour un affixe : vide pour la fiche du personnage.
@export var implicit_scope: String = ""

@export_group("Arme")
## La chance critique de base de tout ce que lance le porteur, sous l'implicite. Zéro
## hors des armes : **seule l'arme** donne une base, le reste ne fait que l'accroître.
@export_range(0.0, 1.0) var crit_chance: float = 0.0

const WEAPON_FAMILY := "weapon"
## L'étiquette qui fait une arme d'incantation ; toute autre arme est d'attaque.
const CASTER_TAG := "caster"


## Le mot-clé des compétences que cette arme laisse lancer, vide hors des armes.
func allowed_keyword() -> String:
	if family != WEAPON_FAMILY:
		return ""
	return Keywords.SPELL if tags.has(CASTER_TAG) else Keywords.ATTACK


## Une ligne qui monte la base de l'arme plutôt que la fiche : plate ou accrue.
func is_local(m: StatMod) -> bool:
	return family == WEAPON_FAMILY and m.stat == SkillStats.CRIT_CHANCE and m.mode != StatMod.Mode.MORE


func implicit() -> StatMod:
	if implicit_stat.is_empty():
		return null
	return StatMod.from_definition(
		implicit_stat, implicit_percent, implicit_value, implicit_value_max, implicit_scope
	)
