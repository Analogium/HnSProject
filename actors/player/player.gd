class_name Player
extends CharacterBody3D

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
## Le clic-déplacement (jalon 54) : arrivé à ce rayon du point cliqué, on s'arrête.
const WALK_ARRIVAL := 4.0

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
## La caméra façon Torchlight Infinite, sur une capture du jeu (jalon 54) : champ vertical,
## inclinaison — et le lissage de la caméra 2D d'avant. Le recul se déduit du cadre 2D.
const CAMERA_FOV := 40.0
const CAMERA_PITCH := 55.0
const CAMERA_SMOOTHING := 8.0
## La molette rapproche la caméra, comme dans Path of Exile : le cadre par défaut est le plus
## large — il fixe ce que le jeu montre —, on n'avance que jusqu'au quart du recul.
const CAMERA_ZOOM_MIN := 0.25
const CAMERA_ZOOM_STEP := 0.85
## Ce qui distingue une frappe lourde d'un coup d'épée au toucher, en plus du dessin.
const STRIKE_SHAKE := 2.0
## De combien on recule le long de la visée quand l'arrivée d'une ruée est prise. Huit
## pixels : plus fin ne se voit pas, plus gros fait rater une embrasure.
const LANDING_STEP := 8.0
## Où une frappe vive s'arrête devant sa cible, de centre à centre : les deux corps se
## touchent sans se chevaucher.
const LUNGE_REACH := 14.0

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
## Les couteaux des Lames de jet (jalon 50).
@export var knife_scene: PackedScene
## Secousse de caméra à l'impact. 0 pour la couper.
@export var shake_amount: float = 2.0

@onready var model: ActorModel = $Model
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health_bar: HealthBar = $HealthBar
@onready var attack_pivot: Node3D = $AttackPivot
@onready var hitbox: Area3D = $AttackPivot/Hitbox
@onready var _hit_shape: CollisionShape3D = $AttackPivot/Hitbox/CollisionShape3D
@onready var swing_arc: SwingArc = $AttackPivot/SwingArc
@onready var camera: Camera3D = $Camera3D
## Le corps, pour chercher où une ruée peut atterrir.
@onready var body_shape: CollisionShape3D = $CollisionShape3D

## Où atterrissent les tirs du joueur. Posé par la scène (zone ou arène) ;
## à défaut, ils naissent à côté du joueur.
var projectile_parent: Node3D

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
## `Character.instrument()`, recopié au chargement : vide, l'arme sert à tout.
var instrument := ""

## Ce que l'équipement donne aux compétences d'un mot-clé, reconstruit par
## `recompute_stats()` et lu à chaque lancer.
var skill_mods: Array[StatMod] = []

var health: float
var mana: float
var is_dead := false
## Ses états, comme ceux d'un ennemi.
var states := StatusEffects.new()
var facing := Vector3.RIGHT
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


## Le geste du corps (jalon 47) : **un seul à la fois**, sinon deux cases alternées
## doublent la cadence. Le coup d'une attaque attend son impact (`Skill.GESTURE`).
class Gesture:
	var left: float
	var to_impact := 0.0
	## Le `_pose()` qui reste à porter ; vide une fois porté, ou d'emblée pour un sort.
	var strike := Callable()

	func _init(length: float) -> void:
		left = length

var _gesture: Gesture
## Les gestes entretenus allumés, par identifiant de compétence : une aura et les
## buffs. Leurs nœuds vivent sous le joueur ; le dictionnaire dit lequel répond à
## quelle case.
var _lit := {}
## Le prochain tour des compétences qui changent de nature à chaque lancer, par
## identifiant. Jamais sauvegardé : on recommence par le premier élément.
var _turns := {}
## La dernière Signature, en images de physique.
var _signed_at := -1_000_000
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
## Le Glacier (jalon 44) : les lancers comptés. Le Coup sûr (jalon 46) : les siens.
var _glacier := 0
var _sure := 0
## L'Apnée (jalon 45) : l'heure du jeu, et celle du dernier lancer de chaque compétence.
var _clock := 0.0
var _last_cast := {}
## Le Sursis (jalon 45) : l'attente avant qu'il puisse revenir.
var _reprieve_wait := 0.0
## La Riposte (jalon 46) : le temps qui reste après un coup reçu.
var _riposte_left := 0.0
## La Contre-attaque (jalon 50) : l'attente avant la riposte suivante ; les Pas de côté
## cumulés et ce qu'il leur reste ; ce qu'il reste au Contretemps armé.
var _counter_wait := 0.0
var _sidesteps := 0
var _sidestep_left := 0.0
var _counter_time_left := 0.0
## La Relance et l'Hallali (jalon 46) : les relances d'affilée, et si la dernière ruée en a
## gagné une. Le Pas chassé : les ruées enchaînées, et l'heure de la dernière.
var _hallali := 0
var _relaunched := false
var _chasse := 0
var _last_chasse := -INF
## Le coup du geste en cours : le second d'une croix vide le saignement (jalon 46).
var _hit_index := 0
## La Glace noire (jalon 44) : le dernier sol de la nova, son centre, son rayon, ce qu'il
## lui reste, ce qu'il donne. Le Sursaut : l'attente avant le suivant.
var _black_ice_at := Vector3.ZERO
var _black_ice_radius := 0.0
var _black_ice_left := 0.0
var _black_ice := 0.0
var _startle_wait := 0.0
## L'Accalmie (jalon 44) : ce qu'elle retire aux dégâts subis, tant qu'on est dans l'œil.
var _calm := 0.0
## L'Égide (jalon 48) : ce que la dernière onde de la Pulsation retire aux dégâts subis.
var _aegis := 0.0
## La Tension accumulée (jalon 43) : le « plus » que porte le prochain sort de foudre, et le
## temps qu'il reste pour le lancer.
var _tension := 0.0
var _tension_left := 0.0
## Le Condensateur (jalon 43) : les morsures de charges comptées, et ce qu'elles ont mordu,
## que la Décharge totale rend d'un coup. La Cage de Faraday : son attente. Ce qui reste
## d'une invulnérabilité posée par elle ou par la Voltige (jalon 46).
var _condensed := 0
var _condensed_power := 0.0
var _untouchable_left := 0.0
var _faraday_wait := 0.0
var _already_hit: Array[Node] = []
## Le Festin résolu tant qu'il brûle, null sinon (jalon 53) : le Banquet et les morts rongées le
## lisent à chaque image. Refait avec la fiche. `_gnaw_base` : le rongement hors Ventre creux.
var _feast: SkillStats
var _gnaw_base := 1.0
## La planche du joueur hors du règne, gardée le temps qu'il est Roi des Rats.
var _look := ""
## Les morts du règne en cours : la Légende y lit la taille du Roi.
var _reign_kills := 0
## Souris = visée au curseur, manette = visée dans la direction du stick.
var _aim_with_mouse := true
## La part du recul de la caméra, 1 au cadre par défaut ; la molette la règle.
var camera_zoom := 1.0
## Le point où mène le clic gauche, tant que `_walking` ; `_steering` tant que le bouton
## reste enfoncé, et le point suit alors le curseur.
var _walk_to := Vector3.ZERO
var _walking := false
var _steering := false


## Une gorgée en cours. Deux gorgées de vie se cumulent, comme dans PoE 1.
class Sip:
	var flask: Item
	var left: float
	var life_per_second: float
	var mana_per_second: float

var _sips: Array[Sip] = []


func _ready() -> void:
	# Hors de la hiérarchie pour suivre en douceur ; posée sur le joueur dès la naissance.
	camera.top_level = true
	camera.fov = CAMERA_FOV
	camera.global_position = global_position + _camera_offset()
	camera.look_at(global_position)
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
	hurtbox.evaded.connect(_on_evaded)
	hurtbox.states = states
	states.struck.connect(_on_struck)
	states.slew.connect(_on_slew)
	states.critical.connect(_on_critical)
	states.change.connect(_show_states)
	states.reached.connect(_announce_state)
	states.heal.connect(heal)
	states.fell.connect(_on_fell)
	states.gnawed.connect(_on_gnawed)


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
	var walk := _walk_click(event)
	if walk:
		_walk_to = Flat.under_mouse(get_viewport())
		_walking = true
		_steering = true
	for i in SkillBar.SLOT_COUNT:
		var action := "skill_%d" % (i + 1)
		if event.is_action_pressed(action) and not walk and not _click_taken(action):
			_held[i] = true
			# Un coup interrompt la marche vers un point ; bouton tenu, elle reprend.
			_walking = _steering
	var wheel := event as InputEventMouseButton
	if wheel != null and wheel.pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var step := CAMERA_ZOOM_STEP if wheel.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / CAMERA_ZOOM_STEP
		camera_zoom = clampf(camera_zoom * step, CAMERA_ZOOM_MIN, 1.0)


## La caméra rejoint le joueur au rythme de l'image, pas de la physique : comme la caméra 2D.
func _process(delta: float) -> void:
	var goal := global_position + _camera_offset()
	camera.global_position = camera.global_position.lerp(goal, 1.0 - exp(-CAMERA_SMOOTHING * delta))
	_show_through()


## Ce qui passe entre la caméra et le corps s'estompe autour de lui (`terrain.gdshader`) : le
## centre de l'écran à sa poitrine, et sa profondeur de vue.
func _show_through() -> void:
	var chest := global_position + Vector3.UP * SpriteForge.CENTER_ABOVE_FEET
	var screen := get_viewport().get_visible_rect().size
	RenderingServer.global_shader_parameter_set(&"fade_center", camera.unproject_position(chest) / screen)
	RenderingServer.global_shader_parameter_set(&"fade_depth", -(camera.global_transform.affine_inverse() * chest).z)


## Au plan du joueur, le monde qu'en montrait la caméra 2D (360 px au zoom du monde) : les
## sprites y gardent leur taille d'avant, et les portées leur place à l'écran.
func _camera_offset() -> Vector3:
	var height := float(ProjectSettings.get_setting("display/window/size/viewport_height")) / Game.WORLD_ZOOM
	var distance := height * 0.5 / tan(deg_to_rad(CAMERA_FOV) * 0.5) * camera_zoom
	var pitch := deg_to_rad(CAMERA_PITCH)
	return Vector3(0.0, sin(pitch), cos(pitch)) * distance


