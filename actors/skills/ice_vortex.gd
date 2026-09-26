class_name IceVortex
extends Node2D

## Le vortex de Désastre hivernal : posé sur le personnage, il **grandit pendant toute
## sa durée** et frappe son cercle à chaque période. C'est la croissance qui le sépare du
## nuage d'orage : on le pose tôt, il paie tard.
##
## Il ne fige jamais le jeu — une impulsion qui gèle toutes les demi-secondes hacherait
## l'image tant qu'il tourne.

## Le rayon de départ, en part du rayon final : sous un tiers, ses premières impulsions
## ne toucheraient que ce qui est déjà sur le personnage.
const SEED_PART := 0.35
## Les bras de la spirale, leur vitesse en tours par seconde, et ce qu'ils
## balaient d'angle du cœur au bord — c'est cet écart qui fait l'enroulement.
##
## **Douze et non quatre** (choisi sur planche, jalon 24) : au cœur ils se touchent
## et font une roue pleine, ce qui donne enfin un œil au tourbillon. À quatre, on
## voyait quatre traits qui tournaient.
const ARMS := 12
const SPIN := 1.6
const SWEEP := 2.2
## Ce qui sépare deux éclats d'un bras, au plus serré : plus espacés, les bras se
## lisent comme des colliers de perles — le défaut qu'avait le dos du serpent.
const CHIP_STEP := 3.0
## Les flocons aspirés vers le cœur, hors des bras.
const FLAKES := 8
const FADE := 0.4

var _cast: SkillStats
var _author: StatusEffects
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0


static func open(
	parent: Node, point: Vector2, cast: SkillStats, author: StatusEffects
) -> IceVortex:
	var vortex := IceVortex.new()
	vortex._cast = cast
	vortex._author = author
	vortex._tint = DamageType.COLORS[cast.dominant_nature()]
	parent.add_child(vortex)
	Settings.veil(vortex, Settings.SPELLS)
	vortex.global_position = point
	return vortex


## Pas de lumière ajoutée : les éclats sont **dessinés**, et une planche cernée
## ne peut pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	z_index = 3


## Ce qu'il couvre maintenant : de `SEED_PART` à son rayon plein, linéairement.
func reach() -> float:
	var grown := clampf(_age / _cast.duration, 0.0, 1.0) if _cast.duration > 0.0 else 1.0
	return _cast.radius * lerpf(SEED_PART, 1.0, grown)


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et le vortex ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	_age += delta
	var total := _cast.strikes_over_duration()
	while _strikes < total and _age >= float(_strikes) * _cast.period:
		_strike()
		_strikes += 1
	queue_redraw()
	if _age >= _cast.duration and _strikes >= total:
		queue_free()


## Un tirage par impulsion, qu'elle touche ou non : c'est un geste du vortex.
func _strike() -> void:
	var parts := _cast.roll(Game.rng)
	for target in Targets.in_circle(get_world_2d(), global_position, reach()):
		Targets.strike(target, parts, global_position, _author, _cast)


## Un tourbillon, et non un cercle de pics : quatre bras d'éclats **couchés sur
## leur cap**, et des flocons aspirés vers le cœur. C'est l'orientation des éclats
## qui dit que ça tourne ; tous pointés en haut, ce ne serait qu'une chute de neige.
##
## Pas de givre au sol sous celui-ci, contrairement aux pics et à la nova : un
## tourbillon ne se pose pas, et son rayon change à chaque image — une trame par
## rayon entier se recalculerait cinquante fois par lancer.
func _draw() -> void:
	var r := reach()
	var fade := clampf((_cast.duration - _age) / (_cast.duration * FADE), 0.0, 1.0)
	var steps := maxi(int(r / CHIP_STEP), 2)
	for i in ARMS:
		var base := TAU * float(i) / float(ARMS) + _age * SPIN
		for step in steps:
			# Il ne pâlit pas, il se **vide**. Un éclat en moins se lit comme un éclat
			# en moins ; un éclat à demi transparent sur un sol sombre sort gris, le
			# même piège que l'orange peu opaque du feu. Le tirage ne dépend que du
			# bras et du rang : c'est une trame, pas un scintillement.
			if fmod(float(step) * 0.618 + float(i) * 0.37, 1.0) > fade:
				continue
			# La racine étire les rangs vers le bord : à pas constant, le bout du bras
			# — qui parcourt deux fois plus de chemin par rang — s'égrenait en collier.
			var along := pow((float(step) + 1.0) / float(steps), 0.6)
			var at := Vector2.from_angle(base + along * SWEEP) * r * along
			# Le cap d'un éclat est la tangente de la spirale, pas le rayon : c'est
			# la différence entre un tourbillon et une étoile.
			var ahead := Vector2.from_angle(base + (along + 0.04) * SWEEP) * r * (along + 0.04)
			Frost.chip(self, at, (ahead - at).angle(), _tint, 1.0)

	for i in FLAKES:
		var turn := _age * SPIN * 1.4 + TAU * float(i) / float(FLAKES)
		# Ils tombent vers le cœur : un vortex aspire, il ne rayonne pas.
		var away := 1.0 - fmod(_age * 0.6 + float(i) * 0.137, 1.0)
		Frost.drift(self, Vector2.from_angle(turn) * r * away, _tint, 0.8 * away * fade)
