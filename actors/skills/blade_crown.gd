class_name BladeCrown
extends Node2D

## Les épées d'Épée spirale, qui tournent autour du joueur. Un seul nœud pour
## toutes : elles partagent une rotation, et se répartissent dessus. Chacune tourne au
## rayon de son lancer (Orbite large, jalon 39).

## Radians par seconde : un tour en un peu moins d'une seconde et demie.
const ROTATION := 4.2
## Du centre d'une épée au centre d'une hurtbox ennemie.
const CONTACT := 14.0
## Le temps que met une épée lancée à rejoindre le cercle.
const OUTPUT := 0.15
## Sans glissement, les survivantes sautent d'un tiers de tour quand une épée part.
const SLIDE := 8.0
const VANISH := 0.5
## Les images rémanentes : leur retard sur l'épée en radians, et la part d'elles que
## laisse leur trame.
const AFTERIMAGES := [[0.22, 0.30], [0.44, 0.14]]


class Blade:
	var cast: SkillStats
	var contacts: Targets.Contacts
	var age := 0.0
	var place := 0.0
	## L'Affûtage (jalon 46) : les ennemis qu'elle a coupés. La Parade : son attente.
	var honed := 0
	var parry_wait := 0.0


var _blades: Array[Blade] = []
var _rotation := 0.0
## Celui qui les a lancées, pour ce que ses états changent à leurs coups. Posé une
## fois : la couronne ne change pas de porteur.
var author: StatusEffects
## Où partent les épées d'une volée : hors du porteur, qui les emmènerait avec lui.
var effects: Node
## Le Brise-lames (jalon 46) : l'attente avant qu'une épée puisse encaisser un autre coup.
var _breakwater_wait := 0.0


func _ready() -> void:
	z_index = 1


func count() -> int:
	return _blades.size()


## Zéro : sans limite.
func full(maximum: int) -> bool:
	return maximum > 0 and _blades.size() >= maximum


func add_to(cast: SkillStats) -> void:
	var blade := Blade.new()
	blade.cast = cast
	blade.contacts = Targets.Contacts.new(cast.period)
	# Elle naît à la place qui l'attend : ce sont les autres qui glissent.
	blade.place = TAU * float(_blades.size()) / float(_blades.size() + 1)
	_blades.append(blade)
	_shelter_changed(cast)


func clear() -> void:
	_blades.clear()
	queue_redraw()
	_shelter_changed(null)


## Bouclier de lames (jalon 39) : les points de dégâts subis que retirent les épées qui
## tournent, que `Player.recompute_stats()` lit comme le Rempart d'os.
func ward() -> float:
	var total := 0.0
	for blade in _blades:
		total += blade.cast.blade_ward
	return total


## L'abri change avec chaque épée qui naît ou part : la fiche du porteur se refait.
func _shelter_changed(cast: SkillStats) -> void:
	if (cast == null or cast.blade_ward > 0.0) and get_parent() is Player:
		(get_parent() as Player).recompute_stats()


func _physics_process(delta: float) -> void:
	_breakwater_wait = maxf(_breakwater_wait - delta, 0.0)
	if _blades.is_empty():
		return
	# La Valse (jalon 46) : la plus rapide mène la ronde ; la Ronde folle la double encore.
	var waltz := 0.0
	for blade in _blades:
		waltz = maxf(waltz, blade.cast.waltz)
	var spin := ROTATION * (1.0 + waltz * 0.01) * (SkillStats.MAD_SPIN if _madness() > 0.0 else 1.0)
	_rotation = fmod(_rotation + spin * delta, TAU)
	var alive_ones: Array[Blade] = []
	var gone: Array[Blade] = []
	for blade in _blades:
		blade.age += delta
		blade.contacts.advance(delta)
		if blade.age < blade.cast.duration:
			alive_ones.append(blade)
		else:
			gone.append(blade)
	# Hors de la liste d'abord : sinon la fiche refaite les compterait encore.
	_blades = alive_ones
	for blade in gone:
		_leave(blade)
	var slides := 1.0 - exp(-SLIDE * delta)
	for i in _blades.size():
		_blades[i].place = lerp_angle(_blades[i].place, TAU * float(i) / float(_blades.size()), slides)
	_slice()
	_parry(delta)
	queue_redraw()


## Une épée au bout de sa durée : sous la Volée d'épées, elle part d'où elle tourne.
func _leave(blade: Blade) -> void:
	if blade.cast.sword_volley > 0.0:
		var at := to_global(_center(blade, _rotation + blade.place))
		var sword := FlyingSword.throw(effects, at, at - global_position, blade.cast, author)
		if blade.cast.rally > 0.0:
			sword.home = self
	_shelter_changed(blade.cast)


## Le Ralliement (jalon 46) : une épée de la volée revient tourner, pour peu de temps, sans
## repartir — dans la limite de la ronde.
func rally(cast: SkillStats) -> void:
	if full(cast.max_simultaneous()):
		return
	var back := cast.echoed(1.0)
	back.duration = SkillStats.RALLY_LIFE
	back.sword_volley = 0.0
	add_to(back)