func _physics_process(delta: float) -> void:
	# Le gel ralentit la recharge des cinq cases ici, la marche plus bas.
	var cadence := states.speed_factor
	for i in _recharges.size():
		_recharges[i] = maxf(_recharges[i] - delta * cadence, 0.0)
	_rebirth_wait = maxf(_rebirth_wait - delta, 0.0)
	_clock += delta
	_reprieve_wait = maxf(_reprieve_wait - delta, 0.0)
	_riposte_left = maxf(_riposte_left - delta, 0.0)
	_counter_wait = maxf(_counter_wait - delta, 0.0)
	_counter_time_left = maxf(_counter_time_left - delta, 0.0)
	if _sidesteps > 0:
		_sidestep_left -= delta
		if _sidestep_left <= 0.0:
			_sidesteps = 0
			after_buff_change()
	for index: int in _strides.keys():
		_strides[index] -= delta
		if _strides[index] <= 0.0:
			_strides.erase(index)
	phoenix_ashes = maxf(phoenix_ashes - delta, 0.0)
	_ramp_idle += delta
	_tension_left = maxf(_tension_left - delta, 0.0)
	_faraday_wait = maxf(_faraday_wait - delta, 0.0)
	_black_ice_left = maxf(_black_ice_left - delta, 0.0)
	_startle_wait = maxf(_startle_wait - delta, 0.0)
	var calm := IceVortex.calm_for(global_position, states)
	if calm != _calm:
		_calm = calm
		_restat()
	if _untouchable_left > 0.0:
		_untouchable_left -= delta
		if _untouchable_left <= 0.0:
			hurtbox.invulnerable = false

	_regen(delta)
	_drink(delta)
	_feed_rats()
	_suffer_states(delta)
	if is_dead:
		_gesture = null
		halt()
		return
	if _gesture != null:
		_tick_gesture(delta * cadence)

	var stick := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input := Vector3(stick.x, 0.0, stick.y)
	if _steering:
		_steering = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if _steering:
			_walk_to = Flat.under_mouse(get_viewport())
			_walking = true
	# Les touches reprennent la main sur le clic.
	if input != Vector3.ZERO:
		_walking = false
	elif _walking:
		var to := _walk_to - global_position
		to.y = 0.0
		if to.length() > WALK_ARRIVAL:
			input = to.normalized()
		elif not _steering:
			_walking = false
	# Enfermé dans la glace : la visée et le sprite suivent encore, les pieds non. Et
	# ZQSD tapé dans un champ de texte — la recherche de l'arbre — ne fait pas marcher.
	# Un geste arrête le corps, comme dans PoE : la marche tenue reprend après lui.
	if not _bound.is_empty() or get_viewport().gui_get_focus_owner() is LineEdit \
			or _gesture != null or _is_swinging:
		input = Vector3.ZERO

	if _aim_with_mouse:
		var to_mouse := Flat.under_mouse(get_viewport()) - global_position
		if to_mouse.length() > 4.0:
			facing = to_mouse.normalized()
	elif input != Vector3.ZERO:
		facing = input.normalized()

	attack_pivot.rotation.y = -Flat.angle(facing)
	# Le corps regarde où il va, comme dans PoE ; la visée ne le tourne que pour frapper.
	var moving := input != Vector3.ZERO
	model.set_state(moving, input if moving else facing)

	var speed := stats.move_speed * cadence
	if _black_ice_left > 0.0 and global_position.distance_to(_black_ice_at) <= _black_ice_radius:
		speed *= 1.0 + _black_ice * 0.01
	if input != Vector3.ZERO:
		velocity = velocity.lerp(input.normalized() * speed, ACCEL)
	else:
		velocity = velocity.lerp(Vector3.ZERO, FRICTION)

	move_and_slide()

	# Sondage des cinq cases. Tenue, la touche relance à chaque fin de recharge : la
	# cadence est celle de `cast_slot()`. Un survol qui réclame le clic **suspend** la
	# case sans la désarmer : seul le relâchement désarme.
	for i in SkillBar.SLOT_COUNT:
		var action := "skill_%d" % (i + 1)
		if not Input.is_action_pressed(action):
			_held[i] = false
		elif _held[i] and not _click_taken(action):
			cast_slot(i)


## Au rythme des recharges : le gel ralentit le geste comme il ralentit les cases.
func _tick_gesture(step: float) -> void:
	_gesture.left -= step
	_gesture.to_impact -= step
	if _gesture.strike.is_valid() and _gesture.to_impact <= 0.0:
		var strike := _gesture.strike
		_gesture.strike = Callable()
		strike.call()
	if _gesture.left <= 0.0:
		_gesture = null


## Un panneau tient la souris, ou une étiquette de butin, un marchand ou un portail
## réclame le clic gauche.
func _click_taken(action: String) -> bool:
	return Game.ui_grabs_input or GroundItem.takes_the_click(action) \
			or Interactable.takes_the_click(action)


