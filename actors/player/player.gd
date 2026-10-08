class_name Player
extends CharacterBody2D

signal died
## Pour le HUD, par signal : vie et mana ne bougent qu'aux coups et à la régénération.
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal xp_changed(current: int, needed: int, level: int)
signal leveled_up(level: int)
## Un nœud de l'arbre pris ou repris, ou un point d'arbre gagné.
signal passives_changed
## Un geste entretenu s'est allumé ou éteint : le bandeau en montre les icônes.
signal buffs_changed
signal equipment_changed
## Une gorgée prise ou finie, des charges gagnées : le bandeau des flacons.
signal flasks_changed

const ACCEL := 0.25          # réactivité au démarrage
const FRICTION := 0.35       # freinage à l'arrêt
const ATTACK_MOVE_MULT := 0.4  # on ralentit pendant le coup, on ne fige pas

## La ressource du disque, **jamais modifiée** (invariant 2).
@export var base_stats: CharacterStats

## Le personnage persiste : ni la mort ni le changement de zone ne remettent la
## progression à zéro.
const XP_BASE := 40.0
const XP_POWER := 1.5
## Au plafond, l'expérience ne s'accumule plus : `xp_to_next` vaut zéro.
const MAX_LEVEL := 100
## Soin partiel à la montée : complet, on chercherait à monter au milieu d'un paquet.
const LEVEL_HEAL := 0.30

## Les attaques de départ ne s'apprennent pas : leur table n'a qu'une entrée.
const BASIC_ATTACK_POINTS := 1

## Jusqu'où un nuage ou un serpent se posent du personnage. Au-delà du curseur, on
## poserait hors de l'écran à la manette ; en deçà, on se jetterait dans le paquet.
const PLACEMENT_RANGE := 140.0
## Ce qui distingue une frappe lourde d'un coup d'épée au toucher, en plus du dessin.
const STRIKE_SHAKE := 2.0
## De combien on recule le long de la visée quand l'arrivée d'une ruée est prise. Huit
## pixels : plus fin ne se voit pas, plus gros fait rater une embrasure.
const LANDING_STEP := 8.0
## Où une frappe vive s'arrête devant sa cible, de centre à centre : les deux corps se
## touchent sans se chevaucher.
const LUNGE_REACH := 14.0
## Où tombe le Brise-sol, devant le corps : au bout de la hitbox (20 px), là où la lame
## frapperait.
const SLAM_REACH := 24.0

## Ce qu'une mise à mort verse à chaque flacon porté, plus par affixe de l'ennemi : une
## élite remplit plus vite, comme la rareté d'un monstre de PoE. Provisoire.
const CHARGES_PER_KILL := 1.0
const CHARGES_PER_AFFIX := 1.0

## Durée pendant laquelle la hitbox est active. Réglable à chaud depuis l'arène.
@export var swing_duration: float = 0.12

@export_group("Tir")
## Moins de dégâts que le corps à corps, sans obliger à entrer dans la mêlée.
@export var bolt_scene: PackedScene
## Le tir de Boule de feu, qui explose à l'impact.
@export var orb_scene: PackedScene
## Le tir du Projectile élémentaire : une comète dessinée, de la teinte de l'élément.
@export var comet_scene: PackedScene
## Secousse de caméra à l'impact. 0 pour la couper.
@export var shake_amount: float = 2.0

@onready var sprite: ActorSprite = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_bar: HealthBar = $HealthBar
@onready var attack_pivot: Node2D = $AttackPivot
@onready var hitbox: Area2D = $AttackPivot/Hitbox
@onready var swing_arc: SwingArc = $AttackPivot/SwingArc
@onready var camera: Camera2D = $Camera2D
## Le corps, pour chercher où une ruée peut atterrir.
@onready var body_shape: CollisionShape2D = $CollisionShape2D

## Où atterrissent les tirs du joueur. Posé par la scène (zone ou arène) ;
## à défaut, ils naissent à côté du joueur.
var projectile_parent: Node2D

## La fiche de travail — disque, attributs, équipement —, **recalculée d'un bloc** et
## jamais retouchée : sinon les bonus s'accumulent.
var stats: CharacterStats

var level := 1
var xp := 0
var xp_to_next := 40

## Partagé et jamais écrit ; une variable pour qu'un test y pose un petit arbre.
var passive_tree := PassiveTree.shared()
## Les nœuds pris, et rien d'autre : les points restants se déduisent du niveau.
var passives := PackedStringArray()

## Le sac porte son propre signal `changed`.
var inventory := Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)

## Ce qui est porté, par emplacement. Un Item par entrée, ou rien.
var equipment := {}

## L'interface s'y branche, elle ne les possède pas.
var rack := Rack.new()
var bar := SkillBar.starting()

## Le manuel de départ a-t-il déjà été donné à ce personnage.
var manual_given := false

## Ce que l'équipement donne aux compétences d'un mot-clé, reconstruit par
## `recompute_stats()` et lu à chaque lancer.
var skill_mods: Array[StatMod] = []

var health: float
var mana: float
var is_dead := false
## Ses états, comme ceux d'un ennemi.
var states := StatusEffects.new()
var facing := Vector2.RIGHT
## Une recharge par case : deux compétences voisines s'enchaînent.
var _recharges := PackedFloat32Array()
## Ce que valait cette recharge au lancer, pour le voile de la barre. Gardé plutôt que
## recalculé : un nœud peut avoir changé l'intervalle (jalon 23), et `Skill.interval()`
## ne connaît pas les nœuds.
var _recharge_totals := PackedFloat32Array()
## Les cases tenues depuis un appui **né en jeu** : sinon le clic qui choisit une
## compétence dans le menu de la barre la lancerait aussitôt.
var _held: Array[bool] = []
## Les parts du coup en cours, **tirées une fois au départ du geste** : tout l'arc
## reçoit la même valeur.
var _hit_parts: Array[float] = []
var _hit_cast: SkillStats
var _hit_shake := 0.0
var _is_swinging := false
## Les gestes entretenus allumés, par identifiant de compétence : une aura et les
## buffs. Leurs nœuds vivent sous le joueur ; le dictionnaire dit lequel répond à
## quelle case.
var _lit := {}
## Le prochain tour des compétences qui changent de nature à chaque lancer, par
## identifiant. Jamais sauvegardé : on recommence par le premier élément.
var _turns := {}
var _costs := {}
## La nature du dernier sort qui a frappé, pour les charges d'Harmonie ; −1 avant le premier.
var _last_spell_nature := -1
## L'identifiant du geste entretenu qui enferme son lanceur, ou vide. Tenu à jour à
## l'allumage plutôt que relu à chaque image : il est lu par le déplacement.
var _bound := ""
var _crown: BladeCrown
## Ce que la brûlure d'Immolation a pris depuis le dernier chiffre affiché.
var _burn_to_show := StatusEffects.Pack.new()
## La Renaissance (jalon 42) : les secondes avant qu'elle puisse revenir. Les Cendres du
## phénix : celles qui leur restent, que le brasier lit.
var _rebirth_wait := 0.0
var phoenix_ashes := 0.0
## La Seconde foulée : par case, le temps qui reste pour relancer la ruée sans payer.
var _strides := {}
## L'Emballement (jalon 43) : les cumuls, le temps depuis le dernier lancer qui en porte ;
## le Plein régime compte les tirs à plein cumul.
var _ramps := 0
var _ramp_idle := INF
var _throttle := 0
## La Tension accumulée (jalon 43) : le « plus » que porte le prochain sort de foudre, et le
## temps qu'il reste pour le lancer.
var _tension := 0.0
var _tension_left := 0.0
## Le Condensateur (jalon 43) : les morsures de charges comptées, et ce qu'elles ont mordu,
## que la Décharge totale rend d'un coup. La Cage de Faraday : son reste, son attente.
var _condensed := 0
var _condensed_power := 0.0
var _faraday_left := 0.0
var _faraday_wait := 0.0
var _already_hit: Array[Node] = []
## Souris = visée au curseur, manette = visée dans la direction du stick.
var _aim_with_mouse := true


## Une gorgée en cours. Deux gorgées de vie se cumulent, comme dans PoE 1.
class Sip:
	var flask: Item
	var left: float
	var life_per_second: float
	var mana_per_second: float

var _sips: Array[Sip] = []


func _ready() -> void:
	camera.zoom = Vector2.ONE * Game.WORLD_ZOOM
	Settings.veil(swing_arc, Settings.SPELLS)
	# Sans .tres assigné on part sur des valeurs par défaut plutôt que de planter.
	if base_stats == null:
		base_stats = CharacterStats.new()
	_recharges.resize(SkillBar.SLOT_COUNT)
	_recharge_totals.resize(SkillBar.SLOT_COUNT)
	_held.resize(SkillBar.SLOT_COUNT)
	recompute_stats()
	xp_to_next = _needed_for(level)
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hurtbox.damaged.connect(_on_damaged)
	hurtbox.states = states
	states.struck.connect(_on_struck)
	states.slew.connect(_on_slew)
	states.change.connect(_show_states)
	states.reached.connect(_announce_state)
	states.heal.connect(heal)


## La souris sert-elle à viser ? Pas déduit de sa position, qui bouge avec la caméra.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_aim_with_mouse = true
	elif event is InputEventJoypadButton:
		_aim_with_mouse = false
	elif event is InputEventJoypadMotion:
		# Seuil large : sinon la dérive du stick au repos rebascule la visée.
		if absf((event as InputEventJoypadMotion).axis_value) > 0.5:
			_aim_with_mouse = false


