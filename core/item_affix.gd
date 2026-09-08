class_name ItemAffix
extends Resource

## La *définition* d'un affixe d'objet : quelle statistique, et son échelle de
## paliers. Le tirage, lui, donne un RolledAffix — un affixe sur le disque, mille
## exemplaires différents en jeu.
##
## Une fourchette et non une valeur fixe : c'est elle qui fait qu'on regarde
## deux épées « acérées » avant de choisir. Sans elle, un affixe est un
## interrupteur et deux objets du même type sont interchangeables.
##
## Et une **échelle** de fourchettes depuis le jalon 5 : le niveau de l'objet
## ouvre des paliers, et c'est par là que descendre plus bas rapporte mieux.

@export var id: String = ""

## Les étiquettes qu'une base doit porter pour recevoir cet affixe : **une seule
## suffit**. Une armure ne donne pas d'allonge, une épée ne donne pas de PV —
## sans ce filtre, tous les objets se valent et le type de base ne veut plus rien
## dire.
##
## Des étiquettes et non des familles ; le champ s'appelait `families` jusqu'au
## jalon 5. Une épée et une baguette sont toutes deux de famille `weapon`, et il
## fallait pouvoir donner les dégâts d'attaque à l'une seulement. Voir
## `ItemBase.tags`.
##
## Vide = partout, sous réserve d'`exclut`. Utile pour un affixe volontairement
## universel — les résistances — et ça évite d'énumérer trente bases.
@export var tags: PackedStringArray = PackedStringArray()

## Les étiquettes qui interdisent cet affixe, quoi qu'en dise `tags` : une seule
## suffit à refuser, et **elle l'emporte**.
##
## C'est elle qui écrit « partout sauf sur les armes » en une ligne au lieu de
## neuf, et surtout : une base ajoutée plus tard hérite du refus sans qu'on ait
## à y penser, là où une liste d'autorisations l'aurait oubliée en silence.
@export var exclut: PackedStringArray = PackedStringArray()

## Le champ de CharacterStats touché. Doit exister : voir StatMod.LABELS.
@export var stat: String = "attack_damage"

## Pourcentage plutôt que valeur absolue. Les deux existent pour la même
## statistique — « +6 dégâts » sur une arme de début vaut mieux que « +10 % »,
## l'inverse en fin de partie.
@export var percent: bool = false

## Les paliers, **du meilleur au pire** : le premier de la liste est le T1. Le
## numéro est donc une position et non un champ à saisir — deux paliers portant
## le même numéro seraient invérifiables autrement.
##
## Le nombre de paliers dépend de l'affixe : neuf pour l'armure qui progresse par
## grands bonds, cinq pour la vitesse de déplacement qu'on veut garder serrée.
## C'est ce qui fait que deux affixes ne se lisent pas à la même échelle.
@export var tiers: Array[ItemAffixTier] = []

## Le pas d'arrondi de la valeur tirée : 1 pour un affixe entier, 0.01 pour une
## fraction. « +7 dégâts » se lit, « +7.3184 dégâts » non, et l'infobulle ne doit
## pas mentir sur ce qui est réellement appliqué.
##
## Un champ et non une déduction depuis la borne haute, comme avant les paliers :
## une même échelle peut passer sous 1 en bas et au-dessus en haut, et la règle
## déduite aurait arrondi les paliers d'un même affixe différemment — des
## dégâts critiques affichés « +0,35 » à un palier et « +1 » au suivant.
@export var arrondi: float = 1.0

## Poids dans la réserve. Un affixe rare n'est pas un affixe fort — c'est un
## affixe qu'on est content de voir.
@export var weight: int = 10


## Le refus d'abord : `exclut` l'emporte sur `tags`, sinon « partout sauf les
## armes » se lirait « partout, y compris les armes qui portent une étiquette
## autorisée ».
func fits(base: ItemBase) -> bool:
	if base == null:
		return false
	for t in exclut:
		if base.tags.has(t):
			return false
	if tags.is_empty():
		return true
	for t in tags:
		if base.tags.has(t):
			return true
	return false


## Combien de paliers restent ouverts en même temps : le meilleur qu'un objet
## atteint, et les trois du dessous.
##
## **Une fenêtre et non un plafond.** Le niveau d'objet ouvrait les bons paliers
## sans jamais fermer les mauvais : un objet de niveau 60 pouvait donc sortir le
## T8, celui des premières zones, et le meilleur objet du jeu valait parfois
## moins que le premier ramassé. Le plancher monte maintenant avec le plafond —
## un objet de haut niveau ne peut plus tirer le fond de l'échelle.
##
## Quatre, donc un objet qui atteint le T1 ne tire plus rien en dessous du T4. Ce
## n'est pas une garantie pour autant : quatre paliers d'écart, c'est encore un
## objet sur quatre qui déçoit, et c'est ce qu'il faut pour qu'une bonne sortie
## reste une bonne nouvelle.
const PALIERS_OUVERTS := 4


