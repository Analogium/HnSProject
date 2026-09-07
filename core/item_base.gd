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

## Ce qui désigne cette base dans une sauvegarde, et rien d'autre — jamais
## affiché. Saisi à la main dans le `.tres`, et **il ne doit plus jamais
## changer** : le renommer transformerait tous les objets déjà sauvegardés en
## objets inconnus, qui seraient ignorés au chargement.
##
## Pourquoi pas le chemin du fichier, qui désigne déjà la base de façon unique :
## parce qu'il décrit un rangement et non un objet. Déplacer `epee.tres` dans un
## sous-dossier est une décision sans conséquence de jeu ; elle ne doit pas
## effacer l'épée de tout le monde.
@export var id: String = ""

@export var display_name: String = ""

## Ce que l'objet est, au sens de SpriteForge : "sword", "wand", "torso"…
## C'est lui qui décide du dessin de l'icône — pour une arme, c'est exactement
## la fonction qui la pose dans la main d'un personnage, donc l'icône et l'arme
## portée ne peuvent pas diverger.
@export var kind: String = "sword"

## La **famille** d'équipement : à quel genre d'objet celui-ci appartient.
## Vide pour un objet qui ne s'équipe pas.
##
## Une famille et non un emplacement, et le champ s'appelait `slot` jusqu'au
## jalon 4. Un anneau est de famille « ring » et le personnage a deux doigts :
## c'est EquipmentSlots qui décide auquel des deux il va, pas la base.
@export var family: String = "weapon"

## Ce que la base est, au-delà de l'endroit où elle se porte : une épée est une
## arme *de mêlée*, une baguette une arme *d'incantation*, un plastron une
## *armure*. C'est là-dessus que les affixes filtrent.
##
## Pourquoi pas la famille, qui existe déjà : parce qu'elle ne sépare pas l'épée
## de la baguette — les deux sont de famille `weapon`, et **aucun filtre écrit
## sur les familles ne peut donner des dégâts d'attaque à l'une et pas à
## l'autre**. C'est le cas qui a fait éclater la règle, comme les deux anneaux
## avaient fait éclater `slot` au jalon 4.
##
## Pourquoi pas l'identifiant de la base : chaque base nouvelle obligerait alors
## à rouvrir tous les `.tres` d'affixes pour l'y ajouter, et l'oubli donnerait
## une base qui ne tire rien sans que rien ne le signale. Une base qui a besoin
## de son propre identifiant dans un affixe est une base à qui il manque une
## étiquette.
##
## **La famille en fait partie**, et c'est la première : un affixe peut donc
## viser « les bottes » sans vocabulaire supplémentaire, et les affixes écrits
## avant le jalon 5 continuent de tomber sur exactement les mêmes objets. Le
## test du catalogue vérifie que chaque base porte bien la sienne.
@export var tags: PackedStringArray = PackedStringArray()

## Encombrement dans le sac, en cases : colonnes × lignes. C'est la règle de
## Path of Exile et de Hero Siege — une épée mange une colonne sur trois lignes,
## un plastron deux sur trois. Le sac ne compte donc pas les objets mais la
## place, et un gros butin coûte quelque chose même quand on a de la marge.
##
## Vector2i et non deux entiers : c'est un couple qu'on lit, teste et décale
## toujours d'un bloc.
@export var grid_size: Vector2i = Vector2i(1, 1)

## Le niveau de zone à partir duquel cette base peut tomber. Une seule borne,
## basse : au-dessus, la base reste dans le tirage — c'est le palier suivant de
## sa lignée qui la chassera, pas un plafond écrit ici.
##
## Toutes les bases du jalon 4 valent 1 : elles sont le premier palier de leur
## lignée, et le jeu doit pouvoir tout habiller dès la première zone. Ce sont les
## paliers de l'étape 5 qui donneront ses valeurs à ce champ.
@export var niveau_requis: int = 1

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
