class_name LootFilter
extends RefCounted

## Le filtre de butin, à la Last Epoch : une liste de règles, **la plus haute qui
## vise l'objet décide**, et un objet qu'aucune ne vise s'affiche tel quel. Masquer
## tout ce qui reste se fait donc par une règle sans condition, posée en bas.

enum Action { SHOW, HIDE, RECOLOR }

## **Identifiants définitifs** : ils partent dans `settings.json`.
const ACTION_IDS := ["show", "hide", "recolor"]
const ACTION_LABELS := ["Montrer", "Masquer", "Recolorer"]

## Les couleurs proposées à une règle qui recolore. Une palette plutôt qu'un
## sélecteur libre : un nom illisible sur le sol se choisit trop facilement.
## En hexadécimal, comme dans `settings.json` : une couleur à virgule relue du fichier
## n'égalerait plus sa case de la palette.
const COLORS := [
	Color("#ffffff"),
	Color("#f25959"),
	Color("#ff9933"),
	Color("#ffe64d"),
	Color("#73e666"),
	Color("#59d9f2"),
	Color("#8c8cff"),
	Color("#f273f2"),
]

## Les types d'objet qu'une condition peut viser, dans l'ordre de la page. Des
## familles et non des emplacements : un anneau se vise une fois, pas par doigt.
const FAMILIES := {
	"weapon": "Armes",
	"offhand": "Mains gauches",
	"helmet": "Casques",
	"chest": "Torses",
	"gloves": "Gants",
	"boots": "Bottes",
	"belt": "Ceintures",
	"amulet": "Amulettes",
	"ring": "Anneaux",
	"manual": "Manuels",
	"currency": "Monnaie",
}


## Une règle : ce qu'elle fait, et ses conditions, **toutes** requises. Une
## condition vide ne restreint rien.
class Rule:
	var action := Action.SHOW
	var color: Color = COLORS[0]
	## Des `Item.Rarity`.
	var rarities: Array[int] = []
	## Des clés de `FAMILIES`. Des tableaux et non des tableaux packés : la page les
	## modifie en place, et un tableau packé se copie à chaque passage.
	var families: Array[String] = []
	## Des identifiants d'`ItemAffix`, dont l'objet doit porter au moins `min_count`,
	## chacun à `best_tier` ou mieux — le palier 1 est le meilleur, 0 les prend tous.
	var affixes: Array[String] = []
	var min_count := 1
	var best_tier := 0

	func matches(item: Item) -> bool:
		if not rarities.is_empty() and not rarities.has(item.rarity()):
			return false
		if not families.is_empty() and not families.has(item.base.family):
			return false
		return affixes.is_empty() or _matching_affixes(item) >= min_count

	func _matching_affixes(item: Item) -> int:
		var found := 0
		for rolled in item.explicits:
			if affixes.has(rolled.affix_id) and (best_tier == 0 or rolled.tier <= best_tier):
				found += 1
		return found

	func to_dict() -> Dictionary:
		var rarity_ids: Array[String] = []
		for rarity in rarities:
			rarity_ids.append(LootFilter.rarity_id(rarity))
		return {
			"action": ACTION_IDS[action],
			"color": color.to_html(false),
			"rarities": rarity_ids,
			"families": families,
			"affixes": affixes,
			"min_count": min_count,
			"best_tier": best_tier,
		}

	## Ce qu'un fichier retouché à la main contient de faux retombe sur le défaut.
	static func from_dict(source: Dictionary) -> Rule:
		var rule := Rule.new()
		rule.action = maxi(ACTION_IDS.find(String(source.get("action", ""))), 0) as Action
		var written := String(source.get("color", ""))
		if Color.html_is_valid(written):
			rule.color = Color.html(written)
		for id in LootFilter.strings(source.get("rarities")):
			var rarity := LootFilter.rarity_of(id)
			if rarity >= 0:
				rule.rarities.append(rarity)
		for id in LootFilter.strings(source.get("families")):
			if FAMILIES.has(id):
				rule.families.append(id)
		rule.affixes = LootFilter.strings(source.get("affixes"))
		rule.min_count = maxi(int(LootFilter.number(source.get("min_count"), 1)), 1)
		rule.best_tier = maxi(int(LootFilter.number(source.get("best_tier"), 0)), 0)
		return rule


var rules: Array[Rule] = []


## La règle qui décide pour cet objet, ou null.
func rule_for(item: Item) -> Rule:
	for rule in rules:
		if rule.matches(item):
			return rule
	return null


## Les affixes qu'un objet de ces types peut porter — tous sans type choisi. Par
## `ItemAffixPool.compatibles()`, que le tirage suit : la page ne propose rien qui ne
## tombe jamais.
static func possible_affixes(families: Array[String]) -> Array:
	if families.is_empty():
		return ItemAffixPool.ALL
	var out := []
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		if not families.has(base.family):
			continue
		for affix: ItemAffix in ItemAffixPool.compatibles(base):
			if not out.has(affix):
				out.append(affix)
	return out


## Monte (`step` = −1) ou descend une règle ; rien au bord de la liste.
func move(index: int, step: int) -> void:
	var target := index + step
	if index < 0 or index >= rules.size() or target < 0 or target >= rules.size():
		return
	var rule := rules[index]
	rules[index] = rules[target]
	rules[target] = rule


func to_list() -> Array:
	return rules.map(func(rule: Rule) -> Dictionary: return rule.to_dict())


static func from_list(source: Variant) -> LootFilter:
	var out := LootFilter.new()
	if source is Array:
		for one: Variant in source:
			if one is Dictionary:
				out.rules.append(Rule.from_dict(one))
	return out


## « magic » : le nom de la rareté et non son rang, qu'un palier inséré décalerait.
static func rarity_id(rarity: int) -> String:
	return String(Item.Rarity.keys()[rarity]).to_lower()


static func rarity_of(id: String) -> int:
	return Item.Rarity.keys().find(id.to_upper())


static func strings(source: Variant) -> Array[String]:
	var out: Array[String] = []
	if source is Array or source is PackedStringArray:
		for one: Variant in source:
			if one is String:
				out.append(one)
	return out


static func number(source: Variant, fallback: float) -> float:
	return float(source) if source is float or source is int else fallback
