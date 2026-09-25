class_name Explosion
extends Node2D

## L'explosion d'une boule de feu : elle frappe une fois ce qui est dans son rayon,
## sauf la cible directe qui a déjà reçu le coup, puis s'efface.
##
## **Elle naît en différé et frappe à sa première image de physique** : l'impact
## arrive dans un rappel de collision, où rien ne doit entrer dans l'arbre et où
## l'espace physique refuse les requêtes (invariant 4).

const LIFETIME := 0.3
## Le brasier dure **moitié moins** que les autres souffles. Tenue trois dixièmes
## de seconde, sa couronne de langues se mettait à ressembler à un feu de camp
## posé là — c'est un coup, pas un foyer. La nova de glace garde les trois
## dixièmes : le froid ne souffle pas, il prend, et ce qu'il gèle doit se voir.
const BLAZE_LIFE := 0.16
const SPARKS := 8
## La couronne de matière du souffle peint — langues de feu ou cristaux de glace.
## Onze, parce que dessinées elles doivent **se toucher** pour faire une onde.
const CROWN := 11
## Les éclats que la nova projette devant elle, sur le cercle qui mord : un par
## huit pixels de circonférence, sinon l'anneau se lit comme un collier.
const CHIP_STEP := 8.0

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
	# Le feu, la glace et la nécrose sont **dessinés**, et une planche cernée ne peut
	# pas être additive : son contour sombre n'y ajoute rien. Les natures encore
	# tracées restent en lumière ajoutée.
	if not _is_painted():
		material = ArtPalette.ADDITIVE


func _physics_process(delta: float) -> void:
	if not _has_struck:
		_has_struck = true
		for target in Targets.in_circle(get_world_2d(), global_position, _radius):
			if target.get_instance_id() != _excluded:
				Targets.strike(target, _parts, global_position, _author, _cast)
	_age += delta
	queue_redraw()
	if _age >= _life_span():
		queue_free()


## Trois souffles peints — le brasier, la nova, le mur de gaz de la nécrose, qui se
## rastérise d'un tenant (`Necrotic.miasma()`) — et, pour tout le reste, l'onde tracée
## qui suit.
##
## Pas de disque plein qui dure : en mélange additif sur un sol sombre, un orange
## peu opaque sortait **brun**, et l'explosion se lisait comme une flaque. Le cœur
## est vif et s'éteint vite, l'onde et les étincelles portent le reste.
##
## Le cœur part à alpha plein : c'est lui qui passe le seuil de glow, donc ce qui
## fait qu'une explosion **éclaire** au lieu d'être un rond coloré.
func _draw() -> void:
	var k := clampf(_age / _life_span(), 0.0, 1.0)
	var fade := 1.0 - k
	# Peinte, l'onde est à son plein rayon au bout d'un cinquième de sa vie — trois
	# centièmes de seconde : c'est ce qui la rend instantanée plutôt que soufflée.
	var opened: float = minf(k * 5.0, 1.0) if _nature() == DamageType.Kind.FIRE else minf(k * 1.6, 1.0)
	var r := _radius * (1.0 - pow(1.0 - opened, 3.0))
	match _nature():
		DamageType.Kind.FIRE:
			_blaze(r, k, fade)
			return
		DamageType.Kind.COLD:
			_rime(r, k, fade)
			return
		DamageType.Kind.NECROTIC:
			Necrotic.put_band(self, Necrotic.miasma(_tint, _radius, k), Vector2.ZERO)
			return

	# **En additif, c'est le bleu qui blanchit.** Le blanc du feu en porte 0,78 : à
	# 0,55 de mélange, le souffle montait à 0,67 de bleu une fois posé sur le sol et
	# sortait gris. À 0,35 il reste de sa couleur.
	var lit := _tint.lerp(Color.WHITE, 0.35)
	var heart := clampf(1.0 - k * 2.5, 0.0, 1.0)
	if heart > 0.0:
		# **Teinté large, blanc minuscule** — la règle de l'éclat de la foudre, et pour
		# la même raison. Serré, le cœur reste un éclat ; large, c'est une fumée.
		Glow.draw_blob(self, Vector2.ZERO, maxf(r * 0.5, 1.0), Color(lit, heart * 0.85))
		Glow.draw_blob(self, Vector2.ZERO, maxf(r * 0.18, 1.0), Color(_tint.lerp(Color.WHITE, 0.8), heart))
	Glow.draw_ring(self, Vector2.ZERO, maxf(r, 0.5), Color(_tint, 0.85 * fade * fade))
	for i in SPARKS:
		var d := Vector2.from_angle(TAU * float(i) / float(SPARKS) + 0.3)
		Glow.draw_streak(self, d * (r * 1.1 + 8.0 * k), d * (r * 0.85), 3.0, Color(lit, 0.9 * fade))


