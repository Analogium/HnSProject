class_name HolyPulse
extends Node3D

## L'émanation de Pulsation sacrée : portée par le joueur, elle frappe son cercle à
## chaque période pendant sa durée, puis s'en va. Ce qui la sépare de l'Immolation
## n'est pas le dessin mais le prix : celle-ci ne se paie pas à la seconde, donc elle
## **finit**, et ne s'éteint pas à la touche.
##
## Comme tout ce qui dure, elle ne fige jamais le jeu.

var _player: Player
var _cast: SkillStats
var _age := 0.0
var _strikes := 0
## La Colère divine (jalon 48) : ce que les ondes retenues ont amassé.
var _amassed := 0.0


## L'auteur n'est pas un paramètre : portée par le joueur, elle frappe forcément pour
## lui, et le passer à part laisserait les deux se contredire.
static func emanate(player: Player, cast: SkillStats) -> HolyPulse:
	var pulse := HolyPulse.new()
	pulse._player = player
	pulse._cast = cast
	player.add_child(pulse)
	Settings.veil(pulse, Settings.SPELLS)
	return pulse


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
	var due := _cast.strikes_due(_age)
	while _strikes < due:
		_strike()
		_strikes += 1
	if _age >= _cast.duration and _strikes >= _cast.strikes_over_duration():
		queue_free()


## L'Exaltation : l'onde porte le gain de celles déjà parties. Sous la Colère divine, les
## ondes s'amassent et la dernière part seule, plus large ; l'Extase grandit la dernière. Ce
## que touche une onde : l'Absolution et la Viatique rendent, l'Égide garde, la Purification
## lave, la Communion fait frapper les piliers.
func _strike() -> void:
	var last := _strikes >= _cast.strikes_over_duration() - 1
	var factor := _cast.wave_factor(_strikes)
	var radius := _cast.radius
	var cast := _cast
	if _cast.wrath > 0.0:
		_amassed += factor
		if not last:
			return
		factor = _amassed
		radius *= SkillStats.WRATH_REACH
		if _cast.revelation > 0.0:
			cast = _cast.echoed(1.0)
			cast.status_chance_increase += SkillStats.SURE_STATE
	if last and _cast.ecstasy > 0.0:
		factor *= 1.0 + _cast.ecstasy * 0.01
		radius *= SkillStats.ECSTASY_REACH
	var struck := float(Targets.strike_circle(
		get_world_3d(), global_position, radius, cast, _player.states, 0.0, factor
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