## À la souris (`Settings.control_mode`), le clic gauche fait marcher, et rien d'autre ;
## le butin, les PNJ et l'interface le prennent avant.
func _walk_click(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	if Settings.control_mode != Keybinds.MOUSE or click == null or not click.pressed \
			or click.button_index != MOUSE_BUTTON_LEFT:
		return false
	return not (Game.ui_grabs_input or GroundItem.hovered != null or Interactable.hovered != null)


## Oublie le point cliqué : à la mort, et quand la zone change sous les pieds.
func halt() -> void:
	_walking = false
	_steering = false


## Lance la compétence de cette case. **Le seul chemin** — touches, barre, tests — et
## il porte les neuf refus : case vide, non apprise, geste en cours, mauvaise arme, réserve,
## recharge, orbite pleine, morts-vivants au complet, frappe vive sans personne à portée.
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
	# Sous la Nécrose (jalon 45) : la Faucheuse divise le coût des sorts nécrotiques, la Lente
	# agonie les allonge, eux et ce qu'ils posent, le Moribond les renforce à bout de vie.
	if cast.nature == DamageType.Kind.NECROTIC and skill.id != SkillStats.NECROSIS_SKILL:
		var necrosis := _necrosis()
		if necrosis != null:
			if necrosis.reaper > 0.0:
				cast.mana_cost *= SkillStats.REAPER_COST
			var longer := necrosis.slow_agony * 0.01
			cast.duration *= 1.0 + longer
			if cast.inflicted_state >= 0:
				cast.languor += StatusEffects.DURATIONS[cast.inflicted_state] * longer
			if necrosis.moribund > 0.0 and health < stats.max_health * SkillStats.MORIBUND_LIFE:
				cast = cast.echoed(1.0 + necrosis.moribund * 0.01)
	if skill.strikes():
		cast = devoted(cast)
	# Sous le Roi des Rats (jalon 53), le Coup de croc mord en nécrotique, et draine.
	if skill.id == SkillStats.BITE_SKILL and reigns():
		cast = cast.echoed(1.0)
		cast.blend([DamageType.Kind.NECROTIC] as Array[int])
		cast.nature = DamageType.Kind.NECROTIC

	if cast.sustained:
		# Tenir la touche n'alterne pas : un geste entretenu qui clignote serait
		# inutilisable.
		_held[index] = false
		if lit(skill.id):
			# Éteindre n'est pas lancer : ni coût, la recharge seulement contre le rebond.
			extinguish(skill.id)
			_start_recharge(index, cast.interval)
			return true
	if _gesture != null:
		return false
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
	# Sauf le Rappel (jalon 45), qui remet sur pied ceux qui sont debout.
	if skill.shape == Skill.Shape.SUMMON and cast.recall <= 0.0 \
			and Minion.count_of(self, skill.id) >= Minion.cap(cast):
		return false
	# Le Coup de grâce aussi (jalon 50) : parti dans le vide, il brûlerait les charges.
	if skill.shape in [Skill.Shape.LUNGE, Skill.Shape.FINISHER] and _lunge_target(cast) == null:
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
	# Le Glacier (jalon 44) : un lancer sur trois, ou sur deux sous le Sérac.
	if cast.glacier > 0.0:
		_glacier += 1
		if _glacier % (SkillStats.SERAC_EVERY if cast.serac > 0.0 else SkillStats.GLACIER_EVERY) == 0:
			cast = cast.swollen(1.0 + SkillStats.GLACIER_MORE * 0.01, SkillStats.GLACIER_RADIUS)
	# Le Coup sûr (jalon 46) : un lancer sur trois, critique à coup sûr.
	if cast.sure_strike > 0.0:
		_sure += 1
		if _sure % SkillStats.SURE_EVERY == 0:
			cast = cast.echoed(1.0)
			cast.crit_chance = 1.0
			cast.is_sure = true
	# Le Contretemps (jalon 50) : une esquive arme l'attaque suivante d'un critique sûr.
	if _counter_time_left > 0.0 and skill.cadence == Skill.Cadence.WEAPON and skill.strikes() \
			and not cast.sustained:
		var counter := resolve(SkillCatalog.by_id(SkillStats.COUNTER_SKILL), skill_points(SkillStats.COUNTER_SKILL))
		cast = cast.echoed(1.0 + counter.fencing_time * 0.01)
		cast.crit_chance = 1.0
		_counter_time_left = 0.0
	# La Relance et l'Hallali (jalon 46) : la ruée rendue par un tué frappe plus fort ; une
	# ruée lancée sans relance remet le compte à zéro.
	if cast.relaunch > 0.0:
		if not _relaunched:
			_hallali = 0
		_relaunched = false
		if cast.hallali > 0.0 and _hallali > 0:
			cast = cast.echoed(1.0 + cast.hallali * 0.01 * float(_hallali))
	# Le Pas chassé (jalon 46) : une ruée qui suit la précédente de près frappe plus fort.
	if cast.chasse > 0.0:
		var chained := _clock - _last_chasse <= SkillStats.CHASSE_WINDOW
		_chasse = mini(_chasse + 1, SkillStats.CHASSE_MOST) if chained else 0
		_last_chasse = _clock
		cast = cast.echoed(1.0 + cast.chasse * 0.01 * float(_chasse))
	# La Riposte (jalon 46) : un coup reçu depuis peu, et la croix suivante le rend.
	if cast.riposte > 0.0 and _riposte_left > 0.0:
		cast = cast.echoed(1.0 + cast.riposte * 0.01)
		_riposte_left = 0.0
	# L'Apnée (jalon 45) : plus fort à chaque seconde depuis le précédent ; le premier, au plein.
	if cast.apnea > 0.0:
		var most := SkillStats.DEEP_DIVE_MOST if cast.deep_dive > 0.0 else SkillStats.APNEA_MOST
		var held := minf(_clock - float(_last_cast.get(skill.id, -INF)), most)
		_last_cast[skill.id] = _clock
		cast = cast.echoed(1.0 + cast.apnea * 0.01 * held)
	var salvo := _salvo(skill, points, cast)
	var spell := skill.cadence == Skill.Cadence.CAST and skill.strikes()
	if spell:
		_incarnate(salvo)
		_chord(salvo)
		_diapason(salvo)
	if not skill.nature_cycle.is_empty():
		_turns[skill.id] = int(_turns.get(skill.id, 0)) + 1
	# Tout lancer anime le lanceur sur son geste, et ce geste prend le corps. Pas la ruée,
	# où le corps traverse l'écran : son temps de geste n'espace que sa case (le Choc
	# d'arrivée en fait une recharge).
	var family: String = Skill.GESTURE.get(cast.shape, "")
	if cast.shape not in [Skill.Shape.DASH, Skill.Shape.LEAP]:
		if cast.use_time > 0.0:
			_gesture = Gesture.new(cast.use_time)
		# Le corps, tourné vers où il marchait, fait face à la visée pour frapper.
		model.set_state(false, facing)
		# Une image de physique de plus : le geste finit sur une image de physique, jusqu'à une
		# après son temps exact ; plus court, le corps retombait au repos une image par coup.
		model.attack(
			skill.cadence == Skill.Cadence.CAST,
			cast.use_time / maxf(states.speed_factor, 0.01) + 1.0 / Engine.physics_ticks_per_second,
			family, held_for(skill.id)
		)
	var aim := _aim_point()
	var pose := _pose.bind(skill, salvo, self, facing, aim)
	if _gesture != null and not family.is_empty():
		_gesture.to_impact = cast.use_time * model.impact_of(family)
		_gesture.strike = pose
	else:
		pose.call()
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
	var incarnated := _incarnation_of(skill)
	for i in range(1, cast.projectile_count()):
		out.append(skill.resolve(points, stats, skill_mods, talents_of(skill.id), turn + i, incarnated))
	# Le Chatoiement (jalon 49) : chaque rebond d'un trait avance d'un tour sur le précédent.
	if cast.shimmer > 0.0:
		for i in out.size():
			for k in range(1, int(cast.bounces) + 1):
				out[i].bounce_turns.append(skill.resolve(
					points, stats, skill_mods, talents_of(skill.id), turn + i + k, incarnated
				))
	return out


## **Ce qu'un lancer pose dans le monde**, depuis `origin` vers `toward` et le point visé :
## le joueur, ou l'épaule du Familier qui rejoue un sort (jalon 41). Le premier lancer de
## la salve sert à tout ce qui n'est pas une volée de projectiles.
func _pose(
	skill: Skill, salvo: Array[SkillStats], origin: Node3D, toward: Vector3, aim: Vector3
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
		Skill.Shape.KNIVES:
			_roll(salvo, knife_scene, origin, toward)
			# La Seconde salve (jalon 50) : la même volée, plus faible, un instant après.
			if cast.second_volley > 0.0:
				var volley: Array[SkillStats] = [cast.echoed(SkillStats.VOLLEY_PART)]
				volley[0].second_volley = 0.0
				get_tree().create_timer(SkillStats.VOLLEY_GAP, false).timeout.connect(
					func() -> void:
						if not is_dead:
							_roll(volley, knife_scene, self, facing)
				)
		Skill.Shape.FROST_ORB:
			for direction in _spread(cast, toward):
				FrozenOrb.send(parent, at, direction, cast, states, origin, bolt_scene, aim, self)
		Skill.Shape.ORB:
			var directions := _spread(cast, toward)
			# Le Satellite (jalon 43) : répartis autour du lanceur, pas en éventail.
			if cast.satellite > 0.0:
				for i in directions.size():
					directions[i] = Flat.rotated(toward, TAU * float(i) / float(directions.size()))
			for direction in directions:
				StaticOrb.send(parent, at, direction, cast, states, origin)
		Skill.Shape.METEOR:
			# Plusieurs boules deviennent une rangée de météores en travers de la visée, à
			# un rayon l'un de l'autre : leurs explosions se chevauchent de moitié.
			var count := cast.projectile_count()
			for i in count:
				var across := Flat.orthogonal(toward) * (float(i) - float(count - 1) * 0.5) * cast.radius
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
				HellSnake.drop(parent, aim, cast, Flat.rotated(toward, turn), states, origin)
		Skill.Shape.AURA:
			_light(skill.id, Immolation.ignite(self, skill))
		Skill.Shape.BUFF:
			# Sa durée, ou zéro : un buff sans durée brûle tant qu'on le paie. Le règne du Roi
			# des Rats dure d'autant plus qu'il a consommé de rats.
			var lifetime := cast.duration + (_consume_rats(cast) if skill.id == SkillStats.KING_SKILL else 0.0)
			var buff := Buff.light(self, skill, lifetime, cast.binds_caster)
			if skill.id == SkillStats.KING_SKILL:
				_reign(true)
			# L'Incarnation (jalon 49) : l'élément du dernier sort, le feu s'il n'y en a pas.
			if cast.incarnation > 0.0:
				buff.incarnation = _last_spell_nature if _last_spell_nature in DamageType.ELEMENTS \
						else DamageType.ELEMENTS[0]
			_light(skill.id, buff)
			# Le Refuge (jalon 44) : entrer dans la glace éteint ce que l'on porte.
			if cast.refuge > 0.0:
				states.clear()
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
				SlashWave.send(parent, global_position, Flat.rotated(facing, turn), cast, states, self)
		Skill.Shape.SLAM:
			_slam(cast)
		Skill.Shape.SPIKES:
			IceSpikes.grove(parent, aim, toward, cast, states, origin, bolt_scene)
			if cast.crystallize > 0.0:
				IceVortex.feed(aim, states, SkillStats.CRYSTALLIZE_TIME)
		Skill.Shape.FISSURE:
			IceSpikes.fissure(parent, at, aim, cast, states, origin, bolt_scene)
			if cast.crystallize > 0.0:
				IceVortex.feed(aim, states, SkillStats.CRYSTALLIZE_TIME)
		Skill.Shape.NOVA:
			# L'explosion de la boule de feu, posée sur soi : elle frappe une fois son
			# cercle et s'efface, ce qu'une nova fait exactement. Son sol a sa taille.
			var nova := Explosion.of_cast(parent, at, cast, cast.radius, states)
			nova.knockback = cast.knockback
			nova.crowd = cast.deep_cold
			nova.drink = stats.max_health * cast.suction * 0.01
			if cast.detonation > 0.0:
				RottingGate.detonate(at, cast.radius, states, 1.0 + cast.detonation * 0.01)
			if cast.ground_duration > 0.0:
				DashTrail.patch(parent, at, cast.ground(cast.radius), states)
				if cast.black_ice > 0.0 and origin == self:
					_black_ice_at = at
					_black_ice_radius = cast.radius
					_black_ice_left = cast.ground_duration
					_black_ice = cast.black_ice
		Skill.Shape.RING:
			FrostRing.spread(parent, at, cast, states)
		Skill.Shape.VORTEX, Skill.Shape.IMPLOSION:
			IceVortex.open(parent, at, cast, states, aim)
		Skill.Shape.CHAINS:
			JudgmentChains.throw(parent, at, toward, cast, states)
		Skill.Shape.SCAPEGOAT:
			JudgmentChains.bind(parent, self, cast, states)
		Skill.Shape.HAMMER:
			# Le Carillon (jalon 48) : des marteaux en étoile, le premier vers la visée.
			var count := 1 + int(cast.hammers)
			for i in count:
				BlessedHammer.swing(
					parent, at, Flat.angle(toward) + TAU * float(i) / float(count), cast, states, origin, i
				)
		Skill.Shape.PILLAR, Skill.Shape.DRIFT:
			# Le Triptyque (jalon 48) : trois colonnes en triangle autour du point visé.
			if cast.triptych > 0.0:
				for i in SkillStats.TRIPTYCH_COUNT:
					var corner := Flat.rotated(Vector3.FORWARD, TAU * float(i) / float(SkillStats.TRIPTYCH_COUNT))
					SacredPillar.fall(
						parent, aim + corner * cast.radius * SkillStats.TRIPTYCH_SPREAD, cast, states, self
					)
			else:
				SacredPillar.fall(parent, aim, cast, states, self)
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
			RottingGate.open(parent, aim, cast, states, null, self)
		Skill.Shape.NEST:
			RottingGate.open(parent, global_position, cast, states, self, self)
		Skill.Shape.CURSE, Skill.Shape.MARK:
			PutridCurse.fall(parent, aim, cast, states, self)
		Skill.Shape.BREATH:
			ToxicBreath.exhale(parent, at, toward, cast, states)
			# La Quinte (jalon 45) : le cône repart, d'où l'on se tient alors.
			if cast.fit > 0.0:
				var fit := cast.echoed(SkillStats.FIT_PART)
				fit.fit = 0.0
				for i in SkillStats.FIT_COUNT:
					get_tree().create_timer(SkillStats.FIT_GAP * float(i + 1), false).timeout.connect(
						func() -> void:
							if is_instance_valid(origin) and is_instance_valid(parent):
								ToxicBreath.exhale(parent, origin.global_position, toward, fit, states)
					)
		Skill.Shape.GLYPH:
			Glyph.place(self, origin, aim, cast, parent)
		Skill.Shape.TRIAD:
			Triad.converge(parent, at, aim, cast, states)
		Skill.Shape.TURRET:
			Brazier.place(self, aim, cast, parent)
		Skill.Shape.CAULDRON:
			Cauldron.place(self, aim, cast, parent)
		Skill.Shape.STRIKE:
			_swing(cast, SwingArc.Style.STRIKE)
		Skill.Shape.CROSS:
			_swing(cast, SwingArc.Style.CROSS)
		Skill.Shape.LUNGE:
			_lunge(cast)
		Skill.Shape.FLURRY:
			_flurry(cast)
		Skill.Shape.FINISHER:
			_finish_off(cast)
		Skill.Shape.RIPOSTE:
			_light(skill.id, Buff.light(self, skill))
		Skill.Shape.BITE:
			_bite(cast)
		Skill.Shape.TIDE:
			# Sous le Roi des Rats, elle tourne autour de lui, le Peuple grouillant en plus.
			if reigns():
				RatTide.orbit(parent, self, cast.echoed(1.0 + lit_number(SkillStats.TEEMING) * 0.01), states)
			else:
				RatTide.unleash(parent, at, toward, cast, states, self)
		Skill.Shape.MELODY:
			_light(skill.id, HamelinAir.play(self, skill))
		Skill.Shape.DANCE:
			_dance(cast)
		_:
			_swing(cast)


## Ce qu'un sort qui frappe déclenche chez son lanceur (jalon 41) : une charge d'Harmonie
## s'il change de nature — le Tempo avec elle —, leur perte s'il la répète sous la
## Dissonance, ce que la Résonance rend à un buff lancé, l'écho du Familier, ce qui se verse
## au Chaudron (jalon 49).
func _after_spell(skill: Skill, salvo: Array[SkillStats], aim: Vector3) -> void:
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
			_modulate(own.modulation)
		elif repeated and own.dissonance > 0.0 and buff.stacks > 0:
			if own.false_note > 0.0:
				_false_note(salvo[0], buff.stacks)
			buff.stacks = 0
			changed = true
		if own.resonance > 0.0:
			buff.resonate(own.resonance)
		if own.triple_burst > 0.0:
			buff.natures_cast[nature] = true
	Cauldron.pour_all(self, nature)
	Glyph.pour_all(self, nature)
	if changed:
		after_buff_change()


## L'Incarnation (jalon 49) : le sort, déjà résolu dans son élément (`_incarnation_of()`), y
## pose un état plus fort. Sous la Métamorphose, l'élément avance ensuite d'un tour.
func _incarnate(salvo: Array[SkillStats]) -> void:
	for id: String in _lit:
		if not lit(id) or not _lit[id] is Buff or (_lit[id] as Buff).incarnation < 0:
			continue
		var buff := _lit[id] as Buff
		var element := buff.incarnation
		var effect: String = SkillStats.EFFECT_OF[StatusEffects.rolled_by(element)]
		for cast in salvo:
			cast.set(effect, float(cast.get(effect)) + SkillStats.INCARNATION_EFFECT)
		buff.last_spell = salvo[0]
		if resolve(SkillCatalog.by_id(id), skill_points(id)).metamorphosis > 0.0:
			var at := DamageType.ELEMENTS.find(element)
			buff.incarnation = DamageType.ELEMENTS[(at + 1) % DamageType.ELEMENTS.size()]
		return


## Le Diapason (jalon 49) : un sort qui change d'élément sous un buff qui le porte garde une
## part de ses dégâts dans l'élément précédent — de quoi en poser l'état. Avant la pose, que
## le geste peut retarder.
func _diapason(salvo: Array[SkillStats]) -> void:
	var previous := _last_spell_nature
	if previous < 0 or salvo[0].nature == previous:
		return
	for id: String in _lit:
		if not lit(id) or not _lit[id] is Buff:
			continue
		var own := resolve(SkillCatalog.by_id(id), skill_points(id))
		if own.diapason > 0.0:
			for cast in salvo:
				cast.tinge(previous, own.diapason * 0.01)
			return


## La Modulation (jalon 49) : chaque charge gagnée prolonge les états élémentaires autour de soi.
func _modulate(seconds: float) -> void:
	if seconds <= 0.0:
		return
	for target in Targets.in_circle(get_world_3d(), global_position, SkillStats.MODULATION_REACH):
		if target.states != null:
			for kind: int in StatusEffects.ELEMENTAL:
				target.states.extend(kind, seconds)


## La Fausse note (jalon 49) : les charges que la Dissonance fait perdre éclatent autour de soi,
## dans l'élément répété.
func _false_note(cast: SkillStats, lost: int) -> void:
	var parts := DamageType.scaled(cast.roll(Game.rng), SkillStats.FALSE_NOTE_PART * float(lost))
	Explosion.put(
		_effects_parent(), global_position, parts, SkillStats.FALSE_NOTE_RADIUS, null,
		DamageType.COLORS[cast.nature], states, cast
	)


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
		# Le Renversement (jalon 49) : à une charge du plafond.
		if own.perfect_chord <= 0.0 or buff.stacks < Buff.cap_of(skill, own) - int(own.inversion):
			continue
		buff.stacks = 0
		# La Coda (jalon 49) : il en reste une.
		if own.coda > 0.0:
			buff.hold_stacks(1, Buff.hold_of(skill, own))
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
func echo(skill: Skill, salvo: Array[SkillStats], origin: Node3D, aim: Vector3) -> void:
	if is_dead:
		return
	var toward := origin.global_position.direction_to(aim)
	if toward == Vector3.ZERO:
		toward = facing
	_pose(skill, salvo, origin, toward, aim)


## Le lancer résolu de la Lumière sacrée allumée, null éteinte (jalon 48).
func _holy_light() -> SkillStats:
	if not lit(SkillStats.LIGHT_SKILL):
		return null
	return resolve(SkillCatalog.by_id(SkillStats.LIGHT_SKILL), skill_points(SkillStats.LIGHT_SKILL))


## La Dévotion (jalon 48) : chaque seconde de lumière renforce le sort sacré lancé.
func devoted(cast: SkillStats) -> SkillStats:
	if cast.nature != DamageType.Kind.HOLY:
		return cast
	var light := _holy_light()
	if light == null or light.devotion <= 0.0:
		return cast
	var lit_for := minf((_lit[SkillStats.LIGHT_SKILL] as Buff).age(), SkillStats.DEVOTION_MOST)
	return cast.echoed(1.0 + light.devotion * 0.01 * lit_for)


## Le lancer résolu de la Nécrose avancée allumée, null éteinte (jalon 45).
func _necrosis() -> SkillStats:
	if not lit(SkillStats.NECROSIS_SKILL):
		return null
	return resolve(SkillCatalog.by_id(SkillStats.NECROSIS_SKILL), skill_points(SkillStats.NECROSIS_SKILL))


## Le Charognard (jalon 45) : un ennemi qui meurt près de soi rend des PV, sous la Nécrose.
## Appelée par l'`EnemyManager` à chaque mort qui rapporte.
func feast(at: Vector3) -> void:
	if at.distance_to(global_position) > SkillStats.CARRION_REACH:
		return
	var necrosis := _necrosis()
	if necrosis != null:
		heal(stats.max_health * necrosis.carrion * 0.01)


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
	if skill_id == SkillStats.KING_SKILL:
		_reign(false)
	if is_instance_valid(node):
		(node as Node).extinguish()
		if node is Buff and not is_dead:
			_shatter(SkillCatalog.by_id(skill_id), node as Buff)
			_transfigure(skill_id)
			_abdicate(skill_id)
	after_buff_change()


## La Transfiguration (jalon 48) : l'Épiphanie qui s'éteint éclate autour de son porteur,
## d'une part de ses PV max.
func _transfigure(skill_id: String) -> void:
	if skill_id != SkillStats.LIGHT_SKILL:
		return
	var light := resolve(SkillCatalog.by_id(skill_id), skill_points(skill_id))
	if light.transfiguration <= 0.0 or light.epiphany <= 0.0:
		return
	var parts := DamageType.empty_parts()
	parts[light.nature] = stats.max_health * SkillStats.TRANSFIGURATION_PART
	Explosion.put(
		_effects_parent(), global_position, parts, SkillStats.TRANSFIGURATION_RADIUS, null,
		DamageType.COLORS[light.nature], states, light
	)


## L'Éclatement du Tombeau (jalon 36) : un buff lancé qui s'éteint éclate. Pas celui
## d'une ruée, qui a déjà éclaté à l'arrivée. Le Brise-glace (jalon 44) paie chaque seconde
## qu'il lui restait ; le Cœur de glace transit à coup sûr, à double force.
func _shatter(skill: Skill, buff: Buff) -> void:
	if skill == null or skill.shape != Skill.Shape.BUFF:
		return
	var cast := resolve(skill, skill_points(skill.id))
	if cast.end_burst <= 0.0:
		return
	# Le Contrecoup (jalon 49) : des dégâts qui montent avec le temps brûlé et le niveau.
	if cast.recoil > 0.0:
		var built := cast.recoil_damage(level, buff.lived)
		cast.add_to(cast.nature, built, built)
	cast = cast.echoed(1.0 + cast.icebreaker * 0.01 * buff.remaining())
	if cast.ice_heart > 0.0:
		cast.status_chance_increase += SkillStats.SURE_STATE
		cast.chill_effect += SkillStats.ICE_HEART_EFFECT
	# Le Triple éclat (jalon 49) : un éclat par élément lancé, chacun dans le sien.
	if cast.triple_burst > 0.0 and not buff.natures_cast.is_empty():
		for nature: int in buff.natures_cast:
			var part := cast.echoed(1.0)
			part.blend([nature] as Array[int])
			part.nature = nature
			Explosion.of_cast(_effects_parent(), global_position, part, cast.end_burst, states)
		return
	Explosion.of_cast(_effects_parent(), global_position, cast, cast.end_burst, states)


## L'allumage, son pendant : la fiche reçoit les lignes du buff.
func _light(skill_id: String, node: Node) -> void:
	# Une ruée relancée avant la fin de son buff remplace le sien : sans ça le premier
	# nœud brûlerait sans que rien ne le tienne plus.
	var old: Variant = _lit.get(skill_id)
	if is_instance_valid(old) and old != node:
		(old as Node).extinguish()
	_lit[skill_id] = node
	after_buff_change()


## La Ronde folle (jalon 46) : ce que donne aux épées le Cyclone qui tourne, zéro sans lui.
func spin_madness() -> float:
	for node: Variant in _lit.values():
		if is_instance_valid(node) and node is Cyclone:
			return (node as Cyclone).madness()
	return 0.0


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


## L'Égide (jalon 48) : l'abri de la dernière onde, jusqu'à la suivante.
func guard(amount: float) -> void:
	if amount != _aegis:
		_aegis = amount
		_restat()


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
func _on_struck(at: Vector3, parts: Array, victim: StatusEffects) -> void:
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


## Un ennemi vient de frapper au contact (`Enemy._hurt()`) : la Peau de givre le transit
## (jalon 44) ; le Choc en retour lui rend une part du coup en foudre, par un arc, et la Cage
## de Faraday s'ensuit.
func melee_blow(attacker: Enemy, amount: float) -> void:
	var skin := lit_number(SkillStats.FROST_SKIN)
	if skin > 0.0 and is_instance_valid(attacker) and attacker.hurtbox.states != null:
		attacker.hurtbox.states.put(StatusEffects.Kind.CHILL, 0.0, states, SkillStats.TOMB_SKILL, skin * 0.01)
	var part := lit_number(SkillStats.BACKLASH)
	if part <= 0.0 or is_dead or not is_instance_valid(attacker):
		return
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.LIGHTNING] = amount * part * 0.01
	Targets.strike(attacker.hurtbox, parts, global_position, states, null)
	ChainLightning.trace(
		_effects_parent(), PackedVector3Array([global_position, attacker.global_position]),
		DamageType.COLORS[DamageType.Kind.LIGHTNING]
	)
	if _faraday_wait <= 0.0 and lit_number(SkillStats.FARADAY) > 0.0 \
			and _untouchable(SkillStats.FARADAY_TIME):
		_faraday_wait = SkillStats.FARADAY_PERIOD


## Invulnérable pour ce temps — la Cage de Faraday, la Voltige. Jamais par-dessus une
## invulnérabilité posée ailleurs, qu'elle lèverait en finissant.
func _untouchable(seconds: float) -> bool:
	if hurtbox.invulnerable:
		return false
	hurtbox.invulnerable = true
	_untouchable_left = seconds
	return true


## Un ennemi tué. **Depuis un rappel de collision** : ce qui naît ici passe par
## `DeferredTree` (invariant 4) — l'explosion et le sol le font d'eux-mêmes.
func _on_slew(cast: SkillStats, at: Vector3, victim: StatusEffects) -> void:
	_reign_kill()
	if cast == null:
		return
	# L'état de la nature du lancer : un brasier devenu nécrotique fait exploser les pourrissants.
	# Les Pustules de la Peste (jalon 45) : les décomposés aussi.
	if cast.kill_burst > 0.0 and victim != null and (victim.active(StatusEffects.rolled_by(cast.nature)) \
			or cast.pustules > 0.0 and victim.active(StatusEffects.Kind.DECAY)):
		var parts := DamageType.scaled(cast.roll(Game.rng), SkillStats.KILL_BURST_PART)
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
			ChainLightning.surge.call_deferred(_effects_parent(), get_world_3d(), at, states, cast.surged())
	# L'Hiver sans fin (jalon 44) : chaque tué rend du temps au tombeau allumé qui le porte.
	if lit(SkillStats.TOMB_SKILL):
		var tomb := resolve(SkillCatalog.by_id(SkillStats.TOMB_SKILL), skill_points(SkillStats.TOMB_SKILL))
		if tomb.endless_winter > 0.0:
			(_lit[SkillStats.TOMB_SKILL] as Buff).prolong(SkillStats.ENDLESS_TIME)
	# La Relance (jalon 46) : un tué rend la ruée sur-le-champ.
	if cast.relaunch > 0.0:
		_relaunch(cast.skill_id)
	# Les Âmes consumées (jalon 42) : chaque tué rend une part des PV max.
	if cast.soul_feast > 0.0:
		heal(stats.max_health * cast.soul_feast * 0.01)
	# Le Coup sur coup (jalon 50) : la frappe vive repart du tué.
	if cast.chain_strike > 0.0 and cast.chained < int(cast.chain_strike):
		_chain_lunge.call_deferred(cast)
	if cast.keywords.has(Keywords.ATTACK):
		_stack_on_kill()
		_no_quarter(cast, at)
	elif cast.keywords.has(Keywords.SPELL):
		_siphon()


## Sans quartier (jalon 50) : sous le Berserk, à pleines charges, un tué d'attaque éclate. Une
## onde sans lancer : ce qu'elle tue ne relance rien.
func _no_quarter(cast: SkillStats, at: Vector3) -> void:
	if not lit(SkillStats.FRENZY_SKILL):
		return
	var skill := SkillCatalog.by_id(SkillStats.FRENZY_SKILL)
	var own := resolve(skill, skill_points(skill.id))
	if own.no_quarter <= 0.0 or lit_stacks(skill.id) < Buff.cap_of(skill, own):
		return
	Explosion.put(
		_effects_parent(), at, DamageType.scaled(cast.roll(Game.rng), SkillStats.NO_QUARTER_PART),
		SkillStats.NO_QUARTER_RADIUS, null, DamageType.COLORS[DamageType.Kind.PHYSICAL], states, null
	)


func _relaunch(skill_id: String) -> void:
	for i in _recharges.size():
		if bar.id_of(i) == skill_id:
			_recharges[i] = 0.0
	if not _relaunched:
		_hallali = mini(_hallali + 1, SkillStats.HALLALI_MOST)
	_relaunched = true


## Un corps qui portait l'état d'un de nos lancers est tombé, de quoi que ce soit (jalon 45) :
## la Dîme rend du mana, l'Exhumation le relève — mort-vivant de la Relève, tout son arbre
## compris, si l'on la connaît.
func _on_fell(cast: SkillStats, at: Vector3) -> void:
	gain_mana(cast.tithe)
	if cast.exhume <= 0.0:
		return
	var points := skill_points(SkillStats.EXHUMED_SKILL)
	if points > 0:
		Minion.risen.call_deferred(
			self, resolve(SkillCatalog.by_id(SkillStats.EXHUMED_SKILL), points), _effects_parent(), at,
			1, SkillStats.EXHUME_LIFE, "exhumed", SkillStats.EXHUMED_MOST
		)


## Le Siphon (jalon 41) : un ennemi tué d'un sort rend du mana, sous le buff qui le porte.
func _siphon() -> void:
	for skill in lit_skills():
		gain_mana(resolve(skill, skill_points(skill.id)).siphon)


## Chaque buff à charges allumé en gagne une — deux sous la Lampée, et la Moisson soigne
## (jalon 50). Rien n'y naît : la fiche seule est refaite.
func _stack_on_kill() -> void:
	var gained := false
	for id: String in _lit:
		var skill := SkillCatalog.by_id(id)
		if not lit(id) or not _lit[id] is Buff or skill.stacks_max <= 0 \
				or skill.stack_trigger != Skill.StackTrigger.KILL:
			continue
		var buff := _lit[id] as Buff
		var own := resolve(skill, skill_points(id))
		buff.stack(Skill.StackTrigger.KILL, own)
		var gains := 1
		if own.gulp > 0.0 and Game.rng.randf() * 100.0 < own.gulp:
			buff.stack(Skill.StackTrigger.KILL, own)
			gains += 1
		heal(stats.max_health * own.harvest * 0.01 * float(gains))
		gained = true
	if gained:
		after_buff_change()


## Un critique porté (jalon 50) : l'Ivresse du sang ravive la Frénésie, la Fièvre en donne
## une charge, à sa chance, sur un coup d'attaque.
func _on_critical(cast: RefCounted) -> void:
	var blow := cast as SkillStats
	if blow == null or not lit(SkillStats.FRENZY_SKILL):
		return
	var frenzy := _lit[SkillStats.FRENZY_SKILL] as Buff
	if blow.blood_rush > 0.0:
		frenzy.revive(blow.blood_rush)
	if not blow.keywords.has(Keywords.ATTACK):
		return
	var own := resolve(SkillCatalog.by_id(SkillStats.FRENZY_SKILL), skill_points(SkillStats.FRENZY_SKILL))
	if own.fever > 0.0 and Game.rng.randf() * 100.0 < own.fever:
		frenzy.stack(Skill.StackTrigger.KILL, own)
		after_buff_change()


## Un état neuf s'annonce : la pastille seule ne dirait pas pourquoi on ralentit.
func _announce_state(kind: int) -> void:
	if HitFeedback.current != null:
		HitFeedback.current.state(hurtbox.overhead(), kind)


func _show_states() -> void:
	model.show_states(states)
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
	if cast.vault > 0.0:
		_untouchable(SkillStats.VAULT_TIME)
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
			Flat.orthogonal((global_position - from_value)) * (1.0 if i % 2 == 0 else -1.0),
			cast.roll(Game.rng), states, SkillStats.TRAIL_CHARGE_PART, cast.static_mines > 0.0,
			charge_life, _charge_bit
		)
	if cast.end_burst > 0.0:
		# La Trouée (jalon 46) : chaque ennemi traversé renforce le choc d'arrivée.
		var burst := cast
		if cast.breakthrough > 0.0:
			var crossed := Targets.in_capsule(get_world_3d(), from_value, global_position, cast.radius * 2.0)
			burst = cast.echoed(1.0 + cast.breakthrough * 0.01 * float(crossed.size()))
		Explosion.of_cast(_effects_parent(), global_position, burst, cast.end_burst, states)
		# La Retombée (jalon 46) : la réception du bond assomme ce qu'elle frappe.
		if cast.fallout > 0.0 and cast.shape == Skill.Shape.LEAP:
			for target in Targets.in_circle(get_world_3d(), global_position, cast.end_burst):
				var body := target.get_parent() as Enemy
				if body != null:
					body.stun(SkillStats.FALLOUT_TIME)
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


