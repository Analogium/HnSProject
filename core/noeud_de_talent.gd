class_name NoeudDeTalent
extends Resource

## Un nœud d'arbre : ce qu'il change et ce qu'il demande. Sur la **case** du manuel
## et non sur la compétence — deux manuels orienteraient un sort chacun à sa façon.

## **Définitif** (invariant 1), dans le même dictionnaire que les cases : d'où la
## forme `<compétence>_<nœud>`.
@export var id: String = ""
@export var nom: String = ""

## En cases de la grille de l'arbre, pas en pixels.
@export var position: Vector2i = Vector2i.ZERO

## Le nœud parent, ou vide pour partir de la compétence. Un parent porte un point pour
## ouvrir l'enfant, et ne se reprend pas tant que l'enfant en porte.
@export var parent: String = ""

## Combien de points dans la **compétence** ouvrent ce nœud. Jamais zéro : un
## arbre s'achète après le sort, pas à sa place.
@export var points_requis: int = 1
@export var points_max: int = 1

@export var lignes: Array[LigneDeTalent] = []

## La nature d'arrivée et la part par point. **C'est la part qui dit s'il y a
## conversion** : l'enum commence au physique.
@export var convertit_vers: DamageType.Kind = DamageType.Kind.PHYSICAL
@export var part_convertie_par_point: float = 0.0

## **Seulement des mots-clés de nature** : `projectile`, `attaque` et `sort` décident
## du chemin du lancer.
@export var mots_cles_ajoutes: PackedStringArray = PackedStringArray()


func nom_affiche() -> String:
	return Textes.t(nom)


func convertit() -> bool:
	return part_convertie_par_point > 0.0


## Sous la forme que la résolution et l'affichage connaissent déjà.
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
