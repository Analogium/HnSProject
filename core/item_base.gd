class_name ItemBase
extends Resource

## Le *type* d'un objet : ce qui est vrai de toutes les épées. Un `.tres` par
## base, éditable dans l'inspecteur.
##
## À ne pas confondre avec Item, l'exemplaire ramassé au sol. Cette base-ci est
## partagée par tous les exemplaires et **n'est jamais modifiée** : aucun `.tres`
## du projet n'est `resource_local_to_scene`, donc l'écrire toucherait le fichier
## du disque et toutes les parties suivantes de la session.

## Ce qui désigne cette base dans une sauvegarde, et rien d'autre — jamais
## affiché. **Il ne doit plus jamais changer** : le renommer transformerait tous
## les objets déjà sauvegardés en objets inconnus, ignorés au chargement.
##
## Pas le chemin du fichier, qui décrit un rangement et non un objet : déplacer
## `epee.tres` dans un sous-dossier ne doit pas effacer l'épée de tout le monde.
@export var id: String = ""

@export var display_name: String = ""

## Ce que l'objet est au sens de SpriteForge : "sword", "wand", "torso"… C'est
## lui qui décide du dessin de l'icône — pour une arme, c'est exactement la
## fonction qui la pose dans la main d'un personnage, donc l'icône et l'arme
## portée ne peuvent pas diverger.
@export var kind: String = "sword"

## La **famille** d'équipement, vide pour un objet qui ne s'équipe pas. Une
## famille et non un emplacement : un anneau est de famille « ring » et le
## personnage a deux doigts, c'est EquipmentSlots qui décide auquel des deux il
## va.
@export var family: String = "weapon"

## Ce que la base est au-delà de l'endroit où elle se porte : une épée est une
## arme *de mêlée*, une baguette une arme *d'incantation*. C'est là-dessus que
## les affixes filtrent.
##
## Pourquoi pas la famille : elle ne sépare pas l'épée de la baguette — les deux
## sont de famille `weapon`, et aucun filtre écrit sur les familles ne peut
## donner des dégâts d'attaque à l'une et pas à l'autre.
##
## Pourquoi pas l'identifiant de la base : chaque base nouvelle obligerait alors
## à rouvrir tous les `.tres` d'affixes pour l'y ajouter, et l'oubli donnerait
## une base qui ne tire rien sans que rien ne le signale.
##
## **La famille en fait partie**, et c'est la première : un affixe peut donc
## viser « les bottes » sans vocabulaire supplémentaire. Le test du catalogue
## vérifie que chaque base porte bien la sienne.
@export var tags: PackedStringArray = PackedStringArray()

## Encombrement dans le sac, en cases : colonnes × lignes. Le sac ne compte donc
## pas les objets mais la place, et un gros butin coûte quelque chose même quand
## on a de la marge.
@export var grid_size: Vector2i = Vector2i(1, 1)

## La suite de bases à laquelle celle-ci appartient : « lame », « bouclier »,
## « casque_leger »… Une lignée, c'est le même objet à trois âges, et c'est
## l'unité sur laquelle la relève raisonne.
##
## Un emplacement peut en compter plusieurs : le torse a sa lignée lourde et sa
## légère, et c'est ce qui fait qu'on choisit entre l'armure et l'esquive au lieu
## de recevoir la seule armure qui existe.
@export var lignee: String = ""

## Le rang dans la lignée, 1 pour le plus modeste. Le test de monotonie exige
## qu'un palier supérieur demande un niveau supérieur **et** donne un implicite
## supérieur : une lignée où le troisième palier vaut moins que le deuxième est
## un piège que personne ne remarque avant de comparer deux objets en jeu.
@export var palier: int = 1

## Le niveau de zone à partir duquel cette base peut tomber. Une seule borne,
## basse : c'est le palier suivant de sa lignée qui la chassera, pas un plafond
## écrit ici — voir ItemCatalog.fenetre_de_chute.
##
## Le premier palier de chaque lignée vaut 1, ou presque : le jeu doit pouvoir
## habiller un personnage entier dès la première zone, et un test le vérifie pour
## chaque emplacement, à chaque niveau.
@export var niveau_requis: int = 1

## La famille de ce qui se lit au lieu de se porter. Nommée ici plutôt qu'écrite
## en clair dans les règles : c'est la seule famille du jeu qui n'a pas
## d'emplacement, et l'invariant qui va avec — une base porte un archétype **si
## et seulement si** elle est de cette famille — se vérifie donc à un endroit.
const FAMILLE_MANUEL := "manual"

## L'archétype que cette base ouvre, ou null. Non nul si et seulement si la
## famille est « manual » : c'est la base qui dit ce qu'elle est, comme elle dit
## déjà son implicite.
##
## Un champ facultatif ici plutôt qu'un second catalogue tenu en parallèle : deux
## listes qui doivent se correspondre finissent par diverger, et cette
## divergence-là ne se verrait qu'en ramassant l'objet.
@export var manuel: ManuelArchetype

@export_group("Implicite")
## Le bonus que porte *toute* la famille, sans tirage : une épée fait des dégâts,
## un plastron donne des PV. C'est lui qui dit à quoi sert la base.
##
## Des champs simples plutôt qu'une sous-ressource : il y en a exactement un par
## base. Vide (chaîne nulle) pour une base sans implicite.
@export var implicit_stat: String = ""
@export var implicit_percent: bool = false
@export var implicit_value: float = 0.0
## La borne haute d'un implicite de dégâts ajoutés — « ajoute 2 à **6** dégâts
## physiques aux attaques ». Ignorée pour tout le reste.
@export var implicit_value_max: float = 0.0
## Le mot-clé visé, comme pour un affixe : vide pour la fiche du personnage.
@export var implicit_portee: String = ""


func implicit() -> StatMod:
	if implicit_stat.is_empty():
		return null
	return StatMod.depuis_definition(
		implicit_stat, implicit_percent, implicit_value, implicit_value_max, implicit_portee
	)