func _bolt_line(from_value: Vector3, to: Vector3, cast: SkillStats) -> void:
	var parts := cast.roll(Game.rng)
	for target in Targets.in_capsule(get_world_3d(), from_value, to, SkillStats.BOLT_DASH_WIDTH):
		Targets.strike(target, parts, from_value, states, cast)
	ChainLightning.trace(_effects_parent(), PackedVector3Array([from_value, to]), DamageType.COLORS[cast.nature])


## L'Aller-retour : on revient d'où l'on est parti, murs traversés comme à l'aller.
func _return_to(origin: Vector3, cast: SkillStats) -> void:
	if is_dead:
		return
	var from_value := global_position
	global_position = _landing(from_value, origin)
	_bolt_line(from_value, global_position, cast)


func _rumble(at: Vector3, cast: SkillStats) -> void:
	Explosion.of_cast(_effects_parent(), at, cast, cast.end_burst, states)


## Le Réarmement (jalon 43) : chaque engourdi dans l'explosion d'arrivée — compté avant
## qu'elle frappe — raccourcit la recharge de la case.
func _rearm(index: int, cast: SkillStats) -> void:
	var numbed := 0
	for target in Targets.in_circle(get_world_3d(), global_position, cast.end_burst):
		if target.has_state(StatusEffects.Kind.NUMB):
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
	var impact := global_position + facing * strike_reach()
	var knockback := stats.knockback_force + cast.knockback
	var struck := Targets.strike_circle(get_world_3d(), impact, cast.radius, cast, states, knockback)
	GroundSlam.leave(_effects_parent(), impact, cast)
	heal(cast.life_on_hit * float(struck.size()))
	for target in struck:
		_shove(target, cast, impact, knockback)
	if not struck.is_empty():
		Game.hit_stop(_stop_of(cast))
		Game.shake_camera(camera, shake_amount * STRIKE_SHAKE)
	if cast.tremor > 0.0:
		get_tree().create_timer(SkillStats.TREMOR_GAP, false).timeout.connect(_tremor.bind(impact, cast))


