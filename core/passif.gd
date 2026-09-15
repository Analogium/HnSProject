class_name Passif
extends Resource

## Une case de manuel qu'on ne lance pas : ses points agissent tant que le livre est
## au râtelier. Ses lignes entrent dans le **même tri** que les objets portés
## (`Player.recompute_stats`).

## **Définitif** : il part dans les sauvegardes, dans le dictionnaire de points du
## manuel (invariant 1).
@export var id: String = ""
@export var nom: String = ""

## Comme celle d'une compétence, elle peut manquer : la case garde alors son fond
## et son compte de points.
@export var icone: Texture2D

@export var niveau_de_manuel_requis: int = 0

## Un champ : un passif n'a pas de table de dégâts d'où déduire son maximum.
@export var points_max: int = 1

@export var lignes: Array[LigneDeTalent] = []


func nom_affiche() -> String:
	return Textes.t(nom)


func mods(points: int) -> Array[StatMod]:
	var out: Array[StatMod] = []
	if points <= 0:
		return out
	for ligne in lignes:
		var m := ligne.modificateur(points)
		if m != null:
			out.append(m)
	return out
