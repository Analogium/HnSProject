class_name Explosion
extends Node2D

## L'explosion d'une boule de feu : elle frappe une fois ce qui est dans son rayon,
## sauf la cible directe qui a déjà reçu le coup, puis s'efface.
##
## **Elle naît en différé et frappe à sa première image de physique** : l'impact
## arrive dans un rappel de collision, où rien ne doit entrer dans l'arbre et où
## l'espace physique refuse les requêtes (invariant 4).

const LIFETIME := 0.3
const SPARKS := 8
## Les panaches de matière — langues ou esquilles — que le souffle pousse : moins
## nombreux que les étincelles, qui partent à plat. Deux gestes, deux directions,
## c'est ce qui donne du volume.
const PLUMES := 5

var _parts: Array[float] = []
var _author: StatusEffects
var _cast: SkillStats
var _radius := 0.0
## L'identifiant et non la référence : la cible directe peut être libérée avant que
## l'explosion ne frappe, et une référence libérée ne se compare plus.
var _excluded := 0
var _tint := Color.WHITE
var _age := 0.0
var _has_struck := false


static func put(
	parent: Node, point: Vector2, parts: Array[float], radius: float, excluded: Hurtbox, tint: Color,
	author: StatusEffects, cast: SkillStats
) -> Explosion:
	var e := Explosion.new()
	e._author = author
	e._cast = cast
	e._parts = parts.duplicate()
	e._radius = radius
	e._excluded = excluded.get_instance_id() if excluded != null else 0
	e._tint = tint
	DeferredTree.add_deferred(parent, e, point)
	return e


func _ready() -> void:
	z_index = 3
	material = ArtPalette.ADDITIVE


func _physics_process(delta: float) -> void:
	if not _has_struck:
		_has_struck = true
		for target in Targets.in_circle(get_world_2d(), global_position, _radius):
			if target.get_instance_id() != _excluded:
				Targets.strike(target, _parts, global_position, _author, _cast)
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


## Pas de disque plein qui dure : en mélange additif sur un sol sombre, un orange
## peu opaque sortait **brun**, et l'explosion se lisait comme une flaque. Le cœur
## est vif et s'éteint vite, l'onde et les étincelles portent le reste.
##
## Le cœur part à alpha plein : c'est lui qui passe le seuil de glow, donc ce qui
## fait qu'une explosion **éclaire** au lieu d'être un rond coloré.
func _draw() -> void:
	var k := clampf(_age / LIFETIME, 0.0, 1.0)
	var fade := 1.0 - k
	var r := _radius * (1.0 - pow(1.0 - minf(k * 1.6, 1.0), 3.0))
	# **En additif, c'est le bleu qui blanchit.** Le blanc du feu en porte 0,78 : à
	# 0,55 de mélange, le souffle montait à 0,67 de bleu une fois posé sur le sol et
	# sortait gris. À 0,35 il reste de sa couleur.
	var lit := _tint.lerp(_glint(), 0.35)
	var heart := clampf(1.0 - k * 2.5, 0.0, 1.0)
	if heart > 0.0:
		# **Teinté large, blanc minuscule** — la règle de l'éclat de la foudre, et pour
		# la même raison. Serré, le cœur reste un éclat ; large, c'est une fumée.
		Glow.draw_blob(self, Vector2.ZERO, maxf(r * 0.5, 1.0), Color(lit, heart * 0.85))
		Glow.draw_blob(self, Vector2.ZERO, maxf(r * 0.18, 1.0), Color(_core(), heart))
	Glow.draw_ring(self, Vector2.ZERO, maxf(r, 0.5), Color(_tint, 0.85 * fade * fade))
	for i in SPARKS:
		var d := Vector2.from_angle(TAU * float(i) / float(SPARKS) + 0.3)
		Glow.draw_streak(self, d * (r * 1.1 + 8.0 * k), d * (r * 0.85), 3.0, Color(lit, 0.9 * fade))
	_matter(r, k, fade)


## La matière de la déflagration, qui n'appartient qu'à deux natures : le feu monte
## en langues, le froid retombe en esquilles. Les autres n'ont que l'onde — une nova
## nécrotique qui jetterait des flammes mentirait sur ce qu'elle fait.
##
## Elle arrive **après** l'onde, le cinquième de la vie : ensemble, ce ne serait
## qu'une seule bouffée.
func _matter(r: float, k: float, fade: float) -> void:
	var nature := _nature()
	if nature != DamageType.Kind.FIRE and nature != DamageType.Kind.COLD:
		return
	var grown := minf(k * 2.2, 1.0) * fade
	for i in PLUMES:
		var turn := TAU * float(i) / float(PLUMES) + 0.7
		# Sur l'anneau et pas au centre : la matière naît là où le souffle mord, et
		# empilée sur le cœur elle ne fait qu'ajouter du blanc.
		var foot := Vector2.from_angle(turn) * r * 0.5
		if nature == DamageType.Kind.FIRE:
			Fire.draw_tongue(
				self, foot, Vector2.UP, r * (0.60 + 0.45 * k) * (1.0 + 0.2 * Fire.breath(_age, i)),
				r * 0.14, _tint, grown, r * 0.12 * Fire.breath(_age * 0.7, i)
			)
		else:
			# Les esquilles fuient le centre : une nova de glace jette ses éclats, elle
			# ne les fait pas pousser sur place.
			Frost.draw_shard(
				self, foot, Vector2.from_angle(turn), r * (0.35 + 0.30 * k),
				r * 0.16, _tint, grown, r * 0.06
			)


## Le point le plus clair du souffle, par nature. Chaque matière sait de combien
## elle a besoin d'être éclaircie pour déborder, et c'est mesuré chez elle : le feu
## à 0,92 de blanc chaud (0,899 en dessous, sous le seuil), le froid à moitié
## seulement, parce que son cyan porte déjà 0,81 de luminance.
func _core() -> Color:
	match _nature():
		DamageType.Kind.FIRE:
			return Fire.heart(_tint)
		DamageType.Kind.COLD:
			return Frost.rim(_tint)
		_:
			return _tint.lerp(Color.WHITE, 0.8)


## Le blanc vers lequel le souffle et ses étincelles tirent, par nature.
func _glint() -> Color:
	match _nature():
		DamageType.Kind.FIRE:
			return Fire.WARM
		DamageType.Kind.COLD:
			return Frost.RIME
		_:
			return Color.WHITE


## −1 pour une explosion posée sans geste résolu : les tests en posent.
func _nature() -> int:
	return _cast.dominant_nature() if _cast != null else -1