## Le Tremblement (jalon 46) : un second anneau autour du Brise-sol, au-delà de son cercle.
## Un tirage pour tout l'anneau (invariant 3).
func _tremor(impact: Vector3, cast: SkillStats) -> void:
	var ring := cast.echoed(cast.tremor * 0.01)
	ring.radius = cast.radius * SkillStats.TREMOR_REACH
	GroundSlam.leave(_effects_parent(), impact, ring)
	var parts := ring.roll(Game.rng)
	for target in Targets.in_circle(get_world_3d(), impact, ring.radius):
		if impact.distance_to(target.global_position) > cast.radius:
			Targets.strike(target, parts, impact, states, ring)


## La cible d'une frappe vive : parmi les ennemis à sa portée, **le plus proche de la
## visée**, cherché à l'appui pour refuser un lancer sans personne, puis à l'impact.
func _lunge_target(cast: SkillStats) -> Hurtbox:
	var aim := _aim_point()
	var best: Hurtbox = null
	for candidate in Targets.in_circle(get_world_3d(), global_position, cast.radius):
		if best == null or candidate.global_position.distance_squared_to(aim) \
				< best.global_position.distance_squared_to(aim):
			best = candidate
	return best


## Une frappe vive : on se porte **contre** la cible, murs traversés comme une ruée, et on
## frappe elle seule — pas un arc, qui prendrait ses voisins. Gel et secousse d'une frappe.
## `prey` : la relance du Coup sur coup (jalon 50), qui choisit la sienne.
func _lunge(cast: SkillStats, prey: Hurtbox = null) -> void:
	# Choisie à l'impact : celle de l'appui a pu tomber pendant le geste (jalon 47).
	if prey == null:
		prey = _lunge_target(cast)
	if prey == null:
		return
	var toward := prey.global_position
	var from_value := global_position
	global_position = _landing(from_value, toward - from_value.direction_to(toward) * LUNGE_REACH)
	if global_position != toward:
		facing = global_position.direction_to(toward)
	LungeTrail.leave(_effects_parent(), from_value, global_position, toward)
	var blow := _lunge_blow(cast, prey, from_value.distance_to(global_position))
	# La Fente : ce que le bond traverse, sans relance — seule la cible en donne une.
	if cast.lunge_path > 0.0:
		var passing := blow.echoed((SkillStats.PATH_PART + cast.cleave_path) * 0.01)
		passing.chain_strike = 0.0
		for crossed in Targets.in_capsule(get_world_3d(), from_value, global_position, SkillStats.PATH_WIDTH):
			if crossed != prey:
				Targets.strike(crossed, passing.roll(Game.rng), from_value, states, passing)
	Targets.strike(prey, blow.roll(Game.rng), global_position, states, blow)
	if cast.opening > 0.0 and is_instance_valid(prey) and prey.states != null:
		prey.states.open_up(cast.opening, SkillStats.OPENING_TIME)
	if cast.double_hit > 0.0:
		var second := blow.echoed(cast.double_hit * 0.01)
		second.chain_strike = 0.0
		get_tree().create_timer(SkillStats.DOUBLE_GAP, false).timeout.connect(
			func() -> void:
				if is_instance_valid(prey) and not is_dead:
					Targets.strike(prey, second.roll(Game.rng), global_position, states, second)
		)
	if cast.retreat > 0.0:
		global_position = _landing(
			global_position, global_position + global_position.direction_to(from_value) * SkillStats.RETREAT_REACH
		)
		if cast.slip > 0.0:
			_untouchable(SkillStats.SLIP_TIME)
	Game.hit_stop()
	Game.shake_camera(camera, shake_amount * STRIKE_SHAKE)


## L'Impétuosité, par tranche de bond, et le Premier sang, sur un ennemi intact (jalon 50).
func _lunge_blow(cast: SkillStats, prey: Hurtbox, leapt: float) -> SkillStats:
	var part := 1.0 + cast.impetus * 0.01 * floorf(leapt / SkillStats.IMPETUS_STEP)
	var enemy := prey.get_parent() as Enemy
	if cast.first_blood > 0.0 and enemy != null and enemy.health >= enemy.stats.max_health:
		part *= 1.0 + cast.first_blood * 0.01
	return cast.echoed(part) if part != 1.0 else cast


## Le Coup sur coup (jalon 50) : un tué relance la frappe sur l'ennemi le plus proche, sans
## payer, `chain_strike` fois d'affilée ; la Furia renforce chaque relance.
func _chain_lunge(cast: SkillStats) -> void:
	if is_dead:
		return
	var prey: Hurtbox = null
	for candidate in Targets.in_circle(get_world_3d(), global_position, cast.radius):
		var enemy := candidate.get_parent() as Enemy
		if enemy != null and enemy.is_dead:
			continue
		if prey == null or global_position.distance_squared_to(candidate.global_position) \
				< global_position.distance_squared_to(prey.global_position):
			prey = candidate
	if prey == null:
		return
	var next := cast.echoed(1.0 + cast.furia * 0.01)
	next.chained = cast.chained + 1
	_lunge(next, prey)


## La Rafale (jalon 50) : des estocs à `FLURRY_GAP` du geste l'un de l'autre, chacun plus enclin au
## critique que le précédent. Chacun prend le premier corps sur sa ligne, vers où l'on
## regarde à cet instant — ou sur la sienne sous l'Éventail.
func _flurry(cast: SkillStats) -> void:
	var count := SkillStats.FLURRY_THRUSTS + int(cast.extra_thrusts)
	var gap := cast.use_time * SkillStats.FLURRY_GAP / maxf(states.speed_factor, 0.01)
	var escalation := SkillStats.FLURRY_CRIT + cast.ascent
	var last: Hurtbox = null
	var streak := 0
	for i in count:
		if i > 0:
			await get_tree().create_timer(gap, false).timeout
		if is_dead:
			return
		var final := i == count - 1
		var piercing := final and cast.jarnac > 0.0
		var heading := Flat.rotated(facing, _flurry_turn(cast, i, count))
		var reach := cast.radius * (SkillStats.JARNAC_REACH if piercing else 1.0)
		var tip := global_position + heading * reach
		var struck := Targets.in_capsule(get_world_3d(), global_position, tip, SkillStats.FLURRY_WIDTH)
		if not struck.is_empty() and not piercing:
			struck = [_nearest_of(struck)] as Array[Hurtbox]
			tip = global_position + heading * global_position.distance_to(struck[0].global_position)
		if not struck.is_empty():
			streak = streak + 1 if struck[0] == last else 0
			last = struck[0]
		var thrust := cast.echoed(1.0 + cast.insistence * 0.01 * float(streak))
		thrust.crit_chance = minf(cast.crit_chance * (1.0 + escalation * 0.01 * float(i)), 1.0)
		if final and cast.secret_thrust > 0.0:
			thrust.crit_chance = 1.0
		var parts := thrust.roll(Game.rng)
		for target in struck:
			Targets.strike(target, parts, global_position, states, thrust)
			gain_mana(cast.mana_on_hit)
		if not struck.is_empty():
			Game.hit_stop()
			Game.shake_camera(camera, shake_amount)
		# Le peigne : chaque estoc dessiné sur sa rangée, la ligne qui frappe au milieu.
		var row := Flat.orthogonal(heading) * (float(i) - float(count - 1) * 0.5) * ThrustTrail.COMB_GAP
		ThrustTrail.leave(
			_effects_parent(), global_position + row, tip + row, DamageType.COLORS[thrust.nature],
			ThrustTrail.COMB_WIDTH
		)


## L'écart de cet estoc à la visée : aucun, sur `FAN_SPREAD` sous l'Éventail, sur tout le
## cercle sous la Rose des vents.
func _flurry_turn(cast: SkillStats, i: int, count: int) -> float:
	if cast.fan <= 0.0 or count < 2:
		return 0.0
	if cast.compass > 0.0:
		return TAU * float(i) / float(count)
	var spread := deg_to_rad(SkillStats.FAN_SPREAD)
	return -spread * 0.5 + spread * float(i) / float(count - 1)


func _nearest_of(bodies: Array[Hurtbox]) -> Hurtbox:
	var best := bodies[0]
	for body in bodies:
		if global_position.distance_squared_to(body.global_position) \
				< global_position.distance_squared_to(best.global_position):
			best = body
	return best


