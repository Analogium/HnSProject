class_name StatusEffects
extends RefCounted

## Ce qu'un coup laisse sur ce qu'il touche — embrasement, engourdissement, gel,
## pourriture, bénédiction, saignement —, un par corps, posé sur sa hurtbox. « États »
## et non « effets », qui désignent ici ce qui se dessine. Tirés par
## `Hurtbox.take_damage()` ; chaque porteur applique les facteurs là où vit la règle.
## Tous se portent à la fois ; seuls deux de la même sorte ne se cumulent pas. Jamais
## sauvegardés. Ne nomme ni `DamageInfo` ni `Hurtbox`, qui le nomment.

## Un état est apparu ou a pris fin — pas au rafraîchissement : c'est ce qui redessine.
signal change
## Un état **neuf** vient de se poser.
signal reached(kind: int)
## Ce que la pourriture posée par ce corps sur un autre lui rend.
signal heal(amount: float)

## **Ajouter à la fin** : les tables ci-dessous sont indexées par cette enum.
enum Kind { IGNITE, NUMB, CHILL, ROT, BLESSING, BLEED }

## La nature qui pose chaque état. **Chaque nature en pose exactement un**, le
## physique compris : le saignement est ce que laisse une lame.
const NATURES := [
	DamageType.Kind.FIRE,
	DamageType.Kind.LIGHTNING,
	DamageType.Kind.COLD,
	DamageType.Kind.NECROTIC,
	DamageType.Kind.HOLY,
	DamageType.Kind.PHYSICAL,
]

## Le mot qui s'envole au-dessus du joueur atteint.
const NAMES := ["embrasé", "engourdi", "transi", "pourrissant", "béni", "saignant"]

## En secondes. Le gel est plus court : quatre secondes au ralenti se liraient comme
## du lag.
const DURATIONS := [4.0, 4.0, 2.0, 4.0, 4.0, 4.0]

## Pour un coup **entièrement** d'une nature ; un coup mêlé la partage selon ses parts
## (jalon 8). **Premier réglage**, comme tous les nombres de ce fichier.
const CHANCE := 0.20
## Ajouté à `CHANCE` par PV max retiré : à 1, un coup qui ôte toute la vie pose à coup sûr.
const CHANCE_PER_HP_LOST := 1.0

## Part du feu **reçu** brûlée par seconde : le coup se rejoue en entier sur la durée.
const IGNITE_PER_SECOND := 0.25
## Une petite brûlure : 40 % du nécrotique reçu, sur la durée.
const ROT_PER_SECOND := 0.10
## La part de ce que brûle la pourriture qui revient à celui qui l'a posée.
const ROT_HEAL := 0.5
## Les dégâts reçus par l'engourdi, en plus.
const NUMB := 0.10
## La vitesse d'action retirée au transi : déplacement, attaque et incantation.
const CHILL := 0.25
## Les dégâts infligés retirés au béni.
const BLESSING := 0.20
## Part du physique reçu par seconde, la moitié du coup : moins que l'embrasement, le
## physique frappant bien plus souvent.
const BLEED_PER_SECOND := 0.125
## **La seule couleur qui ne vient pas de sa nature** : le blanc du physique se lirait
## comme un flash. Plus sombre que la barre de vie basse.
const BLOOD := Color(0.70, 0.08, 0.12)

## Les pertes sans coup s'affichent par paquets : un chiffre par image en ferait
## soixante, à « 0 ». C'est aussi la période d'Immolation.
const DISPLAY_PERIOD := 0.5


class State:
	var kind: int
	var remaining: float
	## Ce qu'il brûle par seconde, avant l'engourdissement. Zéro pour les trois qui
	## ne blessent pas.
	var per_second := 0.0
	## Faible : deux pourritures croisées se tiendraient en vie (RefCounted).
	var author: WeakRef


## Des pertes sans coup, montrées par paquets. Le joueur en a deux — Immolation et
## états —, qui n'avancent pas sur la même horloge.
class Pack:
	var _accumulated := 0.0
	var _from := 0.0

	## Ce qu'il faut montrer maintenant, ou zéro.
	func add_to(amount: float, delta: float) -> float:
		_accumulated += amount
		_from += delta
		return clear() if _from >= StatusEffects.DISPLAY_PERIOD else 0.0

	## Même avant la fin du paquet : la dernière demi-seconde reste à l'écran.
	func clear() -> float:
		var to_show := _accumulated
		_accumulated = 0.0
		_from = 0.0
		return to_show


## Recalculés quand les états changent et lus comme des champs : l'EnemyManager les
## lit pour chaque ennemi à chaque image. En lecture seule de fait.
var is_clear := true
var speed_factor := 1.0
var damage_taken_factor := 1.0
var damage_dealt_factor := 1.0

## Dans l'ordre où ils se sont posés : le dernier est le plus récent.
var _states: Array[State] = []
var _losses := Pack.new()
var _to_show := 0.0