## Un champ de texte qui a le focus garde ses chiffres : la recherche de l'arbre ne boit pas.
## Une case ne s'arme qu'ici : un clic que l'interface a pris n'arrive jamais jusque-là,
## même quand le menu de la barre rend la souris dans la même image.
func _unhandled_input(event: InputEvent) -> void:
	for i in EquipmentSlots.flasks().size():
		if event.is_action_pressed("flask_%d" % (i + 1)):
			use_flask(i)
	for i in SkillBar.SLOT_COUNT:
		if event.is_action_pressed("skill_%d" % (i + 1)):
			_held[i] = true


func _physics_process(delta: float) -> void:
	# Le gel ralentit la recharge des cinq cases ici, la marche plus bas.
	var cadence := states.speed_factor
	for i in _recharges.size():
		_recharges[i] = maxf(_recharges[i] - delta * cadence, 0.0)
	_rebirth_wait = maxf(_rebirth_wait - delta, 0.0)
	for index: int in _strides.keys():
		_strides[index] -= delta
		if _strides[index] <= 0.0:
			_strides.erase(index)
	phoenix_ashes = maxf(phoenix_ashes - delta, 0.0)
	_ramp_idle += delta
	_tension_left = maxf(_tension_left - delta, 0.0)
	_faraday_wait = maxf(_faraday_wait - delta, 0.0)
	if _faraday_left > 0.0:
		_faraday_left -= delta
		if _faraday_left <= 0.0:
			hurtbox.invulnerable = false

	_regen(delta)
	_drink(delta)
	_suffer_states(delta)
	if is_dead:
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Enfermé dans la glace : la visée et le sprite suivent encore, les pieds non. Et
	# ZQSD tapé dans un champ de texte — la recherche de l'arbre — ne fait pas marcher.
	if not _bound.is_empty() or get_viewport().gui_get_focus_owner() is LineEdit:
		input = Vector2.ZERO

	if _aim_with_mouse:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			facing = to_mouse.normalized()
	elif input != Vector2.ZERO:
		facing = input.normalized()

	attack_pivot.rotation = facing.angle()
	# Le sprite suit la visée, pas le déplacement : on recule face à l'ennemi.
	sprite.set_state(input != Vector2.ZERO, facing)

	var speed := stats.move_speed * cadence * (ATTACK_MOVE_MULT if _is_swinging else 1.0)
	if input != Vector2.ZERO:
		velocity = velocity.lerp(input.normalized() * speed, ACCEL)
	else:
		velocity = velocity.lerp(Vector2.ZERO, FRICTION)

	move_and_slide()

	# Sondage des cinq cases, sauf quand un panneau tient la souris ou qu'une étiquette
	# de butin, un marchand ou un portail réclame le clic gauche. Tenue, la touche
	# relance à chaque fin de recharge : la cadence est celle de `cast_slot()`.
	for i in SkillBar.SLOT_COUNT:
		var action := "skill_%d" % (i + 1)
		if Game.ui_grabs_input or GroundItem.takes_the_click(action) or Interactable.takes_the_click(action):
			_held[i] = false
			continue
		if not Input.is_action_pressed(action):
			_held[i] = false
			continue
		if _held[i]:
			cast_slot(i)


## Lance la compétence de cette case. **Le seul chemin** — touches, barre, tests — et
## il porte les huit refus : case vide, non apprise, mauvaise arme, réserve, recharge, orbite
## pleine, morts-vivants au complet, frappe vive sans personne à portée.
func cast_slot(index: int) -> bool:
	# La Seconde foulée passe outre la recharge et le coût, une fois.
	var stride := _strides.has(index)
	if is_dead or _recharges.size() <= index or (_recharges[index] > 0.0 and not stride):
		return false
	var skill := bar.skill_of(index)
	if skill == null:
		return false
	var points := skill_points(skill.id)
	if points <= 0:
		return false
	var cast := resolve(skill, points)

	if cast.sustained:
		# Tenir la touche n'alterne pas : un geste entretenu qui clignote serait
		# inutilisable.
		_held[index] = false
		if lit(skill.id):
			# Éteindre n'est pas lancer : ni coût, la recharge seulement contre le rebond.
			extinguish(skill.id)
			_start_recharge(index, cast.interval)
			return true
	# Après l'extinction : changer d'arme ne doit pas empêcher d'éteindre ce qui brûle,
	# et le tombeau de glace ne laisse partir que lui-même.
	if not _bound.is_empty() and skill.id != _bound:
		return false
	if not skill.usable_with(_weapon_base()):
		return false
	if mana < cast.mana_cost and not stride:
		return false
	# Refusée plutôt que de remplacer la plus ancienne : la touche tenue paierait pour
	# rien.
	if skill.shape == Skill.Shape.ORBIT and _blade_crown().full(cast.max_simultaneous()):
		return false
	if skill.shape == Skill.Shape.SUMMON \
			and Minion.count_of(self, skill.id) >= Minion.cap(cast):
		return false
	var prey: Hurtbox = _lunge_target(cast) if skill.shape == Skill.Shape.LUNGE else null
	if skill.shape == Skill.Shape.LUNGE and prey == null:
		return false

	if cast.ramp > 0.0:
		_ramp_up(cast)
	if stride:
		_strides.erase(index)
		# La Foulée de feu : la seconde ruée frappe plus fort, traînée et explosions.
		cast = cast.echoed(1.0 + cast.stride_fire * 0.01)
	else:
		_set_mana(mana - cast.mana_cost)
		_start_recharge(index, cast.interval)
		if cast.second_stride > 0.0:
			_strides[index] = SkillStats.STRIDE_WINDOW
			# Un nouvel appui : la touche encore tenue la dépensait à l'image suivante.
			_held[index] = false
	# La Tension accumulée (jalon 43) : le premier sort de foudre après la course la dépense.
	if _tension_left > 0.0 and cast.nature == DamageType.Kind.LIGHTNING and skill.strikes() \
			and cast.shape != Skill.Shape.DASH:
		cast = cast.echoed(1.0 + _tension * 0.01)
		_tension_left = 0.0
	# Le Condensateur (jalon 43) : à pleins cumuls, le sort de foudre suivant les dépense.
	if _condensed >= SkillStats.CONDENSER_MOST and cast.nature == DamageType.Kind.LIGHTNING \
			and skill.strikes():
		var condensed := lit_number(SkillStats.CONDENSER)
		if condensed > 0.0:
			cast = cast.echoed(1.0 + condensed * 0.01)
			_condensed = 0
			_condensed_power = 0.0
	var salvo := _salvo(skill, points, cast)
	var spell := skill.cadence == Skill.Cadence.CAST and skill.strikes()
	if spell:
		_chord(salvo)
	if not skill.nature_cycle.is_empty():
		_turns[skill.id] = int(_turns.get(skill.id, 0)) + 1
	# Tout lancer anime le lanceur, un sort comme un coup d'arme : sans ça, la
	# sorcière lançait ses sorts immobile. Pas la ruée, où le corps traverse l'écran.
	if cast.shape not in [Skill.Shape.DASH, Skill.Shape.LEAP]:
		sprite.attack(skill.cadence == Skill.Cadence.CAST)
	var aim := _aim_point()
	_pose(skill, salvo, self, facing, aim, prey)
	if cast.rearm > 0.0:
		_rearm(index, cast)
	# Le Plein régime (jalon 43) rejoue le lancer entier : un éclair, ou un orbe s'il l'est devenu.
	if cast.full_throttle > 0.0 and _ramps == SkillStats.RAMP_MOST:
		_throttle += 1
		if _throttle % SkillStats.THROTTLE_EVERY == 0:
			get_tree().create_timer(SkillStats.THROTTLE_GAP, false, true).timeout.connect(
				_pose.bind(skill, salvo, self, facing, aim)
			)
	if skill.id == SkillStats.HEARTH_SKILL:
		Brazier.assist(self, aim)
	if spell:
		_after_spell(skill, salvo, aim)
	return true


## L'Emballement (jalon 43) : un lancer qui suit le précédent de moins de `RAMP_HOLD`
## ajoute un cumul, au-delà tout retombe ; le geste en est d'autant plus court.
func _ramp_up(cast: SkillStats) -> void:
	_ramps = mini(_ramps + 1, SkillStats.RAMP_MOST) if _ramp_idle < SkillStats.RAMP_HOLD else 0
	_ramp_idle = 0.0
	cast.use_time /= 1.0 + cast.ramp * 0.01 * float(_ramps)


## Le Feu nourri (jalon 42) : sous un brasier allumé, la boule en sort attisée — dégâts et
## rayon. Une copie : le lancer résolu se relit ailleurs.
func _stoke(salvo: Array[SkillStats]) -> Array[SkillStats]:
	if salvo[0].stoked <= 0.0 or not _lit_shape(Skill.Shape.AURA):
		return salvo
	var out: Array[SkillStats] = []
	for cast in salvo:
		var gain := 1.0 + cast.stoked * 0.01
		var fed := cast.echoed(gain)
		fed.radius *= gain
		out.append(fed)
	return out


func _lit_shape(shape: Skill.Shape) -> bool:
	for skill in lit_skills():
		if skill.shape == shape:
			return true
	return false


## Un lancer par projectile : ceux d'une compétence à nature tournante prennent chacun le
## tour suivant (le Prisme, jalon 41) ; partout ailleurs, le même lancer.
func _salvo(skill: Skill, points: int, cast: SkillStats) -> Array[SkillStats]:
	var out: Array[SkillStats] = [cast]
	if skill.nature_cycle.is_empty():
		return out
	var turn := int(_turns.get(skill.id, 0))
	for i in range(1, cast.projectile_count()):
		out.append(skill.resolve(points, stats, skill_mods, talents_of(skill.id), turn + i))
	return out


