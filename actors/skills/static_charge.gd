class_name StaticCharge
extends Node2D

## Une étincelle laissée sur un engourdi : elle s'écarte de quelques pixels, puis frappe
## ce qui entre dans son petit rayon. **Une fois par ennemi, et elle reste** : elle vit
## ses deux secondes quoi qu'elle touche, et une nuée qui la traverse la paie autant de
## fois qu'elle compte de corps.
##
## **Elle naît en différé** : le coup qui la laisse arrive dans un rappel de collision,
## où rien n'entre dans l'arbre et où l'espace refuse les requêtes (invariant 4). Sa
## première sonde tombe une période plus tard, donc jamais dans cette image-là.

## Ce qu'elle porte du coup qui l'a laissée, en foudre quelle que soit la nature de ce
## coup : une charge statique de feu se lirait comme un bug.
const SHARE := 0.20
const LIFE := 2.0
## Petit : elle récompense un ennemi qui marche dessus, elle ne couvre pas une zone.
const RADIUS := 7.0
## Sur toute sa vie, en pixels.
const DRIFT := 10.0
## Entre deux sondes. Soixante par seconde et par charge ne se verraient pas.
const CHECK := 0.1
## Plafond : une compétence rapide sur une nuée d'engourdis en sèmerait des centaines,
## chacune sondant son entourage. La plus vieille cède sa place.
const MAX_LIVE := 24

## Toutes celles qui vivent, dans l'ordre de naissance.
static var _live: Array[StaticCharge] = []

var _parts: Array[float] = []
var _author: StatusEffects
var _toward := Vector2.ZERO
var _age := 0.0
var _next := CHECK
## Qui elle a déjà mordu. Sa période est sa vie entière : une cible plantée dessus ne
## la paie pas vingt fois.
var _bitten := Targets.Contacts.new(LIFE)
var _radius := RADIUS
var _mine := false
var _life := LIFE
var _on_bite := Callable()


## `parts` est ce que le coup a **réellement** infligé : la charge est petite quand
## l'armure a mangé le coup. Celles qu'une ruée sème portent leur propre part.
static func put(
	parent: Node, at: Vector2, direction: Vector2, parts: Array, author: StatusEffects,
	share := SHARE, mine := false, life := LIFE, on_bite := Callable()
) -> StaticCharge:
	var charge := StaticCharge.new()
	# La Capacité (jalon 43) : plus longue, elle garde sa morsure pour toute sa vie. Le
	# Condensateur apprend chacune de ses morsures.
	charge._life = life
	charge._bitten = Targets.Contacts.new(life)
	charge._on_bite = on_bite
	# Les Mines statiques (jalon 43) : plus fortes et plus larges, elles ne mordent qu'une fois.
	if mine:
		share *= SkillStats.MINE_FACTOR
		charge._radius = RADIUS * SkillStats.MINE_REACH
		charge._mine = true
	var total := 0.0
	for part in parts:
		total += float(part)
	charge._parts = DamageType.empty_parts()
	charge._parts[DamageType.Kind.LIGHTNING] = total * share
	charge._author = author
	charge._toward = direction.normalized() * DRIFT
	# Le filtre plutôt que la seule sortie d'arbre : une charge dont le parent a disparu
	# avant l'appel différé est libérée sans jamais y entrer.
	_live = _live.filter(func(c: StaticCharge) -> bool: return is_instance_valid(c))
	_live.append(charge)
	if _live.size() > MAX_LIVE:
		_live.pop_front().queue_free()
	Settings.veil(charge, Settings.SPELLS)
	DeferredTree.add_deferred(parent, charge, at)
	return charge


## Celles qui vivent : le Relais de la Chaîne d'éclairs (jalon 43) y saute.
static func live() -> Array[StaticCharge]:
	_live = _live.filter(func(c: StaticCharge) -> bool: return is_instance_valid(c))
	return _live


func _ready() -> void:
	z_index = 3


func _exit_tree() -> void:
	_live.erase(self)


func _physics_process(delta: float) -> void:
	_age += delta
	# Elle s'écarte vite puis se pose : une étincelle est projetée, elle ne dérive pas.
	position += _toward * delta * maxf(1.0 - _age / LIFE, 0.0) * 2.0
	queue_redraw()
	if _age >= _life:
		queue_free()
		return
	if _age < _next:
		return
	_next = _age + CHECK
	_bitten.advance(CHECK)
	for target in Targets.in_circle(get_world_2d(), global_position, _radius):
		if not _bitten.accepts(target):
			continue
		# Sans lancer : une charge ne critique pas et ne porte aucun bonus contre un état.
		Targets.strike(target, _parts, global_position, _author, null)
		if _on_bite.is_valid():
			_on_bite.call(_parts[DamageType.Kind.LIGHTNING])
		if _mine:
			queue_free()
			return


## L'étoile brisée, choisie sur planche : ses bras tournent et grésillent, décalés
## d'une charge à l'autre pour que deux voisines ne battent pas à l'unisson. Elle se
## défait sur son dernier tiers : disparaître d'un coup se lit comme un bug.
func _draw() -> void:
	Lightning.charge(
		DamageType.COLORS[DamageType.Kind.LIGHTNING], _radius,
		Lightning.hold(_age) + int(get_instance_id()), Lightning.gone(_age, _life)
	).put(self, Vector2.ZERO)
