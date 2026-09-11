class_name ItemAffix
extends Resource

## La *définition* d'un affixe d'objet : quelle statistique, et son échelle de
## paliers. Le tirage, lui, donne un RolledAffix — un affixe sur le disque, mille
## exemplaires différents en jeu.
##
## Une échelle de fourchettes et non une valeur fixe : c'est elle qui fait qu'on
## regarde deux épées « acérées » avant de choisir, et c'est par elle que
## descendre plus bas rapporte mieux.

@export var id: String = ""

## Les étiquettes qu'une base doit porter pour recevoir cet affixe : **une seule
## suffit**. Une armure ne donne pas d'allonge, une épée ne donne pas de PV —
## sans ce filtre, tous les objets se valent et le type de base ne veut plus rien
## dire. Voir `ItemBase.tags`.
##
## Vide = partout, sous réserve d'`exclut`. Utile pour un affixe volontairement
## universel — les résistances — et ça évite d'énumérer trente bases.
@export var tags: PackedStringArray = PackedStringArray()

## Les étiquettes qui interdisent cet affixe, quoi qu'en dise `tags` : une seule
## suffit à refuser, et **elle l'emporte**.
##
## C'est elle qui écrit « partout sauf sur les armes » en une ligne au lieu de
## neuf, et surtout : une base ajoutée plus tard hérite du refus sans qu'on ait à
## y penser, là où une liste d'autorisations l'aurait oubliée en silence.
@export var exclut: PackedStringArray = PackedStringArray()

## Le champ touché. **Sans portée**, un champ de CharacterStats, qui doit être
## dans StatMod.LABELS ; **avec**, un nombre de StatsDeCompetence, qui doit être
## dans ses propres LABELS.
@export var stat: String = "attack_damage"

## Le mot-clé visé, ou vide pour la fiche du personnage. C'est ce qui fait de
## « +1 projectile » un affixe comme les autres — tiré, porté, sauvegardé de la
## même façon — qui n'agit pourtant que sur les compétences portant le mot-clé.
## Voir `StatMod.portee`.
@export var portee: String = ""

## Pourcentage plutôt que valeur absolue. Les deux existent pour la même
## statistique — « +6 dégâts » sur une arme de début vaut mieux que « +10 % »,
## l'inverse en fin de partie.
@export var percent: bool = false

## Les paliers, **du meilleur au pire** : le premier de la liste est le T1. Le
## numéro est donc une position et non un champ à saisir — deux paliers portant
## le même numéro seraient invérifiables autrement.
##
## Leur nombre dépend de l'affixe : neuf pour l'armure qui progresse par grands
## bonds, cinq pour la vitesse de déplacement qu'on veut garder serrée.
@export var tiers: Array[ItemAffixTier] = []

## Le pas d'arrondi de la valeur tirée : 1 pour un affixe entier, 0.01 pour une
## fraction. « +7 dégâts » se lit, « +7.3184 dégâts » non.
##
## Un champ et non une déduction depuis la borne haute : une même échelle peut
## passer sous 1 en bas et au-dessus en haut, et la règle déduite arrondirait les
## paliers d'un même affixe différemment.
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
## **Une fenêtre et non un plafond.** Le plancher monte avec le plafond : sans
## ça, un objet de niveau 60 pouvait sortir le T8, celui des premières zones, et
## le meilleur objet du jeu valait parfois moins que le premier ramassé.
##
## Quatre, donc un objet qui atteint le T1 ne tire plus rien en dessous du T4. Ce
## n'est pas une garantie pour autant : c'est encore un objet sur quatre qui
## déçoit, et c'est ce qu'il faut pour qu'une bonne sortie reste une bonne
## nouvelle.
const PALIERS_OUVERTS := 4


## Les indices des paliers qu'un objet de ce niveau peut recevoir.
##
## Le parcours va du meilleur au pire — c'est l'ordre de `tiers` — donc les
## premiers indices retenus sont bien les meilleurs paliers atteints. C'est la
## monotonie, vérifiée par le test, qui interdit une échelle écrite à l'envers.
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
## jour par un artisanat, peut porter autre chose.
func ouverts_entre(premier: int, dernier: int) -> Array:
	var vus := {}
	for niveau in range(maxi(premier, 1), maxi(dernier, premier) + 1):
		for i in ouverts(niveau):
			vus[i] = true
	var out := vus.keys()
	# Du meilleur au pire, comme `tiers` : l'ordre dans lequel la fiche les lit.
	out.sort()
	return out


## Entre quels niveaux d'objet ce palier peut sortir, **à l'intérieur de la plage
## demandée**. Rend (0, 0) quand il n'y sort jamais.
##
## La plage est un argument et non une constante parce que la question utile
## n'est jamais « sur toute l'échelle du jeu » mais « sur cette base-ci » : une
## épée cesse de tomber en zone 22, et lui annoncer un palier qui sort « de 19 à
## 51 » oblige à faire l'intersection de tête.
##
## Interrogée et non recalculée : la réponse vient de `ouverts`, qui est la
## règle. La fiche de la forge ne peut donc pas annoncer un palier que le tirage
## refuserait — ce qui serait le pire défaut d'un outil de réglage.
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


## Un exemplaire de cet affixe pour un objet de ce niveau, ou null si aucun
## palier n'est ouvert. L'appelant qui reçoit null ne doit pas insister : il n'y
## a rien à tirer, et pas un tirage à recommencer.
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


## Vrai pour un affixe qui ajoute une fourchette de dégâts : il tire deux nombres
## par palier au lieu d'un. Déduit de la statistique visée plutôt que saisi : un
## drapeau de plus pourrait contredire le nom de la statistique.
func est_une_fourchette() -> bool:
	return StatMod.stat_en_fourchette(stat)


## Le modificateur que donne cet affixe à cette valeur — et à cette borne haute,
## pour une fourchette. Le tirage et l'établi passent tous deux par ici : une
## portée oubliée d'un côté ferait d'un « +1 projectile » une ligne de fiche qui
## vise un champ inconnu.
func modificateur(valeur: float, valeur_max := 0.0) -> StatMod:
	return StatMod.depuis_definition(stat, percent, valeur, valeur_max, portee)


## Le modificateur au sommet de ce palier : le haut de chaque fourchette, arrondi
## comme le tirage l'arrondirait. C'est ce que pose l'établi — un réglage doit être
## reproductible, sinon deux essais du même palier ne se comparent pas.
func au_sommet(index: int) -> StatMod:
	var palier: ItemAffixTier = tiers[index]
	return modificateur(snappedf(palier.max_value, arrondi), snappedf(palier.max_haut, arrondi))


## Ce qu'un palier peut donner, tel qu'on l'écrit : « 45–58 », « 8–11 % », ou
## « 3–4 à 7–9 » pour une fourchette. La forge, le catalogue et l'infobulle y
## passent tous : trois formatages séparés finiraient par diverger d'un arrondi.
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