## **Ce qu'un lancer pose dans le monde**, depuis `origin` vers `toward` et le point visé :
## le joueur, ou l'épaule du Familier qui rejoue un sort (jalon 41). Le premier lancer de
## la salve sert à tout ce qui n'est pas une volée de projectiles.
func _pose(
	skill: Skill, salvo: Array[SkillStats], origin: Node2D, toward: Vector2, aim: Vector2,
	prey: Hurtbox = null
) -> void:
	salvo = _stoke(salvo)
	var cast := salvo[0]
	var at := origin.global_position
	var parent := _effects_parent()
	# La forme du lancer : un nœud peut l'avoir transformée (jalon 34).
	match cast.shape:
		Skill.Shape.BOLT:
			_roll(salvo, bolt_scene, origin, toward)
		Skill.Shape.BALL:
			_roll(salvo, orb_scene, origin, toward, aim)
		Skill.Shape.COMET:
			_roll(salvo, comet_scene, origin, toward)
		Skill.Shape.ORB:
			var directions := _spread(cast, toward)
			# Le Satellite (jalon 43) : répartis autour du lanceur, pas en éventail.
			if cast.satellite > 0.0:
				for i in directions.size():
					directions[i] = toward.rotated(TAU * float(i) / float(directions.size()))
			for direction in directions:
				StaticOrb.send(parent, at, direction, cast, states, origin)
		Skill.Shape.METEOR:
			# Plusieurs boules deviennent une rangée de météores en travers de la visée, à
			# un rayon l'un de l'autre : leurs explosions se chevauchent de moitié.
			var count := cast.projectile_count()
			for i in count:
				var across := toward.orthogonal() * (float(i) - float(count - 1) * 0.5) * cast.radius
				Meteor.fall(parent, aim + across, cast, states, origin, orb_scene)
		Skill.Shape.CHAIN, Skill.Shape.WEB:
			if ChainLightning.unload(parent, origin, cast, toward) > 0:
				Game.hit_stop()
				Game.shake_camera(camera, shake_amount)
		Skill.Shape.CLOUD:
			StormCloud.put(parent, aim, cast, states, null, origin)
		Skill.Shape.TEMPEST:
			StormCloud.put(parent, global_position, cast, states, self, origin)
		Skill.Shape.SNAKE:
			# Une couvée part en éventail, centrée sur la visée.
			var brood := 1 + int(cast.brood)
			for i in brood:
				var turn := (float(i) - float(brood - 1) * 0.5) * HellSnake.BROOD_SPREAD
				HellSnake.drop(parent, aim, cast, toward.rotated(turn), states, origin)
		Skill.Shape.AURA:
			_light(skill.id, Immolation.ignite(self, skill))
		Skill.Shape.BUFF:
			# Sa durée, ou zéro : un buff sans durée brûle tant qu'on le paie.
			_light(skill.id, Buff.light(self, skill, cast.duration, cast.binds_caster))
		Skill.Shape.CYCLONE:
			_light(skill.id, Cyclone.spin(self, skill))
		Skill.Shape.FAMILIAR:
			_light(skill.id, Familiar.summon(self, skill))
		Skill.Shape.DASH, Skill.Shape.LEAP:
			_dash(skill, cast)
		Skill.Shape.WAVE, Skill.Shape.BOOMERANG:
			_swing(cast)
			# Vagues jumelles : en éventail, centrées sur la visée, comme une couvée.
			var count := 1 + int(cast.waves)
			for i in count:
				var turn := (float(i) - float(count - 1) * 0.5) * SlashWave.FAN
				SlashWave.send(parent, global_position, facing.rotated(turn), cast, states, self)
		Skill.Shape.SLAM:
			_slam(cast)
		Skill.Shape.SPIKES:
			IceSpikes.raise_at(parent, aim, cast, states, origin, bolt_scene)
		Skill.Shape.FISSURE:
			IceSpikes.fissure(parent, at, aim, cast, states, origin, bolt_scene)
		Skill.Shape.NOVA:
			# L'explosion de la boule de feu, posée sur soi : elle frappe une fois son
			# cercle et s'efface, ce qu'une nova fait exactement. Son sol a sa taille.
			Explosion.put(
				parent, at, cast.roll(Game.rng), cast.radius, null,
				DamageType.COLORS[cast.nature], states, cast
			)
			if cast.ground_duration > 0.0:
				DashTrail.patch(parent, at, cast.ground(cast.radius), states)
		Skill.Shape.RING:
			FrostRing.spread(parent, at, cast, states)
		Skill.Shape.VORTEX, Skill.Shape.IMPLOSION:
			IceVortex.open(parent, at, cast, states)
		Skill.Shape.BEAM:
			HolyBeam.fire(parent, at, toward, cast, states)
		Skill.Shape.HOLY_CROSS:
			# Droit sur les axes, sans viser ; un ennemi au croisement n'est frappé qu'une fois.
			var struck := {}
			for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
				HolyBeam.fire(parent, at, direction, cast, states, struck)
		Skill.Shape.PILLAR, Skill.Shape.DRIFT:
			SacredPillar.fall(parent, aim, cast, states)
		Skill.Shape.PULSE:
			# Portée par le joueur et non posée : elle suit celui qui l'a lancée.
			HolyPulse.emanate(self, cast)
		Skill.Shape.ORBIT:
			# Arsenal : des épées en plus à chaque lancer, dans la limite de la ronde.
			var crown := _blade_crown()
			for i in 1 + int(cast.extra_swords):
				if crown.full(cast.max_simultaneous()):
					break
				crown.add_to(cast)
		Skill.Shape.SUMMON:
			Minion.raise(self, cast, parent)
		Skill.Shape.GATE:
			RottingGate.open(parent, aim, cast, states)
		Skill.Shape.NEST:
			RottingGate.open(parent, global_position, cast, states, self)
		Skill.Shape.CURSE, Skill.Shape.MARK:
			PutridCurse.fall(parent, aim, cast, states, self)
		Skill.Shape.BREATH:
			ToxicBreath.exhale(parent, at, toward, cast, states)
		Skill.Shape.CATALYSIS:
			Catalysis.burst(parent, aim, cast, states)
		Skill.Shape.TRIAD:
			Triad.converge(parent, at, aim, cast, states)
		Skill.Shape.TURRET:
			Brazier.place(self, aim, cast, parent)
		Skill.Shape.DOLL:
			RagDoll.place(self, aim, cast, parent)
		Skill.Shape.STRIKE:
			_swing(cast, SwingArc.Style.STRIKE)
		Skill.Shape.CROSS:
			_swing(cast, SwingArc.Style.CROSS)
		Skill.Shape.LUNGE:
			_lunge(cast, prey)
		_:
			_swing(cast)


## Ce qu'un sort qui frappe déclenche chez son lanceur (jalon 41) : une charge d'Harmonie
## s'il change de nature — le Tempo avec elle —, leur perte s'il la répète sous la
## Dissonance, ce que la Résonance rend à un buff lancé, l'écho du Familier.
func _after_spell(skill: Skill, salvo: Array[SkillStats], aim: Vector2) -> void:
	var nature := salvo[0].nature
	var alternated := _last_spell_nature >= 0 and nature != _last_spell_nature
	var repeated := nature == _last_spell_nature
	_last_spell_nature = nature
	var changed := false
	for id: String in _lit:
		if not lit(id):
			continue
		if _lit[id] is Familiar:
			(_lit[id] as Familiar).echo(skill, salvo, aim)
			continue
		if not _lit[id] is Buff:
			continue
		var buff := _lit[id] as Buff
		var own := resolve(SkillCatalog.by_id(id), skill_points(id))
		if alternated and buff.stack(Skill.StackTrigger.ALTERNATION, own):
			changed = true
			_hasten(own.tempo)
		elif repeated and own.dissonance > 0.0 and buff.stacks > 0:
			buff.stacks = 0
			changed = true
		if own.resonance > 0.0:
			buff.prolong(own.resonance)
	if changed:
		after_buff_change()


## Le Tempo (jalon 41) : les recharges en cours des compétences **à recharge** perdent ces
## secondes. Celles qui n'ont que leur temps de geste n'y gagnent rien : ce serait de la
## vitesse d'incantation.
func _hasten(seconds: float) -> void:
	if seconds <= 0.0:
		return
	for i in _recharges.size():
		var other := bar.skill_of(i)
		if other != null and other.cooldown > 0.0:
			_recharges[i] = maxf(_recharges[i] - seconds, 0.0)


## L'Accord parfait (jalon 41) : un buff à pleines charges qui le porte les consomme
## toutes, et le sort part dans les trois éléments, un tiers chacun, plus fort.
func _chord(salvo: Array[SkillStats]) -> void:
	for id: String in _lit:
		if not lit(id) or not _lit[id] is Buff:
			continue
		var skill := SkillCatalog.by_id(id)
		var own := resolve(skill, skill_points(id))
		var buff := _lit[id] as Buff
		if own.perfect_chord <= 0.0 or buff.stacks < Buff.cap_of(skill, own):
			continue
		buff.stacks = 0
		var factor := 1.0 + own.perfect_chord * 0.01
		for cast in salvo:
			cast.blend(DamageType.ELEMENTS)
			cast.more *= factor
			for i in cast.damage_min.size():
				cast.damage_min[i] *= factor
				cast.damage_max[i] *= factor
		after_buff_change()
		return


## Le Familier rejoue un sort : la même pose depuis son épaule, vers le point visé au
## lancer. **Pas un lancer** — ni coût, ni tour, ni charge, ni écho de l'écho.
func echo(skill: Skill, salvo: Array[SkillStats], origin: Node2D, aim: Vector2) -> void:
	if is_dead:
		return
	var toward := origin.global_position.direction_to(aim)
	if toward == Vector2.ZERO:
		toward = facing
	_pose(skill, salvo, origin, toward, aim)


