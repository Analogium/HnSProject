class_name HitFeedback
extends Node2D

## Le retour visuel d'un coup : le nombre qui s'envole et la gerbe d'éclats. **Un seul
## nœud dessine tout**, sans allocation par coup, et s'enregistre dans `current`. Le
## delta n'est pas dé-scalé : tout se fige pendant un gel.

## Mis à jour depuis _ready / _exit_tree : jamais de référence morte.
static var current: HitFeedback

## Les couleurs hors nature ; celles des éclats viennent de `DamageType.COLORS`.
const CRIT := Color(1.00, 0.78, 0.25)      # l'or, la seule couleur réservée
const PLAYER := Color(1.00, 0.42, 0.38)    # le joueur encaisse : rouge, lisible au coin de l'œil
## Blanc quelle que soit la nature : c'est le total de toutes les parts.
const NUMBER := Color(1.0, 1.0, 1.0)
## Le bleu de la barre d'expérience, éclairci pour tenir sur un sol sombre : le
## gain qui s'envole et la barre qui monte doivent se répondre.
const XP := Color(0.45, 0.68, 1.00)
## Le nom de ce qu'on ramasse. Ce n'est pas la couleur du halo au sol, qui est
## celle de la rareté de l'objet.
const LOOT := Color(0.98, 0.86, 0.45)
## Gris-bleu terne : un non-événement.
const MISS := Color(0.72, 0.78, 0.88)

const NUMBER_LIFE := 0.62
const NUMBER_RISE := -46.0        # vitesse initiale vers le haut, px/s
const NUMBER_DRIFT := 16.0        # dispersion horizontale, pour que deux coups
                                  # simultanés ne se superposent pas
const NUMBER_HEIGHT := 13.0       # au-dessus du centre du corps, à hauteur de tête
const NUMBER_SIZE := 9
const CRIT_SIZE := 13
const GRAVITY := 210.0

## Plus haut et plus lent que les dégâts : deux libellés dans la même bande se mêlent.
const XP_HEIGHT := 22.0
const XP_SIZE := 8
const XP_RISE := 0.7

const PARTICLE_LIFE := 0.30
const PARTICLE_SPEED := 92.0
## Demi-angle du cône, large (~86°) : étroit, la moitié des éclats restait derrière
## le sprite.
const PARTICLE_SPREAD := 1.5
const HIT_PARTICLES := 9
const CRIT_PARTICLES := 16
## Du bord du corps côté attaquant : au centre, l'éclat restait caché sous le flash.
const IMPACT_OFFSET := 7.0

## x, y, vx, vy, âge, durée, côté, r, g, b. La couleur en clair : 38 Ko au pire cas
## mesuré, contre une palette à aligner à la main.
const P_STRIDE := 10

var _p := PackedFloat32Array()


## Une petite classe : ils portent une chaîne et sont peu nombreux.
class FloatingText:
	var pos: Vector2
	var vel: Vector2
	var age := 0.0
	var life: float
	var text: String
	var tint: Color
	var body: int
	## Mesurée une fois : la re-mesurer coûterait plus que tout le dessin.
	var half: float


var _numbers: Array[FloatingText] = []

## Surtout pas Game.rng : décoratif (invariant 3).
var _rng := RandomNumberGenerator.new()

var _font: Font


func _ready() -> void:
	current = self
	_font = ThemeDB.fallback_font
	_rng.randomize()
	set_process(false)


func _exit_tree() -> void:
	if current == self:
		current = null


## **Le point d'entrée**, appelé par Hurtbox : l'éclat part dans l'axe du coup.
func hit(at: Vector2, info: DamageInfo, on_player: bool) -> void:
	var away := at - info.source_position
	away = away.normalized() if away.length_squared() > 0.01 else Vector2.UP

	# Le chiffre seulement : la gerbe reste.
	if Settings.shows_damage(on_player):
		_add_number(at, info.amount, info.is_crit, number_color(info, on_player))
	_add_burst(at - away * IMPACT_OFFSET, away, info.is_crit, _spray_color(info, on_player))

	set_process(true)
	queue_redraw()


## Le rouge quand c'est le joueur qui encaisse, l'or d'un critique, et le blanc
## pour tout le reste : aucune nature, voir `NUMBER`.
static func number_color(info: DamageInfo, on_player: bool) -> Color:
	if on_player:
		return PLAYER
	return CRIT if info.is_crit else NUMBER


## **L'élément gagne sur tout** : le nombre étant blanc, c'est la gerbe qui dit par
## quoi on est touché.
func _spray_color(info: DamageInfo, on_player: bool) -> Color:
	if info.type != DamageType.Kind.PHYSICAL:
		return info.color()
	if on_player:
		return PLAYER
	return CRIT if info.is_crit else info.color()


## Des dégâts sans coup — brûlure d'aura ou d'état —, sans gerbe : rouge sur le
## joueur, blanc sur un ennemi, chacun derrière sa case.
func damage_without_hit(at: Vector2, amount: float, on_player: bool) -> void:
	if amount <= 0.0 or not Settings.shows_damage(on_player):
		return
	_add_number(at, amount, false, PLAYER if on_player else NUMBER)
	set_process(true)
	queue_redraw()


## Un état neuf, sur le joueur seulement : sur soixante-dix ennemis, les pastilles
## suffisent.
func state(at: Vector2, kind: int) -> void:
	_add_label(at + Vector2(0.0, -XP_HEIGHT), StatusEffects.name(kind), XP_SIZE, StatusEffects.color(kind), XP_RISE)
	set_process(true)
	queue_redraw()