## Le Brise-lames (jalon 46) : une épée qui le porte se brise à la place du coup. Vrai si
## elle l'a pris : le coup ne fait rien. La Grenaille la fait éclater autour du porteur.
func take_blow() -> bool:
	if _breakwater_wait > 0.0:
		return false
	for blade in _blades:
		if blade.cast.breakwater <= 0.0:
			continue
		_blades.erase(blade)
		_breakwater_wait = SkillStats.BREAKWATER_WAIT
		if blade.cast.grapeshot > 0.0:
			Explosion.put(
				effects, global_position,
				DamageType.scaled(blade.cast.roll(Game.rng), blade.cast.grapeshot * 0.01),
				SkillStats.GRAPESHOT_RADIUS, null, DamageType.COLORS[blade.cast.nature], author,
				blade.cast
			)
		_shelter_changed(blade.cast)
		queue_redraw()
		return true
	return false


## L'Escorte (jalon 46) : un coup d'arme envoie le double d'une épée de la ronde sur sa
## cible, à la part de l'Escorte ; l'épée, elle, continue de tourner.
func escort(target: Hurtbox) -> void:
	if _blades.is_empty() or _blades[0].cast.escort <= 0.0:
		return
	var blade := _blades[0]
	var at := to_global(_center(blade, _rotation + blade.place))
	var sent := blade.cast.echoed(blade.cast.escort * 0.01)
	sent.sword_volley = at.distance_to(target.global_position) + CONTACT
	sent.rally = 0.0
	FlyingSword.throw(effects, at, at.direction_to(target.global_position), sent, author, target)


## La Parade (jalon 46) : une épée qui croise un trait ennemi le brise, puis attend.
func _parry(delta: float) -> void:
	var widest := 0.0
	for blade in _blades:
		blade.parry_wait = maxf(blade.parry_wait - delta, 0.0)
		if blade.cast.parry > 0.0:
			widest = maxf(widest, blade.cast.radius)
	if widest <= 0.0:
		return
	var bolts := Targets.bolts_in_circle(get_world_2d(), global_position, widest + CONTACT)
	for blade in _blades:
		if blade.cast.parry <= 0.0 or blade.parry_wait > 0.0:
			continue
		var center := to_global(_center(blade, _rotation + blade.place))
		for bolt in bolts:
			if is_instance_valid(bolt) and not bolt.is_queued_for_deletion() \
					and center.distance_to(bolt.global_position) <= CONTACT:
				bolt.queue_free()
				blade.parry_wait = SkillStats.PARRY_WAIT / blade.cast.parry
				break


## La Ronde folle (jalon 46) : ce que le Cyclone allumé du porteur donne à ses épées.
func _madness() -> float:
	var player := get_parent() as Player
	return player.spin_madness() if player != null else 0.0


func _slice() -> void:
	if _blades.is_empty():
		return
	var widest := 0.0
	for blade in _blades:
		widest = maxf(widest, blade.cast.radius)
	var targets := Targets.in_circle(get_world_2d(), global_position, widest + CONTACT)
	var mad := 1.0 + _madness() * 0.01
	for blade in _blades:
		var center := to_global(_center(blade, _rotation + blade.place))
		for target in targets:
			if center.distance_to(target.global_position) <= CONTACT and blade.contacts.accepts(target):
				# L'Affûtage (jalon 46) : chaque coupé rend la suivante plus forte.
				var honed := 1.0 + blade.cast.honing * 0.01 * float(blade.honed)
				var parts := DamageType.scaled(blade.cast.roll(Game.rng), honed * mad)
				Targets.strike(target, parts, center, author, blade.cast)
				if blade.cast.honing > 0.0:
					blade.honed = mini(blade.honed + 1, SkillStats.HONING_MOST)


func _center(blade: Blade, angle: float) -> Vector2:
	return Vector2.from_angle(angle) * blade.cast.radius * smoothstep(0.0, OUTPUT, blade.age)


## L'épée **dessinée**, tournée au cap de sa course par `Slash.sword()`, et ses
## images rémanentes réduites à leur silhouette et **tramées** plutôt que
## transparentes : une ombre à 30 % d'opacité sur un sol sombre sortait grise.
##
## Tangente au cercle, pointe en avant : l'épée file dans le sens où elle tourne.
## Pointée vers l'extérieur, elle se lisait comme une lame de scie.
func _draw() -> void:
	for blade in _blades:
		var angle := _rotation + blade.place
		var fade := clampf((blade.cast.duration - blade.age) / VANISH, 0.0, 1.0)
		var gone := floorf((1.0 - fade) * 4.0) / 4.0
		var tint: Color = DamageType.COLORS[blade.cast.nature]
		for r: Array in AFTERIMAGES:
			var delay := angle - float(r[0])
			Slash.sword(
				tint, Slash.turn_of(delay + PI * 0.5), true, maxf(1.0 - float(r[1]), gone)
			).put(self, _center(blade, delay))
		Slash.sword(tint, Slash.turn_of(angle + PI * 0.5), false, gone).put(
			self, _center(blade, angle)
		)