## Ce geste entretenu brûle-t-il en ce moment.
func lit(skill_id: String) -> bool:
	# Sans type : assigner une instance déjà libérée à une variable typée est en soi une
	# erreur, avant même le test de validité (invariant 4).
	var node: Variant = _lit.get(skill_id)
	return is_instance_valid(node) and not (node as Node).is_queued_for_deletion()


## Une aura, quelle qu'elle soit. Pour les tests de forme.
func aura_lit() -> bool:
	for id: String in _lit:
		if lit(id) and _lit[id] is Immolation:
			return true
	return false


## **Le seul chemin de l'extinction**, touche ou réserve vide : le nœud s'en va et la
## fiche perd les lignes du buff.
func extinguish(skill_id: String) -> void:
	var node: Variant = _lit.get(skill_id)
	_lit.erase(skill_id)
	if is_instance_valid(node):
		(node as Node).extinguish()
		if node is Buff and not is_dead:
			_shatter(SkillCatalog.by_id(skill_id))
	after_buff_change()


## L'Éclatement du Tombeau (jalon 36) : un buff lancé qui s'éteint éclate. Pas celui
## d'une ruée, qui a déjà éclaté à l'arrivée.
func _shatter(skill: Skill) -> void:
	if skill == null or skill.shape != Skill.Shape.BUFF:
		return
	var cast := resolve(skill, skill_points(skill.id))
	if cast.end_burst > 0.0:
		Explosion.put(
			_effects_parent(), global_position, cast.roll(Game.rng), cast.end_burst, null,
			DamageType.COLORS[cast.nature], states, cast
		)


## L'allumage, son pendant : la fiche reçoit les lignes du buff.
func _light(skill_id: String, node: Node) -> void:
	# Une ruée relancée avant la fin de son buff remplace le sien : sans ça le premier
	# nœud brûlerait sans que rien ne le tienne plus.
	var old: Variant = _lit.get(skill_id)
	if is_instance_valid(old) and old != node:
		(old as Node).extinguish()
	_lit[skill_id] = node
	after_buff_change()


## Combien d'épées tournent autour du personnage.
func orbiting_swords() -> int:
	return _crown.count() if _crown != null else 0


## Ce qu'une aura coûte à son porteur cette image-ci, réparti entre les natures comme
## ses dégâts, chaque part par `CharacterStats.mitigate()`, engourdissement compris.
## **Pas un coup** : ni esquive ni plancher. L'armure se compte sur la perte **par
## seconde**, pas sur la tranche d'une image. Mortelle.
func burn(part_per_second: float, distribution: Array[float], delta: float) -> void:
	if is_dead or part_per_second <= 0.0:
		return
	var per_second := stats.max_health * part_per_second
	var taken_value := 0.0
	for kind in distribution.size():
		taken_value += stats.mitigate(kind, per_second * distribution[kind])
	var loss := taken_value * states.damage_taken_factor * delta
	_set_health(health - loss)
	var digit := _burn_to_show.add_to(loss, delta)
	HitFeedback.damage_without_hit(hurtbox.overhead(), digit, true)
	if health <= 0.0:
		_die()


## Ce qu'un geste entretenu **rend** cette image-ci, en part des PV max : le pendant de
## `burn()`, sans mitigation — un soin ne se résiste pas.
func mend(part_per_second: float, delta: float) -> void:
	if part_per_second > 0.0:
		heal(stats.max_health * part_per_second * delta)


## Ce qu'un geste entretenu prend à la réserve cette image-ci, **à plat**. Faux quand
## elle est vide : le geste s'éteint, là où la brûlure des PV tue. Aucun drain demandé,
## rien à payer.
func drain(mana_per_second: float, delta: float) -> bool:
	if mana_per_second <= 0.0:
		return true
	var cost := mana_per_second * delta
	if mana < cost:
		return false
	_set_mana(mana - cost)
	return true


## Ce qu'un geste rend à la réserve : le Tribut de la malédiction (jalon 38).
## Paie ce montant s'il est là, et dit s'il l'était : le Foyer du mage ne tire qu'à ce prix.
func spend_mana(amount: float) -> bool:
	if is_dead or mana < amount:
		return false
	_set_mana(mana - amount)
	return true


func gain_mana(amount: float) -> void:
	if amount > 0.0 and not is_dead:
		_set_mana(mana + amount)


## Ce que les états brûlent, ôté par le seul chemin de la vie.
func _suffer_states(delta: float) -> void:
	var loss := states.advance(delta)
	if loss <= 0.0:
		return
	_set_health(health - loss)
	var digit := states.digit()
	HitFeedback.damage_without_hit(hurtbox.overhead(), digit, true)
	if health <= 0.0:
		_die()


## Ce que sa pourriture lui rend, et ce que rend chaque ennemi touché (Hargne, Absolution).
func heal(amount: float) -> void:
	if not is_dead:
		_set_health(health + amount)


## Un coup du joueur vient de toucher : **le seul endroit** qui tire la charge statique.
## La condition porte sur l'état — chance non nulle, cible engourdie — et jamais sur le
## résultat, donc le nombre de tirages ne dépend pas de ce qui sort (invariant 3).
func _on_struck(at: Vector2, parts: Array, victim: StatusEffects) -> void:
	if stats.static_charge_chance <= 0.0 or victim == null:
		return
	if not victim.active(StatusEffects.Kind.NUMB):
		return
	if Game.rng.randf() * 100.0 >= stats.static_charge_chance:
		return
	StaticCharge.put(
		_effects_parent(), at, at - global_position, parts, states, StaticCharge.SHARE, false,
		StaticCharge.LIFE + lit_number(SkillStats.CAPACITY), _charge_bit
	)


## Ce que les buffs allumés portent de ce nombre de mécanique (jalon 43) : l'Électricité
## statique y met la Capacité, le Condensateur, le Choc en retour. Résolu à chaque appel :
## on ne le demande qu'à un événement rare — une charge qui naît, un coup reçu.
func lit_number(number: String) -> float:
	var total := 0.0
	for skill in lit_skills():
		total += float(resolve(skill, skill_points(skill.id)).get(number))
	return total


## Une charge statique de ce joueur vient de mordre : le Condensateur compte. À pleins
## cumuls, la Décharge totale les rend d'un coup en nova, sans attendre de sort.
func _charge_bit(power: float) -> void:
	_condensed = mini(_condensed + 1, SkillStats.CONDENSER_MOST)
	_condensed_power += power
	if _condensed < SkillStats.CONDENSER_MOST or lit_number(SkillStats.TOTAL_DISCHARGE) <= 0.0:
		return
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.LIGHTNING] = _condensed_power
	Explosion.put(
		_effects_parent(), global_position, parts, SkillStats.DISCHARGE_RADIUS, null,
		DamageType.COLORS[DamageType.Kind.LIGHTNING], states, null
	)
	_condensed = 0
	_condensed_power = 0.0


## Un ennemi vient de frapper au contact (`Enemy._hurt()`) : le Choc en retour lui rend
## une part du coup en foudre, par un arc ; la Cage de Faraday s'ensuit.
func backlash(attacker: Enemy, amount: float) -> void:
	var part := lit_number(SkillStats.BACKLASH)
	if part <= 0.0 or is_dead or not is_instance_valid(attacker):
		return
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.LIGHTNING] = amount * part * 0.01
	Targets.strike(attacker.hurtbox, parts, global_position, states, null)
	ChainLightning.trace(
		_effects_parent(), PackedVector2Array([global_position, attacker.global_position]),
		DamageType.COLORS[DamageType.Kind.LIGHTNING]
	)
	# Jamais par-dessus une invulnérabilité posée ailleurs, qu'elle lèverait en finissant.
	if _faraday_wait <= 0.0 and not hurtbox.invulnerable and lit_number(SkillStats.FARADAY) > 0.0:
		hurtbox.invulnerable = true
		_faraday_left = SkillStats.FARADAY_TIME
		_faraday_wait = SkillStats.FARADAY_PERIOD


## Un ennemi tué. **Depuis un rappel de collision** : ce qui naît ici passe par
## `DeferredTree` (invariant 4) — l'explosion et le sol le font d'eux-mêmes.
func _on_slew(cast: SkillStats, at: Vector2, victim: StatusEffects) -> void:
	if cast == null:
		return
	# L'état de la nature du lancer : un brasier devenu nécrotique fait exploser les pourrissants.
	if cast.kill_burst > 0.0 and victim != null and victim.active(StatusEffects.rolled_by(cast.nature)):
		var parts := cast.roll(Game.rng)
		for i in parts.size():
			parts[i] *= SkillStats.KILL_BURST_PART
		# La Poudrière (jalon 42) : l'explosion pose son état à coup sûr, et la chaîne ne
		# s'arrête plus faute d'embrasés. Une copie, que la suite de la chaîne reprend.
		var blast := cast
		if cast.powder_keg > 0.0:
			blast = cast.echoed(1.0)
			blast.status_chance_increase += SkillStats.SURE_STATE
		Explosion.put(
			_effects_parent(), at, parts, cast.kill_burst, null,
			DamageType.COLORS[cast.nature], states, blast
		)
		# Le Survoltage (jalon 43) : l'explosion relance une petite chaîne depuis le tué.
		if cast.overvolt > 0.0:
			ChainLightning.surge.call_deferred(_effects_parent(), get_world_2d(), at, states, cast.surged())
	# Les Âmes consumées (jalon 42) : chaque tué rend une part des PV max.
	if cast.soul_feast > 0.0:
		heal(stats.max_health * cast.soul_feast * 0.01)
	if cast.keywords.has(Keywords.ATTACK):
		_stack_on_kill()
	elif cast.keywords.has(Keywords.SPELL):
		_siphon()


