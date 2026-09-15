class_name Etats
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
signal atteint(sorte: int)
## Ce que la pourriture posée par ce corps sur un autre lui rend.
signal soin(montant: float)

## **Ajouter à la fin** : les tables ci-dessous sont indexées par cette enum.
enum Sorte { EMBRASEMENT, ENGOURDISSEMENT, GEL, POURRITURE, BENEDICTION, SAIGNEMENT }

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
const NOMS := ["embrasé", "engourdi", "transi", "pourrissant", "béni", "saignant"]

## En secondes. Le gel est plus court : quatre secondes au ralenti se liraient comme
## du lag.
const DUREES := [4.0, 4.0, 2.0, 4.0, 4.0, 4.0]

## Pour un coup **entièrement** d'une nature ; un coup mêlé la partage selon ses parts
## (jalon 8). **Premier réglage**, comme tous les nombres de ce fichier.
const CHANCE := 0.20

## Part du feu **reçu** brûlée par seconde : le coup se rejoue en entier sur la durée.
const EMBRASEMENT_PAR_SECONDE := 0.25
## Une petite brûlure : 40 % du nécrotique reçu, sur la durée.
const POURRITURE_PAR_SECONDE := 0.10
## La part de ce que brûle la pourriture qui revient à celui qui l'a posée.
const SOIN_DE_POURRITURE := 0.5
## Les dégâts reçus par l'engourdi, en plus.
const ENGOURDISSEMENT := 0.10
## La vitesse d'action retirée au transi : déplacement, attaque et incantation.
const GEL := 0.25
## Les dégâts infligés retirés au béni.
const BENEDICTION := 0.20
## Part du physique reçu par seconde, la moitié du coup : moins que l'embrasement, le
## physique frappant bien plus souvent.
const SAIGNEMENT_PAR_SECONDE := 0.125
## **La seule couleur qui ne vient pas de sa nature** : le blanc du physique se lirait
## comme un flash. Plus sombre que la barre de vie basse.
const SANG := Color(0.70, 0.08, 0.12)

## Les pertes sans coup s'affichent par paquets : un chiffre par image en ferait
## soixante, à « 0 ». C'est aussi la période d'Immolation.
const PERIODE_D_AFFICHAGE := 0.5


class Etat:
	var sorte: int
	var restant: float
	## Ce qu'il brûle par seconde, avant l'engourdissement. Zéro pour les trois qui
	## ne blessent pas.
	var par_seconde := 0.0
	## Faible : deux pourritures croisées se tiendraient en vie (RefCounted).
	var auteur: WeakRef


## Des pertes sans coup, montrées par paquets. Le joueur en a deux — Immolation et
## états —, qui n'avancent pas sur la même horloge.
class Paquet:
	var _cumul := 0.0
	var _depuis := 0.0

	## Ce qu'il faut montrer maintenant, ou zéro.
	func ajouter(montant: float, delta: float) -> float:
		_cumul += montant
		_depuis += delta
		return vider() if _depuis >= Etats.PERIODE_D_AFFICHAGE else 0.0

	## Même avant la fin du paquet : la dernière demi-seconde reste à l'écran.
	func vider() -> float:
		var a_montrer := _cumul
		_cumul = 0.0
		_depuis = 0.0
		return a_montrer


## Recalculés quand les états changent et lus comme des champs : l'EnemyManager les
## lit pour chaque ennemi à chaque image. En lecture seule de fait.
var aucun := true
var facteur_de_vitesse := 1.0
var facteur_de_degats_subis := 1.0
var facteur_de_degats_infliges := 1.0

## Dans l'ordre où ils se sont posés : le dernier est le plus récent.
var _etats: Array[Etat] = []
var _pertes := Paquet.new()
var _a_montrer := 0.0


## Le joueur et les ennemis ont un champ `etats` ; un tir ne connaît que son lanceur.
## **Le seul endroit qui le lit par son nom.**
static func de(porteur: Object) -> Etats:
	if not is_instance_valid(porteur):
		return null
	return porteur.get("etats") as Etats


static func nom(sorte: int) -> String:
	return Textes.t(NOMS[sorte])


## `DamageType.COLORS`, sauf le saignement (`SANG`).
static func couleur(sorte: int) -> Color:
	if sorte == Sorte.SAIGNEMENT:
		return SANG
	return DamageType.COLORS[NATURES[sorte]]


func actif(sorte: int) -> bool:
	return _etat(sorte) != null