## Le Coup de grâce (jalon 50) : la cible de la frappe vive, sans le bond. Il vide la
## Frénésie — la moitié sous le Sang-froid : chaque charge le renforce et hausse le seuil
## sous lequel la cible est achevée. Il arrache les lames plantées.
func _finish_off(cast: SkillStats) -> void:
	var prey := _lunge_target(cast)
	if prey == null:
		return
	var charges := _spend_frenzy(cast)
	var part := 1.0 + (SkillStats.FINISHER_POWER + cast.relentless) * 0.01 * float(charges)
	part *= 1.0 + SkillStats.PLANT_POWER * 0.01 * float(PlantedKnives.rip(prey))
	var enemy := prey.get_parent() as Enemy
	if cast.cornered > 0.0 and enemy != null and enemy.health < enemy.stats.max_health * 0.5:
		part *= 1.0 + cast.cornered * 0.01
	var blow := cast.echoed(part)
	blow.execution += SkillStats.FINISHER_EXECUTION * float(charges)
	gain_mana(cast.ransom * float(charges))
	facing = global_position.direction_to(prey.global_position)
	var parts := blow.roll(Game.rng)
	var at := prey.global_position
	Targets.strike(prey, parts, global_position, states, blow, cast.knockback)
	var tint: Color = DamageType.COLORS[blow.nature]
	ThrustTrail.leave(_effects_parent(), global_position, at, tint, ThrustTrail.HEAVY_WIDTH, false)
	GraceMark.carve(_effects_parent(), at, tint)
	# Le Point final : à pleines charges, le coup éclate autour de sa cible ; l'Épilogue y
	# garde le seuil d'achèvement.
	if cast.final_point > 0.0 and charges >= SkillStats.FINAL_CHARGES:
		var blast := blow.echoed(SkillStats.FINAL_PART)
		if cast.epilogue <= 0.0:
			blast.execution = 0.0
		var shards := DamageType.scaled(parts, SkillStats.FINAL_PART)
		for near in Targets.in_circle(get_world_3d(), at, SkillStats.FINAL_RADIUS):
			if near != prey:
				Targets.strike(near, shards, at, states, blast)
		FinalBurst.burst(_effects_parent(), at, SkillStats.FINAL_RADIUS, tint)
	if cast.dread > 0.0 and enemy != null and enemy.is_dead:
		for near in Targets.in_circle(get_world_3d(), at, SkillStats.DREAD_REACH):
			var neighbour := near.get_parent() as Enemy
			if neighbour != null and not neighbour.is_dead:
				neighbour.stun(cast.dread)
	Game.hit_stop()
	Game.shake_camera(camera, shake_amount * STRIKE_SHAKE)


## Les charges de Frénésie que prend le Coup de grâce ; la Patience fait repartir celles
## qu'il laisse.
func _spend_frenzy(cast: SkillStats) -> int:
	if not lit(SkillStats.FRENZY_SKILL):
		return 0
	var frenzy := _lit[SkillStats.FRENZY_SKILL] as Buff
	var wanted := ceili(frenzy.stacks * 0.5) if cast.composure > 0.0 else frenzy.stacks
	var spent := frenzy.spend(wanted)
	if cast.patience > 0.0 and frenzy.stacks > 0:
		frenzy.revive(INF)
	after_buff_change()
	return spent


## Le joueur de flûte (jalon 53) : le Roi des Rats règne-t-il ?
func reigns() -> bool:
	return lit(SkillStats.KING_SKILL)


## Le buff du règne, dont la barre lit le temps ; null hors du règne.
func reign() -> Buff:
	return _lit[SkillStats.KING_SKILL] as Buff if reigns() else null


## Le Coup de croc : le premier corps sur sa ligne, comme un estoc de la Rafale. Ses rats
## s'accrochent au coup (`Hurtbox`) ; le Croc-en-jambe ralentit la cible, et le Rat d'égout
## lance une marée depuis qui en porte assez.
func _bite(cast: SkillStats) -> void:
	var tip := global_position + facing * cast.radius
	var struck := Targets.in_capsule(get_world_3d(), global_position, tip, SkillStats.BITE_WIDTH)
	if not struck.is_empty():
		var prey := _nearest_of(struck)
		tip = prey.global_position
		var info := DamageInfo.roll(
			cast, global_position, cast.roll(Game.rng), stats.knockback_force + cast.knockback
		)
		info.author = states
		prey.take_damage(info)
		_drain_bite(cast, info.amount)
		_bitten(prey, cast)
		Game.hit_stop()
		Game.shake_camera(camera, shake_amount)
	ThrustTrail.leave(_effects_parent(), global_position, tip, DamageType.COLORS[cast.nature])


## Ce que la morsure fait au mordu, en ligne ou en arc sous la Gueule béante : le Croc-en-jambe
## le ralentit, le Rat d'égout lance une marée depuis lui s'il porte assez de rats — en différé,
## l'arc mord dans un rappel de collision (invariant 4).
func _bitten(prey: Hurtbox, cast: SkillStats) -> void:
	if prey.states == null:
		return
	if cast.trip > 0.0:
		prey.states.hobble(cast.trip, SkillStats.TRIP_TIME)
	if cast.sewer_rat > 0.0 and prey.states.rats() >= SkillStats.SEWER_RATS:
		_sewer.call_deferred(cast, prey.global_position)


## Le Rat d'égout : une Marée de rats part du mordu, droit devant, la Crue en plus.
func _sewer(cast: SkillStats, from_value: Vector3) -> void:
	var skill := SkillCatalog.by_id(SkillStats.TIDE_SKILL)
	var tide := resolve(skill, maxi(skill_points(skill.id), 1))
	tide.rats += cast.flood
	RatTide.unleash(_effects_parent(), from_value, facing, tide, states, self)


## Sous le Roi des Rats, le Coup de croc rend une part de ce qu'il a fait passer ; l'Usurpateur
## y ajoute.
func _drain_bite(cast: SkillStats, amount: float) -> void:
	if cast.skill_id == SkillStats.BITE_SKILL and reigns():
		heal(amount * (SkillStats.KING_DRAIN + lit_number(SkillStats.USURPER)) * 0.01)


## La Danse macabre : des coups à `FLURRY_GAP` du geste l'un de l'autre, chacun après un pas vers
## la visée ; sous le Totentanz chacun fait éclater un rat de ce qu'il frappe, et le dernier fait
## éclater tous ceux qui entourent sa cible.
func _dance(cast: SkillStats) -> void:
	var count := SkillStats.DANCE_STEPS + int(cast.extra_steps)
	var gap := cast.use_time * SkillStats.FLURRY_GAP / maxf(states.speed_factor, 0.01)
	var aim := _aim_point()
	var popped := 0
	for i in count:
		if i > 0:
			await get_tree().create_timer(gap, false).timeout
		if is_dead:
			return
		if global_position.distance_to(aim) > SkillStats.DANCE_REACH:
			facing = global_position.direction_to(aim)
		global_position = _landing(global_position, global_position + facing * (SkillStats.DANCE_STRIDE + cast.glide))
		var center := global_position + facing * SkillStats.DANCE_REACH
		var struck := Targets.in_circle(get_world_3d(), center, SkillStats.DANCE_HIT)
		var parts := cast.roll(Game.rng)
		for target in struck:
			Targets.strike(target, parts, global_position, states, cast)
			if cast.totentanz > 0.0:
				popped += Vermin.burst(target, cast, states, _effects_parent(), 1)
		if not struck.is_empty():
			center = _nearest_of(struck).global_position
			Game.hit_stop()
			Game.shake_camera(camera, shake_amount)
		swing_arc.play(swing_duration, SwingArc.Style.ARC, DamageType.COLORS[cast.nature])
		if i == count - 1:
			popped += _dance_finale(cast, center, parts)
	gain_mana(cast.gravedigger * float(popped))
	# Le Chassé-croisé : un pas en arrière, la danse finie.
	if cast.cross_step > 0.0 and not is_dead:
		global_position = _landing(global_position, global_position - facing * cast.cross_step)


## Le dernier coup : les rats de tous ceux qui entourent la cible éclatent ; la Pirouette frappe
## tout le cercle, la Débandade fait fuir ceux dont les rats ont éclaté. Rend combien.
func _dance_finale(cast: SkillStats, center: Vector3, parts: Array[float]) -> int:
	var popped := 0
	for target in Targets.in_circle(get_world_3d(), center, cast.radius):
		var burst := Vermin.burst(target, cast, states, _effects_parent())
		popped += burst
		var enemy := target.get_parent() as Enemy
		if burst > 0 and cast.rout > 0.0 and enemy != null:
			enemy.frighten(cast.rout, center)
		if cast.pirouette > 0.0:
			Targets.strike(target, DamageType.scaled(parts, cast.pirouette * 0.01), center, states, cast)
	return popped


## Le Roi des Rats : il consomme tous les rats accrochés à l'écran ; chacun allonge le règne et,
## sous la Gabelle, rend de la vie. Rend les secondes gagnées.
func _consume_rats(cast: SkillStats) -> float:
	var eaten := 0
	for target in Targets.in_circle(get_world_3d(), global_position, SkillStats.SCREEN_REACH):
		if target.states != null:
			eaten += target.states.take_rats()
	heal(stats.max_health * cast.salt_tax * 0.01 * float(eaten))
	return float(eaten) * (SkillStats.KING_PER_RAT + cast.court)


## Le Roi des Rats prend sa planche le temps du règne et la rend à l'abdication ; barre de vie
## et nombres suivent sa taille.
func _reign(on: bool) -> void:
	# Le Roi grandi commence lui aussi par `KING_LOOK` : ce n'est pas la planche du joueur.
	if on and not model.archetype.begins_with(SkillStats.KING_LOOK):
		_look = model.archetype
		_reign_kills = 0
	_wear(king_look() if on else _look)


func _wear(look: String) -> void:
	if look.is_empty():
		return
	model.set_archetype(look)
	var lift := SpriteForge.head_room(look)
	health_bar.lift = lift
	hurtbox.feedback_lift = lift


## La planche du Roi à la taille où la Légende l'a mené.
func king_look() -> String:
	var step := mini(_reign_kills / SkillStats.LEGEND_KILLS, SkillStats.KING_GROWN.size())
	return SkillStats.KING_LOOK if step == 0 else SkillStats.KING_GROWN[step - 1]


## La Couronne de queues : chaque mort du règne le prolonge ; la Légende davantage, et le Roi
## grandit.
func _reign_kill() -> void:
	if not reigns():
		return
	var king := resolve(SkillCatalog.by_id(SkillStats.KING_SKILL), skill_points(SkillStats.KING_SKILL))
	if king.tail_crown > 0.0:
		(_lit[SkillStats.KING_SKILL] as Buff).lengthen(SkillStats.TAIL_CROWN_TIME + king.legend)
	if king.legend > 0.0:
		_reign_kills += 1
		_wear(king_look())


## L'Abdication : à la fin du règne, des marées jaillissent tout autour, le Régicide en plus.
func _abdicate(skill_id: String) -> void:
	if skill_id != SkillStats.KING_SKILL:
		return
	var king := resolve(SkillCatalog.by_id(skill_id), skill_points(skill_id))
	if king.abdication <= 0.0:
		return
	var skill := SkillCatalog.by_id(SkillStats.TIDE_SKILL)
	var tide := resolve(skill, maxi(skill_points(skill.id), 1)).echoed(1.0 + king.regicide * 0.01)
	var count := SkillStats.ABDICATION_TIDES
	for i in count:
		var toward := Flat.rotated(Vector3.RIGHT, TAU * float(i) / float(count))
		RatTide.send(_effects_parent(), global_position, toward, tide, states, self)


## Le Festin : ce que valent les rats du joueur, écrit sur ses états où leurs porteurs le
## lisent. Refait avec la fiche : il suit le Festin qu'on allume et ses points.
func _rat_rules() -> void:
	if states.rat_rules == null:
		states.rat_rules = StatusEffects.RatRules.new()
	var rules := states.rat_rules
	var skill := SkillCatalog.by_id(SkillStats.FEAST_SKILL)
	_feast = resolve(skill, skill_points(skill.id)) if lit(skill.id) else null
	var feast := _feast if _feast != null else SkillStats.new()
	_gnaw_base = maxf(1.0 + stats.gnaw_damage * 0.01, 0.0) * (1.0 + feast.mastication * 0.01)
	rules.gnaw = _gnaw_base
	rules.most = StatusEffects.RATS_MOST + int(feast.insatiable)
	rules.lasting = StatusEffects.DURATIONS[StatusEffects.Kind.RATS] + feast.nibble
	rules.famine = feast.famine > 0.0