## Le Siphon (jalon 41) : un ennemi tué d'un sort rend du mana, sous le buff qui le porte.
func _siphon() -> void:
	for skill in lit_skills():
		gain_mana(resolve(skill, skill_points(skill.id)).siphon)


## Chaque buff à charges allumé en gagne une. Rien n'y naît : la fiche seule est refaite.
func _stack_on_kill() -> void:
	var gained := false
	for id: String in _lit:
		if lit(id) and _lit[id] is Buff:
			gained = (_lit[id] as Buff).stack(Skill.StackTrigger.KILL) or gained
	if gained:
		after_buff_change()


## Un état neuf s'annonce : la pastille seule ne dirait pas pourquoi on ralentit.
func _announce_state(kind: int) -> void:
	if HitFeedback.current != null:
		HitFeedback.current.state(hurtbox.overhead(), kind)


func _show_states() -> void:
	sprite.show_states(states)
	health_bar.show_states(states)


## Une ruée : on se **porte** au curseur, murs et ennemis traversés — seule l'arrivée
## doit être libre. Ni gel ni secousse : ce qui dure ne fige jamais.
##
## Ce qu'elle laisse derrière, **jamais les deux** : une trace qui frappe quand elle a
## un rayon et une période, ou un buff bref sur le lanceur quand elle a des lignes.
func _dash(skill: Skill, cast: SkillStats) -> void:
	var from_value := global_position
	global_position = _landing(from_value, _aim_point())
	# Le Bond (jalon 34) : un saut, qui ne laisse que son arc et son cratère.
	if cast.shape == Skill.Shape.LEAP:
		LeapArc.leave(_effects_parent(), from_value, global_position, cast)
	elif cast.period > 0.0 and cast.radius > 0.0:
		DashTrail.leave(_effects_parent(), from_value, global_position, cast, states)
	elif skill.grants_buffs():
		# Le Galop (jalon 43) : le nouvel appel reprend les charges de l'ancien, plus une.
		var held := maxi(lit_stacks(skill.id), 1) if lit(skill.id) else 0
		var buff := Buff.light(self, skill, cast.duration)
		if cast.gallop > 0.0:
			buff.hold_stacks(mini(held + 1, SkillStats.GALLOP_MOST), cast.duration)
		_light(skill.id, buff)
	# Le Trait d'éclair (jalon 43) : un éclair relie le départ à l'arrivée, et frappe ce qu'il
	# traverse ; l'Aller-retour y ramène, par le même chemin. La Tension accumulée se charge.
	if cast.bolt_dash > 0.0:
		_bolt_line(from_value, global_position, cast)
		if cast.round_trip > 0.0:
			get_tree().create_timer(SkillStats.ROUND_TRIP_DELAY, false, true).timeout.connect(
				_return_to.bind(from_value, cast)
			)
	if cast.charged_run > 0.0:
		var run := minf(from_value.distance_to(global_position), SkillStats.CHARGED_RUN_MOST)
		_tension = cast.charged_run * run / SkillStats.CHARGED_RUN_STEP
		_tension_left = SkillStats.CHARGED_RUN_WINDOW
	# Sillage statique (jalon 35) : réparties sur le trajet, à la part d'un coup de la ruée.
	var charges := int(cast.trail_charges)
	var charge_life := StaticCharge.LIFE + lit_number(SkillStats.CAPACITY) if charges > 0 else 0.0
	for i in charges:
		StaticCharge.put(
			_effects_parent(), from_value.lerp(global_position, (float(i) + 0.5) / float(charges)),
			(global_position - from_value).orthogonal() * (1.0 if i % 2 == 0 else -1.0),
			cast.roll(Game.rng), states, SkillStats.TRAIL_CHARGE_PART, cast.static_mines > 0.0,
			charge_life, _charge_bit
		)
	if cast.end_burst > 0.0:
		Explosion.put(
			_effects_parent(), global_position, cast.roll(Game.rng), cast.end_burst, null,
			DamageType.COLORS[cast.nature], states, cast
		)
		# Le Tonnerre roulant (jalon 43) : l'arrivée gronde encore, au même endroit.
		if cast.rolling_thunder > 0.0:
			for i in SkillStats.ROLLING_COUNT:
				get_tree().create_timer(SkillStats.ROLLING_GAP * float(i + 1), false, true).timeout.connect(
					_rumble.bind(global_position, cast.echoed(cast.rolling_thunder * 0.01))
				)
		# Le Départ en trombe (jalon 42) : la même explosion, à une part, d'où l'on part.
		if cast.flying_start > 0.0:
			Explosion.put(
				_effects_parent(), from_value, cast.echoed(cast.flying_start * 0.01).roll(Game.rng),
				cast.end_burst, null, DamageType.COLORS[cast.nature], states, cast
			)
	# L'Onde brûlante : l'atterrissage du bond projette un anneau, à une part du coup.
	if cast.burning_wave > 0.0 and cast.shape == Skill.Shape.LEAP:
		var wave := cast.echoed(cast.burning_wave * 0.01)
		wave.radius = cast.end_burst
		FrostRing.spread(
			_effects_parent(), global_position, wave, states, SkillStats.BURNING_WAVE_REACH
		)
	_charm(cast)


func _bolt_line(from_value: Vector2, to: Vector2, cast: SkillStats) -> void:
	var parts := cast.roll(Game.rng)
	for target in Targets.in_capsule(get_world_2d(), from_value, to, SkillStats.BOLT_DASH_WIDTH):
		Targets.strike(target, parts, from_value, states, cast)
	ChainLightning.trace(_effects_parent(), PackedVector2Array([from_value, to]), DamageType.COLORS[cast.nature])


## L'Aller-retour : on revient d'où l'on est parti, murs traversés comme à l'aller.
func _return_to(origin: Vector2, cast: SkillStats) -> void:
	if is_dead:
		return
	var from_value := global_position
	global_position = _landing(from_value, origin)
	_bolt_line(from_value, global_position, cast)


func _rumble(at: Vector2, cast: SkillStats) -> void:
	Explosion.put(
		_effects_parent(), at, cast.roll(Game.rng), cast.end_burst, null,
		DamageType.COLORS[cast.nature], states, cast
	)


## Le Réarmement (jalon 43) : chaque engourdi dans l'explosion d'arrivée — compté avant
## qu'elle frappe — raccourcit la recharge de la case.
func _rearm(index: int, cast: SkillStats) -> void:
	var numbed := 0
	for target in Targets.in_circle(get_world_2d(), global_position, cast.end_burst):
		if target.states != null and target.states.active(StatusEffects.Kind.NUMB):
			numbed += 1
	_recharges[index] = maxf(_recharges[index] - cast.rearm * float(numbed), 0.0)


## Le Charmeur (jalon 42) : à l'arrivée, un Serpent infernal surgit — avec vos points et
## votre arbre du serpent, sans coût, compté dans la limite. La Danse du charmeur rappelle
## ceux déjà en jeu au point d'arrivée.
func _charm(cast: SkillStats) -> void:
	if cast.snake_dance > 0.0:
		HellSnake.recall(self, global_position)
	var points := skill_points(SkillStats.CHARMED_SKILL)
	if cast.charmer <= 0.0 or points <= 0:
		return
	var snake := resolve(SkillCatalog.by_id(SkillStats.CHARMED_SKILL), points)
	HellSnake.drop(_effects_parent(), global_position, snake, facing, states, self)


## Le Brise-sol (jalon 39) : la lame s'abat devant soi et frappe tout le cercle de
## l'impact, le recul partant de son centre. Un geste : un gel, une secousse de frappe.
func _slam(cast: SkillStats) -> void:
	var impact := global_position + facing * SLAM_REACH
	var struck := Targets.strike_circle(
		get_world_2d(), impact, cast.radius, cast, states, stats.knockback_force + cast.knockback
	)
	GroundSlam.leave(_effects_parent(), impact, cast)
	heal(cast.life_on_hit * float(struck.size()))
	if not struck.is_empty():
		Game.hit_stop()
		Game.shake_camera(camera, shake_amount * STRIKE_SHAKE)


## La cible d'une frappe vive : parmi les ennemis à sa portée, **le plus proche de la
## visée**. Null sans personne à portée, et le lancer est refusé.
func _lunge_target(cast: SkillStats) -> Hurtbox:
	var aim := _aim_point()
	var best: Hurtbox = null
	for candidate in Targets.in_circle(get_world_2d(), global_position, cast.radius):
		if best == null or candidate.global_position.distance_squared_to(aim) \
				< best.global_position.distance_squared_to(aim):
			best = candidate
	return best


## Une frappe vive : on se porte **contre** la cible, murs traversés comme une ruée, et on
## frappe elle seule — pas un arc, qui prendrait ses voisins. Gel et secousse d'une frappe.
func _lunge(cast: SkillStats, prey: Hurtbox) -> void:
	var toward := prey.global_position
	var from_value := global_position
	global_position = _landing(from_value, toward - from_value.direction_to(toward) * LUNGE_REACH)
	if global_position != toward:
		facing = global_position.direction_to(toward)
	LungeTrail.leave(_effects_parent(), from_value, global_position, toward)
	Targets.strike(prey, cast.roll(Game.rng), global_position, states, cast)
	Game.hit_stop()
	Game.shake_camera(camera, shake_amount * STRIKE_SHAKE)