## Le joueur et les ennemis ont un champ `states` ; un tir ne connaît que son lanceur.
## **Le seul endroit qui le lit par son nom.**
static func of(wearer: Object) -> StatusEffects:
	if not is_instance_valid(wearer):
		return null
	return wearer.get("states") as StatusEffects


static func name(kind: int) -> String:
	return Texts.t(NAMES[kind])


## `DamageType.COLORS`, sauf le saignement (`BLOOD`).
static func color(kind: int) -> Color:
	if kind == Kind.BLEED:
		return BLOOD
	return DamageType.COLORS[NATURES[kind]]


func active(kind: int) -> bool:
	return _state(kind) != null


func remaining(kind: int) -> float:
	var state := _state(kind)
	return state.remaining if state != null else 0.0


## Les couleurs des états présents, du plus ancien au plus récent.
func colors() -> Array[Color]:
	var out: Array[Color] = []
	for state in _states:
		out.append(color(state.kind))
	return out


## Les états présents, du plus ancien au plus récent.
func kinds() -> Array[int]:
	var out: Array[int] = []
	for state in _states:
		out.append(state.kind)
	return out


## Sur les parts **après** défenses. **Un tirage par nature présente, quel que soit le
## résultat** (invariant 3).
## `max_hp` à zéro : pas de bonus, faute de PV connus.
func suffer(parts: Array[float], author: StatusEffects, rng: RandomNumberGenerator, max_hp := 0.0) -> void:
	var total := 0.0
	for part in parts:
		total += part
	if total <= 0.0:
		return
	for kind in NATURES.size():
		var part: float = parts[NATURES[kind]]
		if part > 0.0 and rng.randf() < chance(part, total, max_hp):
			put(kind, part, author)


## La part de la nature dans le coup, plus ce qu'elle retire des PV max : un coup de
## feu qui ôte 30 % de la vie embrase une fois sur deux, un petit coup sur une grosse
## cible garde ses 20 %.
static func chance(part: float, total: float, max_hp: float) -> float:
	var bonus := part / max_hp * CHANCE_PER_HP_LOST if max_hp > 0.0 else 0.0
	return CHANCE * part / total + bonus


## Pose ou rafraîchit ; `part` est ce que le coup a porté dans sa nature. Entre deux de
## la même sorte, ce qui brûle garde le plus fort — sinon de petites braises
## éteindraient la grosse ; les autres retrouvent leur durée.
func put(kind: int, part: float, author: StatusEffects = null) -> void:
	var per_second := part * _burn_per_second(kind)
	var state := _state(kind)
	var fresh := state == null
	if fresh:
		state = State.new()
		state.kind = kind
		_states.append(state)
	elif per_second < state.per_second:
		return
	state.remaining = DURATIONS[kind]
	state.per_second = per_second
	state.author = weakref(author) if author != null else null
	if fresh:
		_recompute()
		reached.emit(kind)
		change.emit()


## Rend ce que les états ont brûlé pendant ce pas, **à ôter par l'appelant**
## (`_set_health()`, invariant 5), engourdissement compris.
func advance(delta: float) -> float:
	if _states.is_empty():
		return 0.0
	var amplified := damage_taken_factor
	var loss := 0.0
	var finished := false
	for state in _states:
		if state.per_second > 0.0:
			var burns := state.per_second * minf(delta, state.remaining) * amplified
			loss += burns
			if state.kind == Kind.ROT:
				_heal_author(state, burns)
		state.remaining -= delta
		finished = finished or state.remaining <= 0.0
	if loss > 0.0:
		_to_show += _losses.add_to(loss, delta)
	if finished:
		_states = _states.filter(func(e: State) -> bool: return e.remaining > 0.0)
		_to_show += _losses.clear()
		_recompute()
		change.emit()
	return loss


## Le chiffre à faire s'envoler maintenant, ou zéro. Lu une fois : il se vide.
func digit() -> float:
	var to_show := _to_show
	_to_show = 0.0
	return to_show


## À la mort et à la résurrection : un corps relevé ne se relève pas en flammes.
func clear() -> void:
	_losses.clear()
	_to_show = 0.0
	if _states.is_empty():
		return
	_states.clear()
	_recompute()
	change.emit()


func _recompute() -> void:
	is_clear = _states.is_empty()
	speed_factor = 1.0 - CHILL if active(Kind.CHILL) else 1.0
	damage_taken_factor = 1.0 + NUMB if active(Kind.NUMB) else 1.0
	damage_dealt_factor = 1.0 - BLESSING if active(Kind.BLESSING) else 1.0


func _state(kind: int) -> State:
	for state in _states:
		if state.kind == kind:
			return state
	return null


func _burn_per_second(kind: int) -> float:
	match kind:
		Kind.IGNITE:
			return IGNITE_PER_SECOND
		Kind.ROT:
			return ROT_PER_SECOND
		Kind.BLEED:
			return BLEED_PER_SECOND
	return 0.0


## Un auteur mort rend null : personne n'est soigné.
func _heal_author(state: State, burns: float) -> void:
	if state.author == null:
		return
	var author := state.author.get_ref() as StatusEffects
	if author != null:
		author.heal.emit(burns * ROT_HEAL)
