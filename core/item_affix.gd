class_name ItemAffix
extends Resource

## La *définition* d'un affixe : statistique et échelle de paliers ; le tirage donne
## un RolledAffix. Des fourchettes : c'est ce qui fait comparer deux épées « acérées ».

@export var id: String = ""

## Les étiquettes qu'une base doit porter, **une seule suffit** (voir `ItemBase.tags`).
## Vide = partout, sous réserve d'`exclut`.
@export var tags: PackedStringArray = PackedStringArray()

## Les étiquettes qui interdisent, et qui **l'emportent** : « partout sauf les armes »,
## dont une base ajoutée plus tard hérite sans qu'on y pense.
@export var exclut: PackedStringArray = PackedStringArray()

## Sans portée, un champ de CharacterStats (dans StatMod.LABELS) ; avec, un nombre de
## StatsDeCompetence.
@export var stat: String = "attack_damage"

## Le mot-clé visé, ou vide pour la fiche (voir `StatMod.portee`).
@export var portee: String = ""

## Pourcentage plutôt que valeur absolue.
@export var percent: bool = false

## Les paliers, **du meilleur au pire** : le premier est le T1, le numéro est une
## position.
@export var tiers: Array[ItemAffixTier] = []

## Le pas d'arrondi : 1 pour un entier, 0.01 pour une fraction. Un champ et non une
## déduction, pour que tous les paliers s'arrondissent pareil.
@export var arrondi: float = 1.0

## Poids dans la réserve.
@export var weight: int = 10


## `exclut` d'abord : il l'emporte sur `tags`.
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


## Combien de paliers restent ouverts : le meilleur atteint et les trois du dessous.
## **Une fenêtre et non un plafond** : un objet de niveau 60 ne sort plus le T8, et une
## bonne sortie reste une bonne nouvelle sans être garantie.
const PALIERS_OUVERTS := 4


## Les indices des paliers ouverts à ce niveau, du meilleur au pire.
func ouverts(niveau: int) -> Array:
	var out := []
	for i in tiers.size():
		if tiers[i].niveau_requis > niveau:
			continue
		out.append(i)
		if out.size() >= PALIERS_OUVERTS:
			break
	return out


## L'union des fenêtres entre deux niveaux : ce qu'une base peut réellement sortir sur
## sa fenêtre de chute. Vaut pour ce qui tombe.
func ouverts_entre(premier: int, dernier: int) -> Array:
	var vus := {}
	for niveau in range(maxi(premier, 1), maxi(dernier, premier) + 1):
		for i in ouverts(niveau):
			vus[i] = true
	var out := vus.keys()
	# Du meilleur au pire, comme `tiers` : l'ordre dans lequel la fiche les lit.
	out.sort()
	return out


## Entre quels niveaux ce palier sort, **dans la plage demandée** — (0, 0) sinon. La
## réponse vient de `ouverts` : la forge ne peut pas annoncer ce que le tirage refuse.
func fenetre_du_palier(index: int, premier: int, dernier: int) -> Vector2i:
	var debut := 0
	var fin := 0
	for niveau in range(maxi(premier, 1), maxi(dernier, premier) + 1):
		if not ouverts(niveau).has(index):
			continue
		if debut == 0:
			debut = niveau
		fin = niveau
	return Vector2i(debut, fin)


## Le niveau à partir duquel cet affixe existe. Rien à voir avec son meilleur
## palier : c'est le plus bas de l'échelle, et il doit valoir 1.
func niveau_minimum() -> int:
	var mini := 0
	for t in tiers:
		if mini == 0 or t.niveau_requis < mini:
			mini = t.niveau_requis
	return mini


## Un exemplaire pour un objet de ce niveau, ou null si aucun palier n'est ouvert.
func roll(rng: RandomNumberGenerator, niveau: int) -> RolledAffix:
	var index := _pick_tier(rng, niveau)
	if index < 0:
		return null
	var palier: ItemAffixTier = tiers[index]
	var v := snappedf(rng.randf_range(palier.min_value, palier.max_value), arrondi)
	# Un tirage de plus pour la borne haute d'une fourchette. Le compte dépend de
	# l'affixe, jamais de ce qui sort (invariant 3).
	var haut := v
	if est_une_fourchette():
		haut = snappedf(rng.randf_range(palier.min_haut, palier.max_haut), arrondi)
	return RolledAffix.new(id, index + 1, modificateur(v, haut))


## Deux nombres par palier ; déduit de la statistique, jamais saisi.
func est_une_fourchette() -> bool:
	return StatMod.stat_en_fourchette(stat)


## Le tirage et l'établi passent par ici : une portée oubliée d'un côté ferait une
## ligne de fiche qui vise un champ inconnu.
func modificateur(valeur: float, valeur_max := 0.0) -> StatMod:
	return StatMod.depuis_definition(stat, percent, valeur, valeur_max, portee)


## Le haut de chaque fourchette, arrondi comme le tirage : l'établi pose un réglage
## reproductible.
func au_sommet(index: int) -> StatMod:
	var palier: ItemAffixTier = tiers[index]
	return modificateur(snappedf(palier.max_value, arrondi), snappedf(palier.max_haut, arrondi))


## « 45–58 », « 8–11 % », « 3–4 à 7–9 » : forge, catalogue et infobulle passent ici.
func plage(index: int) -> String:
	var palier: ItemAffixTier = tiers[index]
	var mode := StatMod.Mode.PERCENT if percent else StatMod.Mode.FLAT
	var bas := StatMod.range_label(stat, mode, palier.min_value, palier.max_value)
	if not est_une_fourchette():
		return bas
	return "%s à %s" % [bas, StatMod.range_label(stat, mode, palier.min_haut, palier.max_haut)]


## Tirage pondéré parmi les paliers ouverts. `ouverts` n'est appelé qu'une fois :
## les poids et la descente doivent porter sur la même liste, dans le même ordre.
func _pick_tier(rng: RandomNumberGenerator, niveau: int) -> int:
	var ouv := ouverts(niveau)
	var poids := []
	for i in ouv:
		poids.append(tiers[i].poids)
	var choisi := Tirage.pondere(rng, poids)
	return -1 if choisi < 0 else ouv[choisi]