## Le Ventre creux, qui suit la vie à chaque image, et le Banquet, qui rend de la vie par rat
## qui ronge.
func _feed_rats() -> void:
	var rules := states.rat_rules
	if _feast != null:
		var hollow := _feast.hollow_belly > 0.0 and health < stats.max_health * SkillStats.HOLLOW_LIFE
		rules.gnaw = _gnaw_base * (1.0 + _feast.hollow_belly * 0.01 if hollow else 1.0)
		if _feast.banquet > 0.0 and rules.gnawed > 0.0:
			heal(stats.max_health * SkillStats.BANQUET_HEAL * rules.gnawed)
	rules.gnawed = 0.0


## Une mort rongée sous le Festin rend vie et mana — davantage sous les Agapes —, et
## l'Indigestion la fait éclater sur ses voisins.
func _on_gnawed(at: Vector3, victim_max_health: float) -> void:
	if _feast == null or is_dead:
		return
	heal(stats.max_health * (SkillStats.FEAST_LIFE_BASE + _feast.feast_life * 0.01))
	var mana_back := SkillStats.FEAST_MANA_BASE + _feast.feast_mana
	if _feast.agapes > 0.0:
		mana_back *= 2.0 * (1.0 + _feast.agapes * 0.01)
	gain_mana(mana_back)
	if _feast.indigestion > 0.0:
		var parts := DamageType.empty_parts()
		parts[DamageType.Kind.PHYSICAL] = victim_max_health * _feast.indigestion * 0.01
		Explosion.put(
			_effects_parent(), at, parts, SkillStats.INDIGESTION_REACH, null,
			DamageType.COLORS[DamageType.Kind.PHYSICAL], states, null
		)


## La Contre-attaque (jalon 50) : un coup esquivé, et l'ennemi le plus proche de d'où il
## venait prend une riposte. En différé : le coup arrive peut-être d'un rappel de collision.
## Le Pas de côté s'y cumule, le Contretemps y arme l'attaque suivante.
func _on_evaded(info: DamageInfo) -> void:
	if is_dead or not lit(SkillStats.COUNTER_SKILL):
		return
	var counter := resolve(SkillCatalog.by_id(SkillStats.COUNTER_SKILL), skill_points(SkillStats.COUNTER_SKILL))
	if counter.sidestep > 0.0:
		_sidesteps = mini(_sidesteps + 1, SkillStats.SIDESTEP_MOST)
		_sidestep_left = SkillStats.SIDESTEP_TIME
		after_buff_change()
	if counter.counter_time > 0.0:
		_counter_time_left = SkillStats.COUNTER_WINDOW
	if _counter_wait > 0.0:
		return
	_counter_wait = SkillStats.RIPOSTE_WAIT
	_riposte.call_deferred(info.source_position)


## Une riposte, puis une de plus par Double riposte, chacune sur le corps suivant le plus
## proche de d'où venait le coup.
func _riposte(toward: Vector3) -> void:
	if is_dead or not lit(SkillStats.COUNTER_SKILL):
		return
	var skill := SkillCatalog.by_id(SkillStats.COUNTER_SKILL)
	var cast := resolve(skill, skill_points(skill.id))
	var near := Targets.in_circle(get_world_3d(), global_position, cast.radius)
	near.sort_custom(func(a: Hurtbox, b: Hurtbox) -> bool:
		return a.global_position.distance_squared_to(toward) < b.global_position.distance_squared_to(toward))
	for prey: Hurtbox in near.slice(0, 1 + int(cast.ripostes)):
		var at := prey.global_position
		var enemy := prey.get_parent() as Enemy
		Targets.strike(prey, cast.roll(Game.rng), global_position, states, cast)
		heal(cast.life_on_hit)
		if cast.disarm > 0.0 and is_instance_valid(enemy) and not enemy.is_dead:
			enemy.stun(cast.disarm)
		ThrustTrail.leave(
			_effects_parent(), global_position, at, DamageType.COLORS[cast.nature],
			ThrustTrail.PARRY_WIDTH, true, true
		)


## Le point le plus proche de la visée où le corps tient, en reculant vers le départ.
## Le départ ferme la marche : on en vient, donc on y tient.
func _landing(from_value: Vector3, toward: Vector3) -> Vector3:
	var steps := maxi(ceili(from_value.distance_to(toward) / LANDING_STEP), 1)
	for i in steps:
		var point := toward.lerp(from_value, float(i) / float(steps))
		if _fits_at(point):
			return point
	return from_value


## **Le décor seul** : un ennemi sous les pieds se repousse de lui-même à l'image
## suivante, la roche non.
func _fits_at(point: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = body_shape.shape
	query.transform = Transform3D(Basis(), point)
	query.collision_mask = Targets.DECOR
	query.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


## Au curseur, à `PLACEMENT_RANGE` au plus ; à la manette, à cette distance devant.
func _aim_point() -> Vector3:
	var toward := facing * PLACEMENT_RANGE
	if _aim_with_mouse:
		toward = (Flat.under_mouse(get_viewport()) - global_position).limit_length(PLACEMENT_RANGE)
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
	return skill.resolve(
		points, stats, skill_mods, talents, int(_turns.get(skill.id, 0)), _incarnation_of(skill)
	)


## L'élément que l'Incarnation (jalon 49) impose à ce geste, -1 sans elle : les sorts qui
## frappent seulement, résolus dans son élément pour que mots-clés et affixes le suivent.
func _incarnation_of(skill: Skill) -> int:
	if skill.cadence != Skill.Cadence.CAST or not skill.strikes():
		return -1
	for id: String in _lit:
		if lit(id) and _lit[id] is Buff and (_lit[id] as Buff).incarnation >= 0:
			return (_lit[id] as Buff).incarnation
	return -1


## Pour le HUD : l'élément que prendra le prochain sort sous ce buff, -1 sans Incarnation.
func lit_incarnation(skill_id: String) -> int:
	var node: Variant = _lit.get(skill_id)
	if not is_instance_valid(node) or not node is Buff:
		return -1
	return (node as Buff).incarnation


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


## Ce que la main tient pour cette compétence : l'instrument de la classe pour celles de
## son manuel (la flûte du joueur de flûte), vide pour l'arme équipée.
func held_for(skill_id: String) -> String:
	var book := book_of(skill_id)
	return instrument if book != null and book == rack.at(Rack.CLASS_SLOT) else ""


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
	swing_arc.play(swing_duration * float(cast.hits), style, DamageType.COLORS[cast.nature])

	for hit in cast.hits:
		if hit > 0:
			# Un ennemi déjà dedans n'y *entre* pas deux fois : la hitbox doit être fermée
			# pendant un pas de physique entier. Le signal part avant le pas : il en faut deux,
			# sinon Jolt voit la fermeture et la réouverture avant le même pas.
			await get_tree().physics_frame
			await get_tree().physics_frame
		_hit_parts = cast.roll(Game.rng)
		_hit_cast = cast
		_hit_index = hit
		# L'Ordalie (jalon 46) : le second coup de la croix bénit à coup sûr.
		if hit == 1 and cast.ordeal > 0.0:
			_hit_cast = cast.echoed(1.0)
			_hit_cast.status_chance_increase += SkillStats.SURE_STATE
		_already_hit.clear()
		# set_deferred : on est peut-être dans un rappel de physique.
		hitbox.set_deferred("monitoring", true)
		# ignore_time_scale : sinon le hit-stop étire la fenêtre de swing.
		await get_tree().create_timer(swing_duration, true, false, true).timeout
		hitbox.set_deferred("monitoring", false)
	# La Tierce (jalon 46) : après la croix, un estoc droit devant.
	if cast.tierce > 0.0:
		await get_tree().create_timer(SkillStats.TIERCE_GAP, false).timeout
		_thrust(cast)
	_is_swinging = false


## L'estoc de la Tierce : le plus proche sur sa ligne, ou tout ce qu'elle traverse sous la
## Quarte, plus loin. Un tirage pour toute la ligne (invariant 3).
func _thrust(cast: SkillStats) -> void:
	if is_dead:
		return
	var thrust := cast.echoed(SkillStats.TIERCE_PART)
	var reach := stats.attack_range + SkillStats.TIERCE_BEYOND \
		+ (SkillStats.QUARTE_REACH if cast.quarte > 0.0 else 0.0)
	var tip := global_position + facing * reach
	var struck := Targets.in_capsule(get_world_3d(), global_position, tip, SkillStats.TIERCE_WIDTH)
	if cast.quarte <= 0.0 and not struck.is_empty():
		struck.sort_custom(func(a: Hurtbox, b: Hurtbox) -> bool:
			return global_position.distance_squared_to(a.global_position) \
				< global_position.distance_squared_to(b.global_position))
		struck = [struck[0]] as Array[Hurtbox]
	var parts := thrust.roll(Game.rng)
	for target in struck:
		Targets.strike(target, parts, global_position, states, thrust)
	# Sans la Quarte, l'étoile éclate sur celui qu'il frappe.
	if cast.quarte <= 0.0 and not struck.is_empty():
		tip = global_position + facing * global_position.distance_to(struck[0].global_position)
	ThrustTrail.leave(_effects_parent(), global_position, tip, DamageType.COLORS[thrust.nature])


## Les traits répartis sur l'écart du geste résolu : tout vient de
## `SkillStats`, rien n'est relu sur la compétence.
## `salvo` : un lancer par trait, ou un seul pour tous (`_salvo()`).
func _roll(
	salvo: Array[SkillStats], scene: PackedScene, origin: Node3D, toward: Vector3,
	aim := Vector3.INF
) -> void:
	if scene == null:
		return
	var directions := _spread(salvo[0], toward)
	var count := directions.size()
	var salvo_hits := {}
	for i in count:
		var cast := salvo[i % salvo.size()]
		var from := origin.global_position
		var heading := directions[i]
		# La Convergence (jalon 42) : côte à côte au départ, toutes vers le point visé.
		if cast.converge > 0.0 and aim != Vector3.INF:
			from += Flat.orthogonal(toward) * (float(i) - float(count - 1) * 0.5) * SkillStats.CONVERGE_GAP
			heading = from.direction_to(aim)
		# Un tirage par trait : trois traits identiques se liraient comme un seul coup.
		var bolt := Projectile.spawn(
			_effects_parent(), scene, from, heading, cast.roll(Game.rng),
			origin, cast.projectile_speed, cast.nature, cast
		)
		if bolt != null:
			bolt.salvo_hits = salvo_hits
		if bolt is Fireball:
			(bolt as Fireball).explosion_radius = cast.radius


## Un cap par projectile, sur l'écart du geste. Un seul part droit devant, quelle que
## soit la dispersion.
func _spread(cast: SkillStats, toward: Vector3) -> Array[Vector3]:
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
	var out: Array[Vector3] = []
	for i in count:
		out.append(Flat.rotated(toward, start + step * float(i)))
	return out


## Testé avant d'écrire : une barre pleine n'émet rien.
func _regen(delta: float) -> void:
	if stats.health_regen > 0.0 and health < stats.max_health:
		_set_health(health + stats.health_regen * delta)
	if stats.mana_regen > 0.0 and mana < stats.max_mana:
		_set_mana(mana + stats.mana_regen * delta)


## Le milieu de la lame, devant le corps : le centre de la hitbox, où le Brise-sol tombe et
## où la Frappe lourde dessine son impact.
func strike_reach() -> float:
	return _hit_shape.position.x


## L'allonge de la fiche (jalon 46) : le bout de la hitbox est à `attack_range`. Elle était
## fixe dans la scène, et l'allonge d'un affixe ou d'un passif ne changeait rien.
func _reach_out() -> void:
	var blade := (_hit_shape.shape as CapsuleShape3D).radius
	_hit_shape.position.x = maxf(stats.attack_range - blade, 0.0)
	swing_arc.impact_reach = _hit_shape.position.x


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
	# Rempart d'os, Bouclier de lames, Accalmie (jalon 44) et Égide (jalon 48) : tant qu'ils
	# tiennent, pas un buff qu'on allume.
	var wall := Minion.wall_of(self) + (_crown.ward() if _crown != null else 0.0) + _calm + _aegis
	if wall > 0.0:
		mods.append(StatMod.new("damage_taken", StatMod.Mode.FLAT, -wall))

	# En trois temps — attributs, dérivation, reste — pour que « +20 force » rapporte ses
	# PV et que « +10 % PV » les multiplie. Ce qui vise un mot-clé part à part, pour le
	# lancer.
	var over_attributes: Array[StatMod] = []
	var on_the_rest: Array[StatMod] = []
	var on_skills: Array[StatMod] = []
	for m in mods:
		if not m.scope.is_empty() or SkillStats.every_skill(m):
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

	_rat_rules()
	# Réassignée : la hurtbox défendrait sinon avec l'ancienne fiche.
	hurtbox.stats = stats
	_reach_out()


## Ce que les buffs allumés versent dans la fiche, par point placé : les lignes d'un
## passif, par la même fonction. Un livre parti éteint la case et vide ses lignes.
func buff_mods() -> Array[StatMod]:
	var out: Array[StatMod] = []
	for skill in lit_skills():
		# Une ligne est linéaire en points : ses charges la multiplient de la même façon. Un
		# buff sans charges propres en porte sous le Galop (jalon 43).
		var times := lit_stacks(skill.id) if skill.stacks_max > 0 else maxi(lit_stacks(skill.id), 1)
		# L'Épiphanie (jalon 48) : tant qu'elle brûle, la lumière verse ses lignes deux fois.
		if skill.id == SkillStats.LIGHT_SKILL and resolve(skill, skill_points(skill.id)).epiphany > 0.0:
			times *= SkillStats.EPIPHANY_FACTOR
		out.append_array(skill.buff_mods(skill_points(skill.id) * times))
		# Le Berserk (jalon 50) : à pleines charges, l'attaque s'emballe.
		if skill.id == SkillStats.FRENZY_SKILL:
			var own := resolve(skill, skill_points(skill.id))
			if own.berserk > 0.0 and lit_stacks(skill.id) >= Buff.cap_of(skill, own):
				out.append(StatMod.new("attack_speed", StatMod.Mode.MORE, SkillStats.BERSERK_SPEED))
		# Le Pas de côté (jalon 50) : ce que chaque esquive récente ajoute.
		if skill.id == SkillStats.COUNTER_SKILL and _sidesteps > 0:
			var counter := resolve(skill, skill_points(skill.id))
			out.append(StatMod.new("evasion", StatMod.Mode.FLAT, counter.sidestep * float(_sidesteps)))
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

	model.set_archetype(character.archetype())
	instrument = character.instrument()
	var lift := SpriteForge.head_room(character.archetype())
	health_bar.lift = lift
	hurtbox.feedback_lift = lift
	model.set_variant(character.silhouette)
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
	character.silhouette = model.current_variant()

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
	model.set_weapon(weapon_kind())
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
func reward(raw: float, zone_level_value: int, where: Vector3) -> int:
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


func _on_hitbox_area_entered(area: Area3D) -> void:
	if not area is Hurtbox or area in _already_hit:
		return
	_already_hit.append(area)   # un swing ne touche une cible qu'une fois

	var info := DamageInfo.roll(
		_hit_cast, global_position, _hit_parts, stats.knockback_force + _hit_cast.knockback
	)
	info.author = states
	(area as Hurtbox).take_damage(info)
	heal(_hit_cast.life_on_hit)
	_drain_bite(_hit_cast, info.amount)
	_bitten(area as Hurtbox, _hit_cast)
	# Les Mâchoires de fer (jalon 53) : la Gueule béante accroche plus au premier mordu.
	if _already_hit.size() == 1 and _hit_cast.iron_jaws > 0.0 and (area as Hurtbox).states != null:
		(area as Hurtbox).states.add_rats(
			int(_hit_cast.iron_jaws), info.amount * StatusEffects.GNAW_PART * (1.0 + _hit_cast.fangs * 0.01),
			states, _hit_cast.skill_id, _hit_cast
		)
	_shove(area as Hurtbox, _hit_cast, global_position, info.knockback)
	if _hit_index == 1 and _hit_cast.bloodletting > 0.0:
		_bleed_out(area as Hurtbox, _hit_cast)

	# **Au premier touché seulement** : un balayage est un geste, pas cinq.
	if _already_hit.size() == 1:
		Game.hit_stop(_stop_of(_hit_cast))
		Game.shake_camera(camera, _hit_shake)
		# L'Escorte (jalon 46) : une épée de la ronde suit la Frappe lourde et le Coup en croix.
		if _crown != null and _hit_index == 0 and _hit_cast.skill_id in SkillStats.ESCORTED:
			_crown.escort(area as Hurtbox)
		# Le Coup de massue (jalon 46) : le coup sûr frappe aussi autour de sa cible.
		if _hit_cast.is_sure and _hit_cast.maul > 0.0:
			Explosion.put(
				_effects_parent(), area.global_position,
				DamageType.scaled(_hit_parts, SkillStats.MAUL_PART), SkillStats.MAUL_RADIUS, area,
				DamageType.COLORS[_hit_cast.nature], states, _hit_cast
			)


## La Saignée (jalon 46) : le second coup de la croix vide le saignement d'un coup, plus fort ;
## la Transfusion en rend une part. Un coup de plus, sans critique ni état propre : ce qui
## restait à saigner.
func _bleed_out(target: Hurtbox, cast: SkillStats) -> void:
	if target.states == null:
		return
	var left := target.states.drain(StatusEffects.Kind.BLEED) * (1.0 + cast.bloodletting * 0.01)
	if left <= 0.0:
		return
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.PHYSICAL] = left
	Targets.strike(target, parts, global_position, states, cast.bled())
	heal(left * cast.transfusion * 0.01)


