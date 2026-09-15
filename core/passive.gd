class_name Passive
extends Resource

## Une case de manuel qu'on ne lance pas : ses points agissent tant que le livre est
## au râtelier. Ses lignes entrent dans le **même tri** que les objets portés
## (`Player.recompute_stats`).

## **Définitif** : il part dans les sauvegardes, dans le dictionnaire de points du
## manuel (invariant 1).
@export var id: String = ""
@export var name: String = ""

## Comme celle d'une compétence, elle peut manquer : la case garde alors son fond
## et son compte de points.
@export var icon: Texture2D

@export var required_manual_level: int = 0

## Un champ : un passif n'a pas de table de dégâts d'où déduire son maximum.
@export var points_max: int = 1

@export var lines: Array[TalentLine] = []


func displayed_name() -> String:
	return Texts.t(name)


func mods(points: int) -> Array[StatMod]:
	var out: Array[StatMod] = []
	if points <= 0:
		return out
	for line in lines:
		var m := line.modifier(points)
		if m != null:
			out.append(m)
	return out