## Les indices des paliers qu'un objet de ce niveau peut recevoir : le meilleur
## qu'il atteint, et les PALIERS_OUVERTS - 1 suivants.
##
## Le parcours va du meilleur au pire — c'est l'ordre de `tiers` — donc les
## premiers indices retenus sont bien les meilleurs paliers atteints. Un `.tres`
## dont l'échelle serait écrite à l'envers ouvrirait le mauvais bout ; c'est la
## monotonie, vérifiée par le test, qui l'interdit.
func ouverts(niveau: int) -> Array:
	var out := []
	for i in tiers.size():
		if tiers[i].niveau_requis > niveau:
			continue
		out.append(i)
		if out.size() >= PALIERS_OUVERTS:
			break
	return out


## Les paliers qu'un objet peut recevoir quand son niveau tombe **quelque part**
## entre ces deux bornes : l'union des fenêtres de tous ces niveaux.
##
## C'est ce qu'une base donnée peut réellement sortir, une fois croisé avec sa
## fenêtre de chute. Une épée large ne tombe qu'entre les zones 16 et 40, donc
## aucune n'atteint jamais un palier qui demande le niveau 52 : l'annoncer
## reviendrait à décrire un objet qui ne peut pas exister.
##
## Vaut pour ce qui **tombe**. Un objet plus ancien qu'une règle, ou refondu un
## jour par un artisanat, peut porter autre chose ; c'est le tirage neuf que
## cette fonction décrit.
func ouverts_entre(premier: int, dernier: int) -> Array:
	var vus := {}
	for niveau in range(maxi(premier, 1), maxi(dernier, premier) + 1):
		for i in ouverts(niveau):
			vus[i] = true
	var out := vus.keys()
	# Du meilleur au pire, comme `tiers` : c'est l'ordre dans lequel la fiche les
	# lit, et celui du numéro de palier.
	out.sort()
	return out


## Entre quels niveaux d'objet ce palier peut sortir. **Un y de zéro veut dire
## « sans fin »** : les meilleurs paliers ne sont chassés par rien.
##
## Interrogée et non recalculée : la réponse vient de `ouverts`, qui est la
## règle. La fiche de la forge l'affiche, et elle ne peut donc pas annoncer un
## palier que le tirage refuserait — ce qui serait le pire défaut d'un outil de
## réglage.
func fenetre_du_palier(index: int) -> Vector2i:
	var premier := 0
	var dernier := 0
	for niveau in range(1, Game.NIVEAU_MAX + 1):
		if not ouverts(niveau).has(index):
			continue
		if premier == 0:
			premier = niveau
		dernier = niveau
	return Vector2i(premier, 0 if dernier >= Game.NIVEAU_MAX else dernier)


## Le niveau à partir duquel cet affixe existe. Rien à voir avec son meilleur
## palier : c'est le plus bas de l'échelle, et il doit valoir 1.
func niveau_minimum() -> int:
	var mini := 0
	for t in tiers:
		if mini == 0 or t.niveau_requis < mini:
			mini = t.niveau_requis
	return mini


## Un exemplaire de cet affixe pour un objet de ce niveau, ou null si aucun
## palier n'est ouvert. L'appelant qui reçoit null ne doit pas insister : il n'y
## a rien à tirer, et pas un tirage à recommencer.
func roll(rng: RandomNumberGenerator, niveau: int) -> RolledAffix:
	var index := _pick_tier(rng, niveau)
	if index < 0:
		return null
	var palier: ItemAffixTier = tiers[index]
	var mode := StatMod.Mode.PERCENT if percent else StatMod.Mode.FLAT
	var v := snappedf(rng.randf_range(palier.min_value, palier.max_value), arrondi)
	return RolledAffix.new(id, index + 1, StatMod.new(stat, mode, v))


## Tirage pondéré parmi les paliers ouverts. Rend -1 quand il n'y en a aucun,
## ce qui est un cas de jeu ordinaire : un affixe dont même le dernier palier
## demande plus que le niveau de l'objet n'est pas dans la réserve.
##
## `ouverts` n'est appelé qu'une fois. Il l'était deux fois — une pour la somme,
## une pour la descente — et les deux listes devaient rester dans le même ordre
## sans que rien ne l'impose.
func _pick_tier(rng: RandomNumberGenerator, niveau: int) -> int:
	var ouv := ouverts(niveau)
	var poids := []
	for i in ouv:
		poids.append(tiers[i].poids)
	var choisi := Tirage.pondere(rng, poids)
	return -1 if choisi < 0 else ouv[choisi]