## Pas de gerbe : rien n'a été touché. Même case que le chiffre qu'il remplace.
func miss(at: Vector2, on_player: bool) -> void:
	if not Settings.shows_damage(on_player):
		return
	_add_label(
		at + Vector2(0.0, -NUMBER_HEIGHT),
		# Un contexte : « esquive » est aussi la statistique (« evasion »).
		Texts.t("esquive", "coup évité") if on_player else Texts.t("raté"),
		XP_SIZE,
		MISS,
		1.0
	)
	set_process(true)
	queue_redraw()


## Pas d'éclat : ce n'est pas un impact.
func xp_gain(at: Vector2, amount: int) -> void:
	if amount <= 0:
		return
	_add_label(at + Vector2(0.0, -XP_HEIGHT), Texts.t("+%d exp") % amount, XP_SIZE, XP, XP_RISE)
	set_process(true)
	queue_redraw()


## Le nom de l'objet ramassé, au-dessus du joueur.
func loot_gain(at: Vector2, text: String) -> void:
	_add_label(at + Vector2(0.0, -XP_HEIGHT), text, XP_SIZE, LOOT, XP_RISE)
	set_process(true)
	queue_redraw()


func _add_number(at: Vector2, amount: float, is_crit: bool, tint: Color) -> void:
	_add_label(
		at + Vector2(0.0, -NUMBER_HEIGHT),
		"%d" % maxi(roundi(amount), 1),
		CRIT_SIZE if is_crit else NUMBER_SIZE,
		tint,
		1.25 if is_crit else 1.0
	)


## Le libellé flottant générique — dégâts, esquive, expérience, butin. Un seul
## chemin : deux copies divergeraient à la première retouche de la trajectoire.
func _add_label(at: Vector2, text: String, body: int, tint: Color, rise: float) -> void:
	if _font == null:
		return
	var n := FloatingText.new()
	n.pos = at
	n.vel = Vector2(_rng.randf_range(-NUMBER_DRIFT, NUMBER_DRIFT), NUMBER_RISE * rise)
	n.life = NUMBER_LIFE
	n.text = text
	n.tint = tint
	n.body = body
	n.half = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, body).x * 0.5
	_numbers.append(n)


func _add_burst(at: Vector2, away: Vector2, is_crit: bool, tint: Color) -> void:
	var count := CRIT_PARTICLES if is_crit else HIT_PARTICLES
	var base := away.angle()

	for i in count:
		var a := base + _rng.randf_range(-PARTICLE_SPREAD, PARTICLE_SPREAD)
		var speed := PARTICLE_SPEED * _rng.randf_range(0.45, 1.35)
		_p.append_array(PackedFloat32Array([
			at.x, at.y,
			cos(a) * speed, sin(a) * speed,
			0.0, PARTICLE_LIFE * _rng.randf_range(0.7, 1.2),
			# Deux pixels de côté par défaut : à un seul, la gerbe disparaît sur
			# un sol texturé — mesuré à l'image, pas au jugé.
			3.0 if (is_crit and i % 4 == 0) else 2.0,
			tint.r, tint.g, tint.b,
		]))


func _process(delta: float) -> void:
	var particles_alive := _step_particles(delta)
	var numbers_alive := _step_numbers(delta)
	queue_redraw()
	# Éteint hors combat.
	if not particles_alive and not numbers_alive:
		set_process(false)


func _step_particles(delta: float) -> bool:
	var i := 0
	while i < _p.size():
		_p[i + 4] += delta
		if _p[i + 4] >= _p[i + 5]:
			# On ramène la dernière particule sur le trou puis on tronque, au
			# lieu de décaler tout le tableau à chaque mort.
			var last := _p.size() - P_STRIDE
			for k in P_STRIDE:
				_p[i + k] = _p[last + k]
			_p.resize(last)
			continue
		_p[i + 3] += GRAVITY * delta
		_p[i] += _p[i + 2] * delta
		_p[i + 1] += _p[i + 3] * delta
		i += P_STRIDE
	return _p.size() > 0


func _step_numbers(delta: float) -> bool:
	for i in range(_numbers.size() - 1, -1, -1):
		var n := _numbers[i]
		n.age += delta
		if n.age >= n.life:
			_numbers.remove_at(i)
			continue
		# Freiné plus fort que les éclats : le nombre doit monter puis s'arrêter
		# pour se laisser lire, pas retomber comme un débris.
		n.vel.y += GRAVITY * 0.45 * delta
		n.pos += n.vel * delta
	return not _numbers.is_empty()


func _draw() -> void:
	var i := 0
	while i < _p.size():
		var t: float = _p[i + 4] / _p[i + 5]
		# pleine intensité longtemps, puis extinction brutale
		var c := Color(_p[i + 7], _p[i + 8], _p[i + 9], 1.0 - t * t)
		var s: float = _p[i + 6]
		# Coordonnées entières : une particule à cheval sur deux pixels bave et
		# trahit tout de suite le rendu pixel art.
		draw_rect(Rect2(Vector2(roundf(_p[i]), roundf(_p[i + 1])), Vector2(s, s)), c)
		i += P_STRIDE

	if _font == null:
		return

	for n in _numbers:
		var c := n.tint
		# Opaque aux deux premiers tiers, pour être lu.
		c.a = 1.0 - smoothstep(0.62, 1.0, n.age / n.life)
		var pos := Vector2(roundf(n.pos.x - n.half), roundf(n.pos.y))
		# Contour noir : lisible sur tous les sols.
		draw_string_outline(
			_font, pos, n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, n.body, 1, Color(0, 0, 0, c.a)
		)
		draw_string(_font, pos, n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, n.body, c)