func restant(sorte: int) -> float:
	var etat := _etat(sorte)
	return etat.restant if etat != null else 0.0


## Les couleurs des états présents, du plus ancien au plus récent.
func couleurs() -> Array[Color]:
	var out: Array[Color] = []
	for etat in _etats:
		out.append(couleur(etat.sorte))
	return out


## Sur les parts **après** défenses. **Un tirage par nature présente, quel que soit le
## résultat** (invariant 3).
func subir(parts: Array[float], auteur: Etats, rng: RandomNumberGenerator) -> void:
	var total := 0.0
	for part in parts:
		total += part
	if total <= 0.0:
		return
	for sorte in NATURES.size():
		var part: float = parts[NATURES[sorte]]
		if part > 0.0 and rng.randf() < CHANCE * part / total:
			poser(sorte, part, auteur)


## Pose ou rafraîchit ; `part` est ce que le coup a porté dans sa nature. Entre deux de
## la même sorte, ce qui brûle garde le plus fort — sinon de petites braises
## éteindraient la grosse ; les autres retrouvent leur durée.
func poser(sorte: int, part: float, auteur: Etats = null) -> void:
	var par_seconde := part * _brulure_par_seconde(sorte)
	var etat := _etat(sorte)
	var neuf := etat == null
	if neuf:
		etat = Etat.new()
		etat.sorte = sorte
		_etats.append(etat)
	elif par_seconde < etat.par_seconde:
		return
	etat.restant = DUREES[sorte]
	etat.par_seconde = par_seconde
	etat.auteur = weakref(auteur) if auteur != null else null
	if neuf:
		_recalculer()
		atteint.emit(sorte)
		change.emit()


## Rend ce que les états ont brûlé pendant ce pas, **à ôter par l'appelant**
## (`_set_health()`, invariant 5), engourdissement compris.
func avancer(delta: float) -> float:
	if _etats.is_empty():
		return 0.0
	var amplifie := facteur_de_degats_subis
	var perte := 0.0
	var fini := false
	for etat in _etats:
		if etat.par_seconde > 0.0:
			var brule := etat.par_seconde * minf(delta, etat.restant) * amplifie
			perte += brule
			if etat.sorte == Sorte.POURRITURE:
				_soigner_l_auteur(etat, brule)
		etat.restant -= delta
		fini = fini or etat.restant <= 0.0
	if perte > 0.0:
		_a_montrer += _pertes.ajouter(perte, delta)
	if fini:
		_etats = _etats.filter(func(e: Etat) -> bool: return e.restant > 0.0)
		_a_montrer += _pertes.vider()
		_recalculer()
		change.emit()
	return perte


## Le chiffre à faire s'envoler maintenant, ou zéro. Lu une fois : il se vide.
func chiffre() -> float:
	var a_montrer := _a_montrer
	_a_montrer = 0.0
	return a_montrer


## À la mort et à la résurrection : un corps relevé ne se relève pas en flammes.
func vider() -> void:
	_pertes.vider()
	_a_montrer = 0.0
	if _etats.is_empty():
		return
	_etats.clear()
	_recalculer()
	change.emit()


func _recalculer() -> void:
	aucun = _etats.is_empty()
	facteur_de_vitesse = 1.0 - GEL if actif(Sorte.GEL) else 1.0
	facteur_de_degats_subis = 1.0 + ENGOURDISSEMENT if actif(Sorte.ENGOURDISSEMENT) else 1.0
	facteur_de_degats_infliges = 1.0 - BENEDICTION if actif(Sorte.BENEDICTION) else 1.0


func _etat(sorte: int) -> Etat:
	for etat in _etats:
		if etat.sorte == sorte:
			return etat
	return null


func _brulure_par_seconde(sorte: int) -> float:
	match sorte:
		Sorte.EMBRASEMENT:
			return EMBRASEMENT_PAR_SECONDE
		Sorte.POURRITURE:
			return POURRITURE_PAR_SECONDE
		Sorte.SAIGNEMENT:
			return SAIGNEMENT_PAR_SECONDE
	return 0.0


## Un auteur mort rend null : personne n'est soigné.
func _soigner_l_auteur(etat: Etat, brule: float) -> void:
	if etat.auteur == null:
		return
	var auteur := etat.auteur.get_ref() as Etats
	if auteur != null:
		auteur.soin.emit(brule * SOIN_DE_POURRITURE)