## Le souffle du feu, **entièrement dessiné** : un éclat en étoile au centre, et
## une couronne de langues qui s'écarte avec l'onde. Pas d'anneau tracé — choisi
## sur planche : c'est la même matière que le brasier, et deux façons de peindre le
## feu dans le même écran ne se liraient pas comme une seule.
##
## Rien ne dépasse le rayon qui mord : les langues **sont** l'onde.
func _blaze(r: float, k: float, fade: float) -> void:
	var tint := _tint
	_ground(r, fade)

	# **Pleine opacité jusqu'aux deux tiers, puis rien.** Une couronne qui se fond
	# progressivement se lit comme un feu qui meurt ; une qui s'éteint d'un coup se
	# lit comme un souffle. C'est la même raison qui donne son battement à la foudre.
	var flames := EffectForge.flames(tint)
	var half := Vector2(EffectForge.FLAME_WIDTH * 0.5, EffectForge.FLAME_HEIGHT - 2)
	var crown := clampf((1.0 - k) * 3.0, 0.0, 1.0)
	for i in CROWN:
		var at := Vector2.from_angle(TAU * float(i) / float(CROWN) + 0.2) * r * 0.86
		var frame := int(_age * EffectForge.FLAME_HZ * 2.0 + float(i) * 1.7) % flames.size()
		draw_texture_rect(
			flames[frame], Rect2(EffectForge.snap(self, at - half), _size_of(flames[frame])),
			false, Color(1.0, 1.0, 1.0, crown)
		)

	# L'éclat est là **à la première image** et tient le premier tiers : c'est lui
	# qui fait l'instantané, la couronne ne fait que l'habiller.
	var burst := EffectForge.flashes(tint)
	var step := int(_age * EffectForge.FLASH_HZ)
	if step < burst.size():
		var side := Vector2.ONE * float(EffectForge.FLASH_SIZE)
		draw_texture_rect(burst[step], Rect2(EffectForge.snap(self, -side * 0.5), side), false)


## La nova de glace, **entièrement dessinée** : un anneau d'éclats qui file vers
## l'extérieur, et les cristaux qu'il laisse debout derrière lui. Pas d'éclat
## central — le givre porte déjà 0,88 de luminance et déborde tout seul, là où le
## feu a besoin d'un cœur presque blanc pour passer le seuil.
##
## Le froid ne souffle pas, il **prend** : l'anneau ne vit que pendant qu'il
## s'ouvre, et ce qui reste à l'écran est ce qu'il a gelé au passage.
func _rime(r: float, k: float, fade: float) -> void:
	_ground(r, fade)

	var race := clampf(1.0 - k * 2.5, 0.0, 1.0)
	if race > 0.0:
		var chips := maxi(int(TAU * r / CHIP_STEP), 1)
		for i in chips:
			var angle := TAU * float(i) / float(chips)
			Frost.chip(self, Vector2.from_angle(angle) * r, angle, _tint, race)

	# Les cristaux sortent de terre dans le premier quart, tiennent, puis y
	# redescendent : c'est l'inverse de la couronne de langues, qui naît entière et
	# se coupe net. Ni l'une ni l'autre ne s'éteint en pâlissant.
	var out := minf(clampf(k * 4.0, 0.0, 1.0), clampf(fade * 3.0, 0.0, 1.0))
	for i in CROWN:
		var foot := Vector2.from_angle(TAU * float(i) / float(CROWN) + 0.2) * r * 0.78
		Frost.raise_spike(self, foot, i % 2 == 0, out, _tint)


## La trace au sol du souffle peint : tramée, elle s'efface avec lui.
func _ground(r: float, fade: float) -> void:
	draw_texture_rect(
		EffectForge.scorch(_tint, maxi(int(round(r)), 1)),
		Rect2(EffectForge.snap(self, -Vector2(round(r), round(r))), Vector2.ONE * (round(r) * 2.0 + 1.0)),
		false, Color(1.0, 1.0, 1.0, fade)
	)


## Peint — fait de planches cernées — ou tracé en polygones : c'est ce qui décide
## du mélange, et les deux moitiés de `_draw()`.
func _is_painted() -> bool:
	return _nature() in [DamageType.Kind.FIRE, DamageType.Kind.COLD, DamageType.Kind.NECROTIC]


## Combien de temps ce souffle s'affiche.
func _life_span() -> float:
	return BLAZE_LIFE if _nature() == DamageType.Kind.FIRE else LIFETIME


func _size_of(tex: Texture2D) -> Vector2:
	return Vector2(tex.get_width(), tex.get_height())


## −1 pour une explosion posée sans geste résolu : les tests en posent.
func _nature() -> int:
	return _cast.dominant_nature() if _cast != null else -1