## Le point le plus proche de la visée où le corps tient, en reculant vers le départ.
## Le départ ferme la marche : on en vient, donc on y tient.
func _landing(from_value: Vector2, toward: Vector2) -> Vector2:
	var steps := maxi(ceili(from_value.distance_to(toward) / LANDING_STEP), 1)
	for i in steps:
		var point := toward.lerp(from_value, float(i) / float(steps))
		if _fits_at(point):
			return point
	return from_value


## **Le décor seul** : un ennemi sous les pieds se repousse de lui-même à l'image
## suivante, la roche non.
func _fits_at(point: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body_shape.shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = Targets.DECOR
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## Au curseur, à `PLACEMENT_RANGE` au plus ; à la manette, à cette distance devant.
func _aim_point() -> Vector2:
	var toward := facing * PLACEMENT_RANGE
	if _aim_with_mouse:
		toward = (get_global_mouse_position() - global_position).limit_length(PLACEMENT_RANGE)
	return global_position + toward


## Où naissent tirs, nuages et serpents ; à défaut d'un conteneur, à côté du joueur.
func _effects_parent() -> Node:
	return projectile_parent if projectile_parent != null else get_parent()


func _blade_crown() -> BladeCrown:
	if _crown == null:
		_crown = BladeCrown.new()
		_crown.author = states
		_crown.effects = _effects_parent()
		add_child(_crown)
		Settings.veil(_crown, Settings.SPELLS)
	return _crown


## **Le chemin du lancer et de la page du manuel** : fiche et modificateurs de mot-clé.
## Au tour du prochain lancer : la page montre la nature qui partira.
## Le coût d'un lancer, nœuds compris — le Météore le renchérit. La barre le relit à chaque
## image : d'où le cache, vidé à chaque recalcul de la fiche (points, objets, buffs).
func cost_of(skill: Skill) -> float:
	if not _costs.has(skill.id):
		_costs[skill.id] = resolve(skill, maxi(skill_points(skill.id), 1)).mana_cost
	return _costs[skill.id]


## `plain` : sans les nœuds qui la transforment — la Boule de feu que tire le Foyer du mage
## reste une boule, Météore pris ou non (jalon 42).
func resolve(skill: Skill, points: int, plain := false) -> SkillStats:
	var talents: Array = talents_of(skill.id)
	if plain:
		talents = talents.filter(func(t: InvestedTalent) -> bool: return not t.node.transforms)
	return skill.resolve(points, stats, skill_mods, talents, int(_turns.get(skill.id, 0)))


## Les deux ensemble : gardés séparément, l'un finirait par ne plus décrire l'autre.
func _start_recharge(index: int, interval: float) -> void:
	_recharges[index] = interval
	_recharge_totals[index] = interval


## Ce qu'il reste à attendre, en secondes : la barre s'en sert pour savoir si elle se
## repeint. Le voile, lui, veut une part — `cooldown_ratio()`.
func remaining_cooldown(index: int) -> float:
	return _recharges[index] if index >= 0 and index < _recharges.size() else 0.0


## La part de recharge qu'il reste, de 1 à 0 : contre **l'intervalle du lancer**, le
## seul que les nœuds de la case aient pu changer.
func cooldown_ratio(index: int) -> float:
	if index < 0 or index >= _recharges.size() or _recharge_totals[index] <= 0.0:
		return 0.0
	return clampf(_recharges[index] / _recharge_totals[index], 0.0, 1.0)


## Les points du manuel qui l'enseigne, ou l'unique point d'une attaque de départ ;
## zéro si son livre a quitté le râtelier.
func skill_points(skill_id: String) -> int:
	var book := book_of(skill_id)
	if book != null:
		return book.manual.points_of(skill_id)
	if SkillCatalog.is_starting(skill_id):
		return BASIC_ATTACK_POINTS
	return 0


## **Le seul endroit qui le cherche** : points et nœuds viennent du même livre.
func book_of(skill_id: String) -> Item:
	for book in rack.equipped_items():
		if book.teaches(skill_id):
			return book
	return null


## Vides pour une attaque de départ, qui n'a pas de case.
func talents_of(skill_id: String) -> Array[InvestedTalent]:
	var book := book_of(skill_id)
	return book.invested_talents(skill_id) if book != null else [] as Array[InvestedTalent]


## **Le seul chemin** : un passif change la fiche, le recalcul ne s'oublie pas.
func invest(slot: int, identifier: String) -> bool:
	var book := rack.at(slot)
	if book == null or book.base.manual == null:
		return false
	if not book.manual.invest(book.base.manual, identifier):
		return false
	_after_equipment_change()
	return true


## Reprend un point d'une case, d'un passif ou d'un nœud — `Manual` dit quand.
## Une compétence retombée à zéro sort de la barre, comme quand son livre part.
func refund(slot: int, identifier: String) -> bool:
	var book := rack.at(slot)
	if book == null or book.base.manual == null:
		return false
	if not book.manual.refund(book.base.manual, identifier):
		return false
	_clear_bar_of(book.base.manual.skills())
	_after_equipment_change()
	return true


## Ce qu'on peut poser dans une case de barre : les deux attaques de départ, et
## toute case des manuels à l'étude où l'on a mis au moins un point.
func available_skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for id: String in SkillCatalog.STARTING:
		out.append(SkillCatalog.by_id(id))
	for book in rack.equipped_items():
		for skill in book.base.manual.skills():
			if book.manual.points_of(skill.id) > 0:
				out.append(skill)
	return out


## Un coup par coup du geste — deux pour une croix —, chacun tiré, avec sa hitbox.
func _swing(cast: SkillStats, style := SwingArc.Style.ARC) -> void:
	_is_swinging = true
	_hit_shake = shake_amount * (STRIKE_SHAKE if style == SwingArc.Style.STRIKE else 1.0)
	swing_arc.play(swing_duration * float(cast.hits), style)

	for hit in cast.hits:
		if hit > 0:
			# Un ennemi déjà dedans n'y *entre* pas deux fois : la hitbox doit être fermée une
			# image de physique avant de se rouvrir.
			await get_tree().physics_frame
		_hit_parts = cast.roll(Game.rng)
		_hit_cast = cast
		_already_hit.clear()
		# set_deferred : on est peut-être dans un rappel de physique.
		hitbox.set_deferred("monitoring", true)
		# ignore_time_scale : sinon le hit-stop étire la fenêtre de swing.
		await get_tree().create_timer(swing_duration, true, false, true).timeout
		hitbox.set_deferred("monitoring", false)
	_is_swinging = false


## Les traits répartis sur l'écart du geste résolu : tout vient de
## `SkillStats`, rien n'est relu sur la compétence.
## `salvo` : un lancer par trait, ou un seul pour tous (`_salvo()`).
func _roll(
	salvo: Array[SkillStats], scene: PackedScene, origin: Node2D, toward: Vector2,
	aim := Vector2.INF
) -> void:
	if scene == null:
		return
	var directions := _spread(salvo[0], toward)
	var count := directions.size()
	for i in count:
		var cast := salvo[i % salvo.size()]
		var from := origin.global_position
		var heading := directions[i]
		# La Convergence (jalon 42) : côte à côte au départ, toutes vers le point visé.
		if cast.converge > 0.0 and aim != Vector2.INF:
			from += toward.orthogonal() * (float(i) - float(count - 1) * 0.5) * SkillStats.CONVERGE_GAP
			heading = from.direction_to(aim)
		# Un tirage par trait : trois traits identiques se liraient comme un seul coup.
		var bolt := Projectile.spawn(
			_effects_parent(), scene, from, heading, cast.roll(Game.rng),
			origin, cast.projectile_speed, cast.nature, cast
		)
		if bolt is Fireball:
			(bolt as Fireball).explosion_radius = cast.radius


## Un cap par projectile, sur l'écart du geste. Un seul part droit devant, quelle que
## soit la dispersion.
func _spread(cast: SkillStats, toward: Vector2) -> Array[Vector2]:
	var count := cast.projectile_count()
	var spread := deg_to_rad(cast.spread_in_degrees)
	# Un cercle complet divise l'écart par le nombre de traits et non par les intervalles
	# — sinon le dernier retombe sur le premier —, décalé d'un demi-pas.
	var closes := is_equal_approx(spread, TAU)
	var step := 0.0
	var start := 0.0
	if count > 1:
		step = spread / float(count if closes else count - 1)
		start = -spread * 0.5 + (step * 0.5 if closes else 0.0)
	var out: Array[Vector2] = []
	for i in count:
		out.append(toward.rotated(start + step * float(i)))
	return out


## Testé avant d'écrire : une barre pleine n'émet rien.
func _regen(delta: float) -> void:
	if stats.health_regen > 0.0 and health < stats.max_health:
		_set_health(health + stats.health_regen * delta)
	if stats.mana_regen > 0.0 and mana < stats.max_mana:
		_set_mana(mana + stats.mana_regen * delta)


## Reconstruit la fiche **de zéro** : additionner compterait les bonus à chaque appel.
func recompute_stats() -> void:
	stats = base_stats.duplicate()
	_costs.clear()

	# Tous les objets d'un coup : les plats avant les pourcentages, quel que soit
	# l'ordre d'équipement.
	var mods: Array[StatMod] = []
	for slot in EquipmentSlots.ids():
		var item: Item = equipment.get(slot)
		if item != null and not item.is_flask():
			mods.append_array(item.mods())
	# Un flacon ne compte que pendant qu'on le boit.
	mods.append_array(flask_mods())

	# Les passifs du râtelier et de l'arbre, dans la même liste et le même tri que les
	# objets — et les buffs allumés, qui ne durent que tant qu'on les paie.
	for book in rack.equipped_items():
		mods.append_array(book.passive_mods())
	mods.append_array(passive_tree.mods(passives))
	mods.append_array(buff_mods())
	# Rempart d'os et Bouclier de lames : tant qu'ils sont debout, pas un buff qu'on allume.
	var wall := Minion.wall_of(self) + (_crown.ward() if _crown != null else 0.0)
	if wall > 0.0:
		mods.append(StatMod.new("damage_taken", StatMod.Mode.FLAT, -wall))

	# En trois temps — attributs, dérivation, reste — pour que « +20 force » rapporte ses
	# PV et que « +10 % PV » les multiplie. Ce qui vise un mot-clé part à part, pour le
	# lancer.
	var over_attributes: Array[StatMod] = []
	var on_the_rest: Array[StatMod] = []
	var on_skills: Array[StatMod] = []
	for m in mods:
		# Un accru de chance critique multiplie au lancer la base que la fiche porte : l'arme et les plats.
		if not m.scope.is_empty() or (m.stat == SkillStats.CRIT_CHANCE and m.mode != StatMod.Mode.FLAT):
			on_skills.append(m)
		elif m.stat in CharacterStats.ATTRIBUTES:
			over_attributes.append(m)
		else:
			on_the_rest.append(m)
	StatMod.apply_all(stats, over_attributes)
	stats.apply_attributes()
	StatMod.apply_all(stats, on_the_rest)

	# La force ajoute ses dégâts aux attaques, lue sur la fiche **finale**.
	on_skills.append(StatMod.ranged(
		SkillStats.added_stat(DamageType.Kind.PHYSICAL),
		stats.strength_damage(), stats.strength_damage(), Keywords.ATTACK
	))
	skill_mods = on_skills

	# Un multiplicateur sous 1 transformerait un critique en coup amorti.
	stats.crit_multiplier = maxf(stats.crit_multiplier, 1.0)

	# Ce que le joueur inflige en plus voyage avec ses états : c'est le seul attribut de
	# l'attaquant qui arrive jusqu'à la hurtbox de la cible.
	for kind in StatusEffects.CHANCE_STATS.size():
		var field: String = StatusEffects.CHANCE_STATS[kind]
		if not field.is_empty():
			states.chance_factors[kind] = 1.0 + float(stats.get(field)) * 0.01

	# Réassignée : la hurtbox défendrait sinon avec l'ancienne fiche.
	hurtbox.stats = stats


## Ce que les buffs allumés versent dans la fiche, par point placé : les lignes d'un
## passif, par la même fonction. Un livre parti éteint la case et vide ses lignes.
func buff_mods() -> Array[StatMod]:
	var out: Array[StatMod] = []
	for skill in lit_skills():
		# Une ligne est linéaire en points : ses charges la multiplient de la même façon. Un
		# buff sans charges propres en porte sous le Galop (jalon 43).
		var times := lit_stacks(skill.id) if skill.stacks_max > 0 else maxi(lit_stacks(skill.id), 1)
		out.append_array(skill.buff_mods(skill_points(skill.id) * times))
		# Les lignes de ses nœuds qui ne visent pas un nombre du lancer (jalon 34) : des
		# lignes de buff, aux règles d'un passif, qui ne valent que tant qu'il brûle — et
		# **par charge** sur un buff à charges (jalon 41).
		for t in talents_of(skill.id):
			for m in t.mods():
				if Skill.is_buff_line(m):
					for i in times:
						out.append(m)
	return out


## Ce qui brûle en ce moment, **dans l'ordre d'allumage** : la fiche y prend ses lignes,
## le bandeau ses icônes.
func lit_skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for id: String in _lit:
		if not lit(id):
			continue
		var skill := SkillCatalog.by_id(id)
		if skill != null:
			out.append(skill)
	return out


## Ce qu'il reste à ce geste, entre 0 et 1. **Un pour ce qui dure tant qu'on le paie** —
## une aura, un buff sans durée : le bandeau n'y dessine aucun voile.
func lit_ratio(skill_id: String) -> float:
	var node: Variant = _lit.get(skill_id)
	if not is_instance_valid(node) or not node is Buff:
		return 1.0
	return (node as Buff).remaining_ratio()


## Les charges d'un buff à charges allumé ; zéro pour tout le reste.
func lit_stacks(skill_id: String) -> int:
	var node: Variant = _lit.get(skill_id)
	if not is_instance_valid(node) or not node is Buff:
		return 0
	return (node as Buff).stacks


## Le flacon de cet emplacement, dans l'ordre des touches, ou null.
func flask_in(index: int) -> Item:
	return equipment.get(EquipmentSlots.flasks()[index])


## Boit le flacon de cet emplacement. **Le seul chemin** — touche, tests. Refusé sans
## flacon, sans assez de charges, ou pour un utilitaire dont l'effet dure encore.
func use_flask(index: int) -> bool:
	var flask := flask_in(index)
	if is_dead or flask == null or flask.charges < flask.charges_per_use():
		return false
	var already := drinking(flask)
	if already and flask.base.is_utility_flask():
		return false
	flask.charges -= flask.charges_per_use()
	var sip := Sip.new()
	sip.flask = flask
	sip.left = flask.flask_duration()
	sip.life_per_second = flask.flask_life() / sip.left
	sip.mana_per_second = flask.flask_mana() / sip.left
	_sips.append(sip)
	# Ses lignes entrent dans la fiche, une fois par flacon quel que soit le nombre de gorgées.
	if not already and not flask.mods().is_empty():
		_restat()
	flasks_changed.emit()
	return true


## Ce que rendent les gorgées en cours. Une gorgée finie retire ses lignes à la fiche.
func _drink(delta: float) -> void:
	if _sips.is_empty():
		return
	var life := 0.0
	var mana_back := 0.0
	var ended := false
	for sip in _sips:
		var step := minf(delta, sip.left)
		life += sip.life_per_second * step
		mana_back += sip.mana_per_second * step
		sip.left -= delta
		ended = ended or sip.left <= 0.0
	if life > 0.0:
		_set_health(health + life)
	if mana_back > 0.0:
		_set_mana(mana + mana_back)
	if ended:
		_sips = _sips.filter(func(s: Sip) -> bool: return s.left > 0.0)
		_restat()
		flasks_changed.emit()


func drinking(flask: Item) -> bool:
	return _sips.any(func(s: Sip) -> bool: return s.flask == flask)


## Ce qu'il reste de l'effet le plus long de ce flacon, entre 0 et 1 ; zéro s'il ne coule pas.
func flask_left(flask: Item) -> float:
	var out := 0.0
	for sip in _sips:
		if sip.flask == flask:
			out = maxf(out, sip.left / flask.flask_duration())
	return out


## Les lignes des flacons en cours, une fois par flacon : l'effet d'un utilitaire et ce
## que ses affixes donnent pendant l'effet.
func flask_mods() -> Array[StatMod]:
	var out: Array[StatMod] = []
	var counted: Array[Item] = []
	for sip in _sips:
		if sip.flask in counted:
			continue
		counted.append(sip.flask)
		out.append_array(sip.flask.mods())
	return out


## Une mise à mort remplit chaque flacon porté. Depuis `EnemyManager.report_kill()`.
func gain_flask_charges(enemy_affixes: int) -> void:
	var gained := CHARGES_PER_KILL + CHARGES_PER_AFFIX * float(enemy_affixes)
	for slot in EquipmentSlots.flasks():
		var flask: Item = equipment.get(slot)
		if flask != null:
			flask.charges = minf(flask.charges + gained * flask.charge_gain(), flask.charges_max())
	flasks_changed.emit()


## La ville remplit tout, comme dans PoE.
func refill_flasks() -> void:
	for slot in EquipmentSlots.flasks():
		var flask: Item = equipment.get(slot)
		if flask != null:
			flask.charges = flask.charges_max()
	flasks_changed.emit()


## Les plafonds ont pu bouger avec les lignes du buff, comme à un changement d'objet.
## Publique : un buff dont les charges tombent la rappelle.
func after_buff_change() -> void:
	_bound = ""
	for id: String in _lit:
		if lit(id) and _lit[id] is Buff and (_lit[id] as Buff).binds:
			_bound = id
	_restat()
	buffs_changed.emit()


## La fiche refaite, et la vie et la réserve ramenées sous les nouveaux plafonds.
## Trois chemins écrivaient les trois lignes ; en oublier une laisserait la vie
## au-dessus d'un maximum qui vient de baisser.
func _restat() -> void:
	recompute_stats()
	_set_health(health)
	_set_mana(mana)


## Fait entrer un personnage sauvegardé dans ce corps, après son _ready. **Recopie** et
## non adoption : sac, râtelier et barre restent ceux que l'interface a liés.
func load_character(character: Character) -> void:
	if character == null:
		return

	level = clampi(character.level, 1, MAX_LEVEL)
	xp = character.experience if level < MAX_LEVEL else 0
	xp_to_next = _needed_for(level)
	passives = character.passives.duplicate()

	inventory.clear()
	for placed in character.bag.placed:
		# Sa place d'abord : un sac rechargé se retrouve tel qu'on l'a laissé.
		if not inventory.place(placed.data, placed.cell):
			inventory.add(placed.data)

	equipment.clear()
	for slot in character.equipment:
		# Un emplacement inconnu est écarté : il fausserait la fiche sans s'afficher.
		if EquipmentSlots.exists(slot):
			equipment[slot] = character.equipment[slot]

	# Recopiés comme le sac, pour la même raison.
	rack.copy_from(character.rack)
	for i in SkillBar.SLOT_COUNT:
		bar.put(i, character.bar.id_of(i))
	manual_given = character.manual_given

	sprite.set_archetype(character.archetype())
	var lift := SpriteForge.head_room(character.archetype())
	health_bar.lift = lift
	hurtbox.feedback_lift = lift
	sprite.set_variant(character.silhouette)
	# Recalcul, plafonds et arme visible : trois choses qu'on oublierait à la main.
	_after_equipment_change()
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)

	# Sans ces signaux, HUD et fiche attendraient le premier ennemi tué.
	xp_changed.emit(xp, xp_to_next, level)
	passives_changed.emit()


