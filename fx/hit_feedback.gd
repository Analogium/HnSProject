class_name HitFeedback
extends Node2D

## Le retour visuel d'un coup : le nombre de dégâts qui s'envole, et l'éclat de
## pixels projeté au point d'impact. C'est ce que le document de cadrage met en
## tête de l'après-jalon 1 — « le feedback qui manque le plus après le hit-stop ».
##
## Un seul nœud dessine tout, sur le principe de l'EnemyManager. Un nœud par
## nombre et par particule voudrait dire une allocation par coup, alors qu'un
## swing peut toucher cinq ennemis à la fois et qu'il y en a soixante-dix à
## l'écran ; ici un coup n'ajoute que des flottants dans un tableau.
##
## Le nœud s'enregistre lui-même dans HitFeedback.current : une scène n'a qu'à
## le contenir, il n'y a rien à câbler. C'est aussi ce qui évite de le mettre
## sur l'autoload Game — Game est un Node, il ne sait pas dessiner, et le
## déclarer là créerait une dépendance croisée entre les deux scripts.
##
## Le delta n'est pas dé-scalé : pendant le hit-stop les nombres et les éclats
## se figent avec le reste du jeu, exactement comme la trace du swing.

## Le nœud vivant de la scène courante, ou null hors combat. Statique et non
## posé par la scène : le mettre à jour depuis _ready / _exit_tree garantit
## qu'il ne reste jamais une référence morte après un changement de scène.
static var current: HitFeedback

## Teintes, indexées par les constantes T_* ci-dessous. Un index plutôt qu'une
## couleur stockée par particule : trois flottants de moins par particule, et
## la palette du feedback tient en un seul endroit.
const T_HIT := 0
const T_CRIT := 1
const T_PLAYER := 2
const T_XP := 3
const T_LOOT := 4
const TINTS := [
	Color(1.00, 0.98, 0.88),   # coup ordinaire : le blanc chaud de la lame
	Color(1.00, 0.78, 0.25),   # critique : l'or, la seule couleur réservée
	Color(1.00, 0.42, 0.38),   # le joueur encaisse : rouge, lisible au coin de l'œil
	# Le bleu de la barre d'expérience, éclairci pour tenir sur un sol sombre :
	# le gain qui s'envole et la barre qui monte doivent se répondre.
	Color(0.45, 0.68, 1.00),
	# Le doré du halo posé sous les objets au sol : ramasser et repérer sont la
	# même information, elles partagent la couleur.
	Color(0.98, 0.86, 0.45),
]

const NUMBER_LIFE := 0.62
const NUMBER_RISE := -46.0        # vitesse initiale vers le haut, px/s
const NUMBER_DRIFT := 16.0        # dispersion horizontale, pour que deux coups
                                  # simultanés ne se superposent pas
const NUMBER_HEIGHT := 13.0       # au-dessus du centre du corps, à hauteur de tête
const NUMBER_SIZE := 9
const CRIT_SIZE := 13
const GRAVITY := 210.0

## Le gain d'expérience part plus haut et monte moins vite que les dégâts : il
## arrive au moment où le dernier coup s'affiche encore, et deux libellés dans
## la même bande à la même vitesse se lisent comme un seul bloc illisible.
const XP_HEIGHT := 22.0
const XP_SIZE := 8
const XP_RISE := 0.7

const PARTICLE_LIFE := 0.30
const PARTICLE_SPEED := 92.0
## Demi-angle du cône, en radians. Large (~86°) et non serré : un cône étroit
## dans l'axe du coup envoie la moitié des éclats derrière le sprite, où ils ne
## se voient pas. Ouvert, la gerbe déborde tout de suite de la silhouette.
const PARTICLE_SPREAD := 1.5
const HIT_PARTICLES := 9
const CRIT_PARTICLES := 16
## L'éclat ne part pas du centre du corps mais de son bord, côté attaquant.
## Au centre, il passait ses cent premières millisecondes caché derrière le
## sprite — et sous le flash blanc, qui couvre justement ce moment-là.
const IMPACT_OFFSET := 7.0

## x, y, vx, vy, âge, durée, côté du carré, index de teinte.
const P_STRIDE := 8

var _p := PackedFloat32Array()