## Le gel d'un coup : celui du jeu, doublé sous le Coup sûr (jalon 46).
func _stop_of(cast: SkillStats) -> float:
	return Game.hit_stop_duration * (SkillStats.SURE_STOP if cast.is_sure else 1.0)


## La Collision (jalon 46) : le repoussé est armé pour blesser celui qu'il heurtera ; les
## Quilles lui passent le recul du coup.
func _shove(target: Hurtbox, cast: SkillStats, from_value: Vector3, knockback: float) -> void:
	if cast.collision <= 0.0 or knockback <= 0.0:
		return
	var enemy := target.get_parent() as Enemy
	if enemy != null and not enemy.is_dead:
		enemy.shove(
			cast.collided(), states, from_value.direction_to(enemy.global_position),
			knockback if cast.skittles > 0.0 else 0.0
		)


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return
	# Le Brise-lames (jalon 46) : une épée de la ronde prend le coup à sa place.
	if _crown != null and _crown.take_blow():
		return
	var lost := JudgmentChains.divert(self, info.amount)
	var necrosis := _necrosis()
	if necrosis != null and health - lost <= 0.0 and _spared(necrosis):
		return
	# L'Exutoire (jalon 45) : un gros coup reçu libère le Fardeau sur-le-champ.
	if necrosis != null and necrosis.outlet > 0.0 and lost >= stats.max_health * SkillStats.OUTLET_LOSS:
		(_lit[SkillStats.NECROSIS_SKILL] as Buff).unburden(necrosis)
	_set_health(health - lost)
	_intercede(info, lost)
	_riposte_left = SkillStats.RIPOSTE_WINDOW
	_reprisal(info)
	velocity += (global_position - info.source_position).normalized() * info.knockback
	model.flash()
	if health <= 0.0:
		_die()
		return
	RottingGate.provoke(self)
	_sign()
	if _startle_wait <= 0.0:
		_startle(lost)


## Les Représailles (jalon 50) : sous la Contre-attaque, un coup reçu peut aussi appeler une
## riposte, à sa chance.
func _reprisal(info: DamageInfo) -> void:
	if not lit(SkillStats.COUNTER_SKILL) or _counter_wait > 0.0:
		return
	var counter := resolve(SkillCatalog.by_id(SkillStats.COUNTER_SKILL), skill_points(SkillStats.COUNTER_SKILL))
	if counter.reprisal > 0.0 and Game.rng.randf() * 100.0 < counter.reprisal:
		_counter_wait = SkillStats.RIPOSTE_WAIT
		_riposte.call_deferred(info.source_position)


## La Signature (jalon 49) : un coup reçu trace un glyphe à vos pieds, dans l'élément du tour,
## au plus un toutes les `SIGNATURE_GAP` secondes — de jeu, comme la garde des réactions.
func _sign() -> void:
	var id := SkillStats.GLYPH_SKILL
	var now := Engine.get_physics_frames()
	if skill_points(id) <= 0 or now - _signed_at < roundi(SkillStats.SIGNATURE_GAP * Engine.physics_ticks_per_second):
		return
	var skill := SkillCatalog.by_id(id)
	var cast := resolve(skill, skill_points(id))
	if cast.signature <= 0.0:
		return
	_signed_at = now
	Glyph.place(self, self, global_position, cast, _effects_parent())
	_turns[id] = int(_turns.get(id, 0)) + 1


## L'Intercession (jalon 48) : sous la lumière, un gros coup bénit son auteur à coup sûr, et
## plus fort. Comme l'Auréole, elle pose l'état sans frapper.
func _intercede(info: DamageInfo, lost: float) -> void:
	if info.author == null or lost < stats.max_health * SkillStats.INTERCESSION_LOSS:
		return
	var light := _holy_light()
	if light != null and light.intercession > 0.0:
		info.author.put(
			StatusEffects.Kind.BLESSING, 0.0, states, SkillStats.LIGHT_SKILL,
			light.strength_of(StatusEffects.Kind.BLESSING) * (1.0 + light.intercession * 0.01)
		)


## Le Sursis (jalon 45) : un coup mortel laisse en vie et éteint la Nécrose ; sous le
## Revenant, il revient plus vite et laisse davantage.
func _spared(necrosis: SkillStats) -> bool:
	if necrosis.reprieve <= 0.0 or _reprieve_wait > 0.0:
		return false
	var revenant := necrosis.revenant > 0.0
	_reprieve_wait = SkillStats.REVENANT_PERIOD if revenant else SkillStats.REPRIEVE_PERIOD
	extinguish(SkillStats.NECROSIS_SKILL)
	_set_health(stats.max_health * SkillStats.REVENANT_HEALTH if revenant else 1.0)
	return true


## Le Sursaut (jalon 44) : un coup qui ôte assez de vie fait partir la nova d'elle-même,
## sans coût, depuis le lanceur. Résolue à ce seul moment : un coup reçu est rare. Posée
## en différé : le coup arrive d'un rappel de collision (invariant 4).
func _startle(lost: float) -> void:
	var skill := SkillCatalog.by_id(SkillStats.STARTLE_SKILL)
	var points := skill_points(skill.id)
	if points <= 0:
		return
	var nova := resolve(skill, points)
	if nova.startle <= 0.0:
		return
	var alert := nova.alert > 0.0
	if lost < stats.max_health * (SkillStats.ALERT_LOSS if alert else SkillStats.STARTLE_LOSS):
		return
	_startle_wait = SkillStats.ALERT_PERIOD if alert else SkillStats.STARTLE_PERIOD
	_pose.call_deferred(skill, [nova] as Array[SkillStats], self, facing, global_position)


## Le drapeau évite plusieurs `died` : plusieurs grunts frappent dans la même image.
func _die() -> void:
	if is_dead or _reborn():
		return
	is_dead = true
	set_physics_process(false)
	velocity = Vector3.ZERO
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
		Explosion.of_cast(
			_effects_parent(), global_position, cast, cast.radius * SkillStats.REBIRTH_REACH, states
		)
		return true
	return false


func revive() -> void:
	is_dead = false
	# Un corps tombé encaisse toujours : ses tirages ont pu reposer des états.
	states.clear()
	_set_health(stats.max_health)
	_set_mana(stats.max_mana)
	velocity = Vector3.ZERO
	set_physics_process(true)