## L'inverse, avant l'écriture : rien de calculé.
func fill(character: Character) -> void:
	if character == null:
		return
	character.level = level
	character.experience = xp
	character.passives = passives.duplicate()
	character.silhouette = sprite.current_variant()

	character.bag = Inventory.new(inventory.cols, inventory.rows)
	for placed in inventory.placed:
		character.bag.place(placed.data, placed.cell)
	character.equipment = equipment.duplicate()

	character.rack = Rack.new()
	character.rack.copy_from(rack)
	character.bar = SkillBar.new()
	for i in SkillBar.SLOT_COUNT:
		character.bar.put(i, bar.id_of(i))
	character.manual_given = manual_given


## Porte un objet et rend celui qu'il remplace. `slot` vide : le premier libre
## (le ramassage) ; le panneau impose le sien. Rend l'objet lui-même s'il est refusé.
func equip(item: Item, slot := "") -> Item:
	if item == null:
		return null
	var target := slot if not slot.is_empty() else EquipmentSlots.free_for(item, equipment)
	if target.is_empty() or not EquipmentSlots.accepts(target, item):
		return item
	var old: Item = equipment.get(target)
	equipment[target] = item
	_after_equipment_change()
	return old


## Le pendant d'`equip()` pour ce qui se lit : l'objet refusé est rendu. `index` à -1 :
## la place de son double s'il est posé, puis le premier emplacement libre, à défaut le
## premier — jamais celui de la classe.
func study(item: Item, index := -1) -> Item:
	if not Rack.accepts(item):
		return item
	if index < 0:
		var twin := rack.slot_of(item)
		index = twin if twin >= 0 else rack.free_slot()
	var old := rack.put(index, item)
	# Un manuel porte des passifs : le poser change la fiche.
	_after_equipment_change()
	return old


