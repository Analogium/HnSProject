class_name SlashWave
extends Node2D

## Ce qu'un coup de taille envoie devant lui : l'arc du geste, détaché de la lame, qui
## avance en ligne droite et mord **une fois par corps**.
##
## Il naît en avant du bras (`START`) : sur le personnage, il doublerait le coup de la
## hitbox sur tout ce qui est déjà au contact.
##
## Ses parts sont tirées **une fois à la naissance**, comme celles du coup qui l'envoie :
## tout l'arc porte la même valeur.

## Devant le personnage, en pixels : au-delà de l'allonge de la hitbox.
const START := 18.0
## L'ouverture de l'arc dessiné, en radians. Son rayon de frappe reste un cercle :
## `Targets.in_circle()` est le seul chemin des coups sans collision.
const SPAN := 1.7
## La fin de sa course, où il se dissout en damier au lieu de pâlir.
const FADE := 0.3
## L'épaisseur de la lame qui vole, en son milieu.
const THICKNESS := 5.0

var _cast: SkillStats
var _author: StatusEffects
var _parts: Array[float] = []
var _tint := Color.WHITE
var _toward := Vector2.RIGHT
var _age := 0.0
## Sa période est sa vie entière : un corps traversé de bout en bout n'est frappé
## qu'une fois.
var _bitten: Targets.Contacts


static func send(
	parent: Node, from_value: Vector2, toward: Vector2, cast: SkillStats, author: StatusEffects
) -> SlashWave:
	var wave := SlashWave.new()
	wave._cast = cast
	wave._author = author
	wave._parts = cast.roll(Game.rng)
	wave._toward = toward.normalized()
	wave._tint = DamageType.COLORS[cast.dominant_nature()]
	wave._bitten = Targets.Contacts.new(cast.duration)
	parent.add_child(wave)
	Settings.veil(wave, Settings.SPELLS)
	# Le nœud ne tourne pas : c'est le dessin qui est fabriqué au cap de sa course,
	# une planche tournée se rééchantillonnant.
	wave.global_position = from_value + wave._toward * START
	return wave


## Pas de lumière ajoutée : la lame est **dessinée**, et une planche cernée ne peut
## pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	_age += delta
	position += _toward * _cast.projectile_speed * delta
	_bitten.advance(delta)
	for target in Targets.in_circle(get_world_2d(), global_position, _cast.radius):
		if _bitten.accepts(target):
			Targets.strike(target, _parts, global_position, _author, _cast)
	queue_redraw()
	if _age >= _cast.duration:
		queue_free()


## Un croissant ouvert vers l'avant, le fil blanc devant : l'arc du geste, détaché
## de la lame. Il se dissout en quatre temps sur la fin de sa course.
func _draw() -> void:
	var fade := clampf((_cast.duration - _age) / (_cast.duration * FADE), 0.0, 1.0)
	var gone := floorf((1.0 - fade) * 4.0) / 4.0
	var turn := Slash.turn_of(_toward.angle())
	Slash.crescent(
		_tint, _cast.radius, THICKNESS, turn, -SPAN * 0.5, SPAN * 0.5, gone, false
	).put(self, -Vector2.from_angle(Slash.angle_of(turn)) * _cast.radius * 0.5)
