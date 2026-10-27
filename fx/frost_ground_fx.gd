class_name FrostGroundFx
extends Node3D

## Le sol gelé en 3D (jalon 54 ; Givre persistant, et tout sol de froid : Pics, Désastre). « Fissures »
## choisi sur une première planche, puis la barre de Last Epoch : « glace A » choisie contre une autre
## glace, la même avec un liseré de givre qui frémit et les fissures des Pics : la glace craquelée de la
## vitrine de la Nova, en décal qui épouse le relief, et quelques scintillements lents. Elle n'est plus
## qu'ici : sous un sort qui ne gèle pas le sol, elle en disait un (26 octobre).
##
## **Le Marais** de la Déferlante toxique y prend sa boue (`fx/rot_sludge.png`, Qwen-Image), sans
## scintillements : le seul sol nécrotique, qui frappe vraiment ce qui s'y tient.
##
## Il vit sur son sol (`DashTrail`), qui lui donne son âge : ravivé, le sol repart, et lui avec.

## Au cyan (`tools/fx_textures.py nova`) : éclairé par le soleil du jeu, un albédo clair sortait blanc.
const ICE := preload("res://fx/nova_ice.png")
const SLUDGE := preload("res://fx/rot_sludge.png")
## Ce qui a un sol à soi ; les autres natures gardent leur disque d'étincelles.
const GROUNDS := {DamageType.Kind.COLD: ICE, DamageType.Kind.NECROTIC: SLUDGE}
const SLUDGE_SHADE := Color(0.45, 0.6, 0.35)
## Assez bas pour ne prendre que le sol : à 40, il bleuissait les grunts.
const DEPTH := 8.0
const SPAN := 1.15
## Le temps qu'il met à fondre, au bout de la durée du sol.
const THAW := 0.5
const GLINTS := 10

var _radius := 0.0
var _ice: Decal
## Le voile du menu, que la fonte multiplie.
var _veil := 1.0
var _glints: MultiMeshInstance3D
var _phases: Array[float] = []


## La glace de `ground` (pour son voile), à son rayon.
static func lay(ground: Node3D, radius: float, nature: int) -> FrostGroundFx:
	var fx := FrostGroundFx.new()
	fx._radius = radius
	ground.add_child(fx)
	fx._ice = Decal.new()
	fx._ice.texture_albedo = GROUNDS[nature]
	fx._ice.albedo_mix = 1.0
	fx._ice.upper_fade = 0.5
	fx._ice.lower_fade = 0.2
	fx._ice.rotation.y = randf() * TAU
	fx.add_child(fx._ice)
	ElementFx.veil_like(fx._ice, ground)
	fx._veil = fx._ice.modulate.a
	if nature != DamageType.Kind.COLD:
		# Sous le soleil, la boue claire sortait presque blanche.
		fx._ice.modulate = Color(SLUDGE_SHADE, fx._veil)
		return fx
	fx._glints = IceNovaFx.scatter_glints(fx, GLINTS, radius, nature, fx._phases)
	ElementFx.veil_like(fx._glints, ground)
	return fx


## Il s'ouvre en `open` secondes et fond sur les `THAW` dernières de sa durée `life`.
func thaw(age: float, life: float, open: float) -> void:
	var grown := ease(clampf(age / open, 0.0, 1.0), 0.4)
	var left := 1.0 - smoothstep(life - THAW, life, age)
	var side := _radius * 2.0 * SPAN * (0.3 + 0.7 * grown)
	_ice.size = Vector3(side, DEPTH, side)
	_ice.modulate.a = _veil * left
	if _glints == null:
		return
	for i in GLINTS:
		IceNovaFx.shine(_glints, i, left * IceNovaFx.twinkle(age, _phases[i], 3.0, 12.0))
