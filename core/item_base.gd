class_name ItemBase
extends Resource

## Le *type* d'un objet : ce qui est vrai de toutes les épées. Une Resource comme
## CharacterStats et Affix — un `.tres` par base, éditable dans l'inspecteur, et
## en ajouter une ne demande pas de code.
##
## À ne pas confondre avec Item, l'exemplaire ramassé au sol. Cette base-ci est
## partagée par tous les exemplaires et **n'est jamais modifiée** : aucun `.tres`
## du projet n'est `resource_local_to_scene`, donc l'écrire toucherait le fichier
## du disque et toutes les parties suivantes de la session. C'est la même
## séparation que `base_stats` / `stats` chez le joueur.

@export var display_name: String = ""

## Ce que l'objet est, au sens de SpriteForge : "sword", "wand", "torso"…
## C'est lui qui décide du dessin de l'icône — pour une arme, c'est exactement
## la fonction qui la pose dans la main d'un personnage, donc l'icône et l'arme
## portée ne peuvent pas diverger.
@export var kind: String = "sword"

## Emplacement d'équipement. Vide pour un objet qui ne s'équipe pas.
@export var slot: String = "weapon"

## Encombrement dans le sac, en cases : colonnes × lignes. C'est la règle de
## Path of Exile et de Hero Siege — une épée mange une colonne sur trois lignes,
## un plastron deux sur trois. Le sac ne compte donc pas les objets mais la
## place, et un gros butin coûte quelque chose même quand on a de la marge.
##
## Vector2i et non deux entiers : c'est un couple qu'on lit, teste et décale
## toujours d'un bloc.
@export var grid_size: Vector2i = Vector2i(1, 1)

@export_group("Implicite")
## Le bonus que porte *toute* la famille, sans tirage : une épée fait des
## dégâts, un plastron donne des PV. C'est lui qui dit à quoi sert la base, et
## qui rend une épée nue préférable à un plastron nu quand on veut frapper.
##
## Trois champs simples plutôt qu'une sous-ressource : il y en a exactement un
## par base, et un `.tres` avec une ressource imbriquée est pénible à relire.
## Vide (chaîne nulle) pour une base sans implicite.
@export var implicit_stat: String = ""
@export var implicit_percent: bool = false
@export var implicit_value: float = 0.0


func implicit() -> StatMod:
	if implicit_stat.is_empty():
		return null
	var mode := StatMod.Mode.PERCENT if implicit_percent else StatMod.Mode.FLAT
	return StatMod.new(implicit_stat, mode, implicit_value)