## Retire un manuel et **vide les cases de barre de ses compétences** : une case grisée
## se découvre au pire moment. Le seul chemin (page, rechargement).
func stop_studying(index: int) -> Item:
	var gone := rack.remove(index)
	if gone == null or gone.base.manual == null:
		return gone

	_clear_bar_of(gone.base.manual.skills())
	# Et ses passifs s'en vont avec lui.
	_after_equipment_change()
	return gone


## « La sait-on encore » : un remboursement laisse en barre ce qui garde un point.
func _clear_bar_of(skills: Array[Skill]) -> void:
	for skill in skills:
		if skill_points(skill.id) > 0:
			continue
		for i in SkillBar.SLOT_COUNT:
			if bar.id_of(i) == skill.id:
				bar.clear(i)


func unequip(slot: String) -> Item:
	var item: Item = equipment.get(slot)
	if item == null:
		return null
	equipment.erase(slot)
	_after_equipment_change()
	return item


func equipped(slot: String) -> Item:
	return equipment.get(slot)


func remaining_passive_points() -> int:
	return PassiveTree.remaining_points(passives, level)


## Les deux seuls chemins de l'arbre ; les conditions sont dans `PassiveTree`.
func take_passive(id: String) -> bool:
	if not passive_tree.can_take(passives, id, level):
		return false
	passives.append(id)
	_after_passives_change()
	return true


func release_passive(id: String) -> bool:
	if not passive_tree.can_release(passives, id):
		return false
	passives.remove_at(passives.find(id))
	_after_passives_change()
	return true


## Les plafonds ont bougé : un nœud de PV ou de mana les change.
func _after_passives_change() -> void:
	_restat()
	passives_changed.emit()


## La fiche change, donc les plafonds : la vie courante redescend sous le nouveau. Un
## manuel passe par ici aussi, ses passifs étant une pièce d'armure.
func _after_equipment_change() -> void:
	_restat()
	sprite.set_weapon(weapon_kind())
	equipment_changed.emit()


## L'arme visible, vide pour celle de la fiche. Publique : la fenêtre de personnage
## dessine la même silhouette.
func weapon_kind() -> String:
	var base := _weapon_base()
	return "" if base == null else base.kind


func _weapon_base() -> ItemBase:
	var weapon: Item = equipment.get(EquipmentSlots.WEAPON)
	return null if weapon == null else weapon.base


## **Le seul chemin pour changer la vie** : la barre suit, le plafond s'applique.
func _set_health(value: float) -> void:
	health = clampf(value, 0.0, stats.max_health)
	health_bar.set_health(health, stats.max_health)
	health_changed.emit(health, stats.max_health)


## Le pendant du précédent pour la réserve, plafond compris.
func _set_mana(value: float) -> void:
	mana = clampf(value, 0.0, stats.max_mana)
	mana_changed.emit(mana, stats.max_mana)


func _needed_for(lvl: int) -> int:
	return 0 if lvl >= MAX_LEVEL else Progression.level_cost(lvl, XP_BASE, XP_POWER)


## Appelée par l'EnemyManager quand un ennemi meurt d'un vrai coup.
func gain_xp(amount: int) -> void:
	if is_dead or amount <= 0 or level >= MAX_LEVEL:
		return
	xp += amount
	# Une boucle et non un test : un ennemi qui vaut beaucoup peut faire monter
	# de deux niveaux d'un coup.
	while level < MAX_LEVEL and xp >= xp_to_next:
		xp -= xp_to_next
		_level_up()
	if level >= MAX_LEVEL:
		xp = 0
	xp_changed.emit(xp, xp_to_next, level)


func _level_up() -> void:
	level += 1
	xp_to_next = _needed_for(level)
	passives_changed.emit()
	_set_health(health + stats.max_health * LEVEL_HEAL)
	_set_mana(mana + stats.max_mana * LEVEL_HEAL)
	leveled_up.emit(level)


## **Le seul chemin** d'une récompense, mort ou boule d'expérience : le retard sur la
## zone, puis le joueur et les manuels du râtelier, **du même montant**. Rien ne la
## borne vers le haut : descendre plus bas rapporte mieux.
func reward(raw: float, zone_level_value: int, where: Vector2) -> int:
	var gain := maxi(roundi(raw * Enemy.experience_factor(zone_level_value, level)), 1)
	gain_xp(gain)
	for book in rack.equipped_items():
		book.manual.gain_experience(gain)
	if HitFeedback.current != null:
		HitFeedback.current.xp_gain(where, gain)
	return gain


## Faux quand le sac est plein : l'objet reste au sol.
func pick_up(item: Item) -> bool:
	if item == null:
		return false
	var taken := inventory.add(item)
	# Le livre de départ est « donné » quand il est **pris**, pas quand il tombe ; un
	# joueur qui le jette n'en reçoit pas un second.
	if taken and item.manual != null:
		manual_given = true
	if HitFeedback.current != null:
		HitFeedback.current.loot_gain(
			hurtbox.overhead(), item.display_name() if taken else Texts.t("sac plein")
		)
	return taken


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area is Hurtbox or area in _already_hit:
		return
	_already_hit.append(area)   # un swing ne touche une cible qu'une fois

	var info := DamageInfo.roll(
		_hit_cast, global_position, _hit_parts, stats.knockback_force + _hit_cast.knockback
	)
	info.author = states
	(area as Hurtbox).take_damage(info)
	heal(_hit_cast.life_on_hit)

	# **Au premier touché seulement** : un balayage est un geste, pas cinq.
	if _already_hit.size() == 1:
		Game.hit_stop()
		Game.shake_camera(camera, _hit_shake)


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return
	_set_health(health - info.amount + RagDoll.shoulder(self, info.amount))
	velocity += (global_position - info.source_position).normalized() * info.knockback
	sprite.flash()
	if health <= 0.0:
		_die()


## Le drapeau évite plusieurs `died` : plusieurs grunts frappent dans la même image.
func _die() -> void:
	if is_dead or _reborn():
		return
	is_dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	# Ce qui brûlait pour lui s'éteint avec lui.
	for id: String in _lit.keys():
		extinguish(id)
	if _crown != null:
		_crown.clear()
	# Un corps relevé ne se relève pas en flammes, ni une gorgée à la main.
	states.clear()
	if not _sips.is_empty():
		_sips.clear()
		_restat()
		flasks_changed.emit()
	died.emit()   # l'écran de fin de run se branchera ici


## La Renaissance : un brasier allumé qui la porte retient le coup fatal, une fois par
## `REBIRTH_PERIOD`, et explose de toute sa force. **Depuis un rappel de collision**
## parfois : l'explosion se pose d'elle-même en différé.
func _reborn() -> bool:
	if _rebirth_wait > 0.0:
		return false
	for skill in lit_skills():
		var cast := resolve(skill, skill_points(skill.id))
		if cast.rebirth <= 0.0:
			continue
		_rebirth_wait = SkillStats.REBIRTH_PERIOD
		_set_health(stats.max_health * SkillStats.REBIRTH_HEALTH)
		if cast.phoenix_ashes > 0.0:
			phoenix_ashes = SkillStats.ASHES_TIME
		Explosion.put(
			_effects_parent(), global_position, cast.roll(Game.rng),
			cast.radius * SkillStats.REBIRTH_REACH, null, DamageType.COLORS[cast.nature], states, cast
		)
		return true
	return false


func revive() -> void:
	is_dead = false
	# Un corps tombé encaisse toujours : ses tirages ont pu reposer des états.
	states.clear()
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)
	velocity = Vector2.ZERO
	set_physics_process(true)