## Un libellé qui s'envole. Une petite classe et non un tableau indexé comme les
## particules : ils portent une chaîne, il y en a au plus quelques dizaines là où
## les particules se comptent par centaines, et `n.half` se relit là où `n[9]`
## oblige à compter les colonnes.
class FloatingText:
	var pos: Vector2
	var vel: Vector2
	var age := 0.0
	var life: float
	var text: String
	## Index dans TINTS, et non une couleur : la palette tient en un seul endroit.
	var tint: int
	var body: int
	## Demi-largeur du texte, mesurée une fois à la création : la re-mesurer à
	## chaque image coûterait plus cher que tout le reste du dessin.
	var half: float


var _numbers: Array[FloatingText] = []

## Tirage propre à l'effet. Surtout pas Game.rng : la dispersion d'un éclat est
## purement décorative et ne doit pas décaler le hasard dont dépend le reste.
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


## Le point d'entrée unique, appelé par Hurtbox — donc par tous les coups du jeu.
## at est le point touché, info.source_position dit d'où vient le coup : l'éclat
## part dans l'axe, ce qui suffit à faire lire la direction sans autre donnée.
func hit(at: Vector2, info: DamageInfo, on_player: bool) -> void:
	var away := at - info.source_position
	away = away.normalized() if away.length_squared() > 0.01 else Vector2.UP

	var tint := T_PLAYER if on_player else (T_CRIT if info.is_crit else T_HIT)
	_add_number(at, info.amount, info.is_crit, tint)
	_add_burst(at - away * IMPACT_OFFSET, away, info.is_crit, tint)

	set_process(true)
	queue_redraw()


## Le gain d'expérience d'un ennemi qui tombe. Pas d'éclat de pixels : ce n'est
## pas un impact, et une gerbe sur un corps déjà mort brouillerait le coup
## suivant.
func xp_gain(at: Vector2, amount: int) -> void:
	if amount <= 0:
		return
	_add_label(at + Vector2(0.0, -XP_HEIGHT), "+%d exp" % amount, XP_SIZE, T_XP, XP_RISE)
	set_process(true)
	queue_redraw()


## Le nom de l'objet ramassé, au-dessus du joueur.
func loot_gain(at: Vector2, text: String) -> void:
	_add_label(at + Vector2(0.0, -XP_HEIGHT), text, XP_SIZE, T_LOOT, XP_RISE)
	set_process(true)
	queue_redraw()


func _add_number(at: Vector2, amount: float, is_crit: bool, tint: int) -> void:
	_add_label(
		at + Vector2(0.0, -NUMBER_HEIGHT),
		"%d" % maxi(roundi(amount), 1),
		CRIT_SIZE if is_crit else NUMBER_SIZE,
		tint,
		1.25 if is_crit else 1.0
	)


## Le libellé flottant générique — dégâts comme expérience. Un seul chemin :
## deux copies divergeraient à la première retouche de la trajectoire.
func _add_label(at: Vector2, text: String, body: int, tint: int, rise: float) -> void:
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


func _add_burst(at: Vector2, away: Vector2, is_crit: bool, tint: int) -> void:
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
			float(tint),
		]))


func _process(delta: float) -> void:
	var particles_alive := _step_particles(delta)
	var numbers_alive := _step_numbers(delta)
	queue_redraw()
	# On s'éteint dès qu'il n'y a plus rien : hors combat, ce nœud ne doit rien
	# coûter du tout.
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
		var c: Color = TINTS[int(_p[i + 7])]
		c.a = 1.0 - t * t   # pleine intensité longtemps, puis extinction brutale
		var s: float = _p[i + 6]
		# Coordonnées entières : une particule à cheval sur deux pixels bave et
		# trahit tout de suite le rendu pixel art.
		draw_rect(Rect2(Vector2(roundf(_p[i]), roundf(_p[i + 1])), Vector2(s, s)), c)
		i += P_STRIDE

	if _font == null:
		return

	for n in _numbers:
		var c: Color = TINTS[n.tint]
		# Le nombre reste opaque les deux premiers tiers : s'il s'efface trop
		# tôt on ne le lit pas, et un nombre illisible ne sert à rien.
		c.a = 1.0 - smoothstep(0.62, 1.0, n.age / n.life)
		var pos := Vector2(roundf(n.pos.x - n.half), roundf(n.pos.y))
		# Contour noir : sur un sol clair comme sur un mur sombre, le nombre doit
		# tenir sans qu'on ait à choisir sa couleur en fonction du décor.
		draw_string_outline(
			_font, pos, n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, n.body, 1, Color(0, 0, 0, c.a)
		)
		draw_string(_font, pos, n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, n.body, c)
