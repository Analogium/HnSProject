class_name NoeudDeTalent
extends Resource

## Un nœud de l'arbre d'une compétence : ce qu'il change à la façon dont elle se
## joue, et ce qu'il demande pour s'ouvrir.
##
## Il vit sur la **case** du manuel et non sur la compétence, pour la raison qui
## a mis la position sur la case : une compétence est ce qu'elle fait, pas la
## façon dont un livre l'oriente. Deux manuels qui enseigneraient le même sort
## lui donneraient deux arbres.
##
## Il ne connaît ni la compétence, ni le manuel, ni les points qu'on y a placés :
## ceux-là vivent sur l'exemplaire, et `TalentInvesti` est le couple des deux.

## **Définitif** : il part dans les sauvegardes (invariant 1), dans le même
## dictionnaire que les cases et les passifs du livre. D'où la forme
## `<compétence>_<nœud>`, qui le tient hors de portée d'un homonyme.
@export var id: String = ""
@export var nom: String = ""

## En cases de la petite grille de l'arbre, pas en pixels — la page se redessine
## à une autre taille sans qu'aucun `.tres` ne bouge.
@export var position: Vector2i = Vector2i.ZERO

## Le nœud dont celui-ci dépend, ou vide : il part alors de la compétence
## elle-même. Un parent doit porter au moins un point pour que l'enfant s'ouvre,
## et il ne se reprend plus tant que l'enfant en porte.
@export var parent: String = ""

## Combien de points dans la **compétence** ouvrent ce nœud. Jamais zéro : un
## arbre s'achète après le sort, pas à sa place.
@export var points_requis: int = 1
@export var points_max: int = 1

@export var lignes: Array[LigneDeTalent] = []

## La nature vers laquelle les dégâts partent, et la part qu'un point y déplace.
##
## **C'est la part qui dit s'il y a conversion**, pas la nature : l'enum commence
## au physique, qui est une nature comme une autre, et ne peut donc pas servir de
## « rien ».
@export var convertit_vers: DamageType.Kind = DamageType.Kind.PHYSICAL
@export var part_convertie_par_point: float = 0.0

## Les mots-clés que ce nœud donne à sa compétence — **seulement ceux d'une
## nature**. `projectile`, `attaque` et `sort` décident du chemin que prend le
## lancer et de la cadence qu'il suit : un nœud qui les donnerait ferait partir
## un tir d'une compétence dont la fiche annonce un coup d'arc.
@export var mots_cles_ajoutes: PackedStringArray = PackedStringArray()


func nom_affiche() -> String:
	return Textes.t(nom)


func convertit() -> bool:
	return part_convertie_par_point > 0.0


## Ce que ces points donnent, sous la forme que la résolution et l'affichage
## connaissent déjà.
func mods(points: int) -> Array[StatMod]:
	var out: Array[StatMod] = []
	if points <= 0:
		return out
	for ligne in lignes:
		var m := ligne.modificateur(points)
		if m != null:
			out.append(m)
	return out


## La part des dégâts que ces points déplacent, **bornée au tout** : un nœud mal
## réglé ne doit pas convertir plus que ce qu'il y a.
func conversion(points: int) -> float:
	if points <= 0 or not convertit():
		return 0.0
	return clampf(part_convertie_par_point * float(points), 0.0, 1.0)
