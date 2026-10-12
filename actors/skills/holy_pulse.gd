class_name HolyPulse
extends Node2D

## L'émanation de Pulsation sacrée : portée par le joueur, elle frappe son cercle à
## chaque période pendant sa durée, puis s'en va. Ce qui la sépare de l'Immolation
## n'est pas le dessin mais le prix : celle-ci ne se paie pas à la seconde, donc elle
## **finit**, et ne s'éteint pas à la touche.
##
## Comme tout ce qui dure, elle ne fige jamais le jeu.

## La part de la période que met une onde à atteindre le bord : au-delà, deux ondes se
## chevaucheraient et le cercle ne se lirait plus.
const SPREADING := 0.8
## Les dernières secondes où le halo au sol s'efface, pour qu'il ne disparaisse pas
## d'un coup sur sa dernière impulsion. Lui seul s'efface : il est tramé, donc fait
## pour ça.
const CLOSING := 0.5
## Les grains d'une onde. **Leur nombre ne change pas** : c'est en s'écartant les
## uns des autres qu'ils disent que l'onde s'ouvre, et ils n'ont donc jamais besoin
## de pâlir.
const GRAINS := 16
## La Colère divine (jalon 48), « grains aspirés » choisis sur planche contre une couronne,
## un anneau qui se resserre, des croix en orbite et une colonne : pendant la litanie, des
## grains glissent du bord vers le porteur. Combien, à quelle cadence, et jusqu'où.
const GATHERED := 10
const GATHER_RATE := 0.8
const GATHER_DEPTH := 0.7
## Où passe la seconde rangée de l'onde lâchée, en part de la première.
const WRATH_ROW := 0.85

var _player: Player
var _cast: SkillStats
var _tint := Color.WHITE
var _age := 0.0
var _strikes := 0
## Depuis la dernière onde partie : c'est elle que l'onde dessine, jusqu'à ce rayon.
var _since := 0.0
var _wave_radius := 0.0
## La Colère divine (jalon 48) : ce que les ondes retenues ont amassé.
var _amassed := 0.0


## L'auteur n'est pas un paramètre : portée par le joueur, elle frappe forcément pour
## lui, et le passer à part laisserait les deux se contredire.
static func emanate(player: Player, cast: SkillStats) -> HolyPulse:
	var pulse := HolyPulse.new()
	pulse._player = player
	pulse._cast = cast
	pulse._tint = DamageType.COLORS[cast.nature]
	player.add_child(pulse)
	Settings.veil(pulse, Settings.SPELLS)
	return pulse


## Pas de lumière ajoutée : les grains sont **dessinés**, et une planche cernée ne
## peut pas être additive — son contour sombre n'y ajoute rien.
func _ready() -> void:
	show_behind_parent = true
	_wave_radius = _cast.radius


## L'Égide ne survit pas à la litanie.
func _exit_tree() -> void:
	if _cast.aegis > 0.0 and is_instance_valid(_player):
		_player.guard(0.0)


## Les impulsions se comptent par `strikes_over_duration()`, la fonction même de
## l'estimation : la fiche et l'émanation ne peuvent pas annoncer deux nombres.
func _physics_process(delta: float) -> void:
	if _player.is_dead:
		queue_free()
		return
	_age += delta
	_since += delta
	var due := _cast.strikes_due(_age)
	while _strikes < due:
		if _strike():
			_since = 0.0
		_strikes += 1
	queue_redraw()
	if _age >= _cast.duration and _strikes >= _cast.strikes_over_duration():
		queue_free()


## L'Exaltation : l'onde porte le gain de celles déjà parties. Sous la Colère divine, les
## ondes s'amassent et la dernière part seule, plus large ; l'Extase grandit la dernière. Ce
## que touche une onde : l'Absolution et la Viatique rendent, l'Égide garde, la Purification
## lave, la Communion fait frapper les piliers. Rend si une onde est partie.
func _strike() -> bool:
	var last := _strikes >= _cast.strikes_over_duration() - 1
	var factor := _cast.wave_factor(_strikes)
	var radius := _cast.radius
	var cast := _cast
	if _cast.wrath > 0.0:
		_amassed += factor
		if not last:
			return false
		factor = _amassed
		radius *= SkillStats.WRATH_REACH
		if _cast.revelation > 0.0:
			cast = _cast.echoed(1.0)
			cast.status_chance_increase += SkillStats.SURE_STATE
	if last and _cast.ecstasy > 0.0:
		factor *= 1.0 + _cast.ecstasy * 0.01
		radius *= SkillStats.ECSTASY_REACH
	_wave_radius = radius
	var struck := float(Targets.strike_circle(
		get_world_2d(), global_position, radius, cast, _player.states, 0.0, factor
	).size())
	_player.heal(_cast.life_on_hit * struck)
	_player.gain_mana(_cast.mana_on_hit * struck)
	if _cast.aegis > 0.0:
		_player.guard(minf(_cast.aegis * struck, SkillStats.AEGIS_MOST))
	if _cast.purification > 0.0:
		_player.states.shorten(_cast.purification * 0.01)
	if _cast.communion > 0.0:
		for pillar in SacredPillar.standing_for(_player.states):
			if pillar.global_position.distance_to(global_position) <= radius + pillar.reach():
				pillar.commune(_cast.communion * 0.01)
	return true


## Une onde de grains qui part du porteur à chaque impulsion, et le halo tramé qui
## dit jusqu'où elle mord. L'onde **arrive au bord**, elle ne le dépasse pas : une
## onde qui sort du cercle promettrait une portée que le coup n'a pas.
func _draw() -> void:
	var fade := clampf((_cast.duration - _age) / CLOSING, 0.0, 1.0)
	EffectForge.put_scorch(self, _tint, maxi(roundi(_cast.radius), 1), fade)

	if _cast.wrath > 0.0 and _strikes < _cast.strikes_over_duration():
		for i in GATHERED:
			var inward := fmod(_age * GATHER_RATE + float(i) * 0.37, 1.0)
			var at := Vector2.from_angle(TAU * float(i) / float(GATHERED)) \
					* _cast.radius * (1.0 - GATHER_DEPTH * inward)
			Holy.spark(self, at, _tint, fade)
		return
	var out := clampf(_since / (_cast.period * SPREADING), 0.0, 1.0) if _cast.period > 0.0 else 1.0
	if out >= 1.0:
		return
	for i in GRAINS:
		var at := Vector2.from_angle(TAU * float(i) / float(GRAINS) + out) * _wave_radius * out
		Holy.spark(self, at, _tint, fade)
		# L'onde lâchée par la Colère porte toutes les autres : une seconde rangée, en quinconce.
		if _cast.wrath > 0.0:
			var behind := Vector2.from_angle(TAU * (float(i) + 0.5) / float(GRAINS) + out)
			Holy.spark(self, behind * _wave_radius * out * WRATH_ROW, _tint, fade)
