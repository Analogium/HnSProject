class_name Bloater
extends Enemy

## Le champignon (jalon 27). Il fonce, s'arrête au contact, enfle — il clignote et
## tremble sur sa zone — puis éclate en spores. **Tué, il éclate aussi**, après une
## mèche plus courte : l'achever au contact est un risque qu'on choisit.

const ACCEL := 0.12
const SWELL := 0.7
const DEATH_FUSE := 0.35
const BLAST := 38.0
## Un clignotement toutes les… ; plus serré, le flash (0,08 s) ne s'éteint plus.
const PULSE := 0.16

## Posée en enflant ou en mourant : une seule explosion par corps.
var _zone: DangerZone
var _timer := 0.0
var _pulse := 0.0


func tick(delta: float) -> void:
	if not _should_act():
		return
	if _zone != null:
		_swell(delta)
		return
	var victim := foe()
	if global_position.distance_to(victim.global_position) < stats.attack_range:
		velocity = Vector2.ZERO
		sprite.set_state(false, victim.global_position - global_position)
		_zone = _burst(SWELL)
		_timer = SWELL
		return
	_close_in(victim, ACCEL)
	_animate()


## Sur l'horloge de la zone et non ralentie par le gel : il meurt quand elle frappe.
func _swell(delta: float) -> void:
	_timer -= delta
	_pulse -= delta
	if _pulse <= 0.0:
		_pulse = PULSE
		sprite.flash()
	sprite.position.x = 1.0 if sprite.position.x <= 0.0 else -1.0
	if _timer <= 0.0:
		# Ce n'est pas une victoire du joueur : ni expérience ni butin.
		die(false)


## Non liée à lui : elle frappe même s'il meurt en enflant.
func _burst(fuse: float) -> DangerZone:
	var zone := DangerZone.put(manager.ground(), global_position, DangerZone.Shape.DISC, BLAST, fuse)
	zone.parts = DamageType.empty_parts()
	zone.parts[DamageType.Kind.NECROTIC] = stats.attack_damage
	zone.author = states
	return zone


## Une mort sans victoire (vidage, rechargement) n'éclate pas : la zone suivante
## hériterait d'une explosion.
func die(award := true) -> void:
	if not is_dead and award and _zone == null and manager != null:
		_zone = _burst(DEATH_FUSE)
	super(award)
