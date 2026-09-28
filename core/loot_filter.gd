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
	"flask": "Flacons",
	"manual": "Manuels",
	"currency": "Monnaie",
}


## Une règle : ce qu'elle fait, et ses conditions, **toutes** requises. Une
## condition vide ne restreint rien.
class Rule:
	## Éteinte, la règle reste à sa place et ne décide plus rien : on l'essaie sans
	## la perdre.
	var enabled := true
	var action := Action.SHOW
	var color: Color = COLORS[0]
	## Des `Item.Rarity`.
	var rarities: Array[int] = []
	## Des clés de `FAMILIES`. Des tableaux et non des tableaux packés : la page les
	## modifie en place, et un tableau packé se copie à chaque passage.
	var families: Array[String] = []
	## Des identifiants d'`ItemBase` : « l'Épée large », pas toutes les armes.
	var bases: Array[String] = []
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
		if not bases.is_empty() and not bases.has(item.base.id):
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
			"enabled": enabled,
			"action": ACTION_IDS[action],
			"color": color.to_html(false),
			"rarities": rarity_ids,
			"families": families,
			"bases": bases,
			"affixes": affixes,
			"min_count": min_count,
			"best_tier": best_tier,
		}

	## Ce qu'un fichier retouché à la main contient de faux retombe sur le défaut.
	static func from_dict(source: Dictionary) -> Rule:
		var rule := Rule.new()
		rule.enabled = bool(source.get("enabled", true))
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
		for id in LootFilter.strings(source.get("bases")):
			if ItemCatalog.by_id(id) != null:
				rule.bases.append(id)
		rule.affixes = LootFilter.strings(source.get("affixes"))
		rule.min_count = maxi(int(LootFilter.number(source.get("min_count"), 1)), 1)
		rule.best_tier = maxi(int(LootFilter.number(source.get("best_tier"), 0)), 0)
		return rule


## Le nom que le joueur lui donne : il en garde plusieurs, un seul décide au sol.
var name := ""
var rules: Array[Rule] = []


## La règle qui décide pour cet objet, ou null.
func rule_for(item: Item) -> Rule:
	for rule in rules:
		if rule.enabled and rule.matches(item):
			return rule
	return null


## Ce que devient un objet sous la règle qui décide de lui (null : aucune). Le sol et
## la page le lisent ici tous deux : l'aperçu ne doit pas mentir sur le jeu.
static func hides(rule: Rule) -> bool:
	return rule != null and rule.action == Action.HIDE


static func color_for(item: Item, rule: Rule) -> Color:
	return rule.color if rule != null and rule.action == Action.RECOLOR else item.color()


## Les bases que ces types regroupent — toutes sans type choisi —, par type puis par
## palier : l'ordre où la page les propose.
static func possible_bases(families: Array[String]) -> Array[ItemBase]:
	var out: Array[ItemBase] = []
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		if families.is_empty() or families.has(base.family):
			out.append(base)
	var order := FAMILIES.keys()
	out.sort_custom(func(a: ItemBase, b: ItemBase) -> bool:
		if a.family != b.family:
			return order.find(a.family) < order.find(b.family)
		return a.required_level < b.required_level
	)
	return out


## Les affixes que la règle peut encore viser : ceux de ses bases, sinon de ses types,
## sinon tous. Par `ItemAffixPool.compatibles()`, que le tirage suit : la page ne
## propose rien qui ne tombe jamais.
static func possible_affixes(rule: Rule) -> Array:
	if rule.bases.is_empty() and rule.families.is_empty():
		return ItemAffixPool.ALL
	var out := []
	for base in possible_bases(rule.families):
		if not rule.bases.is_empty() and not rule.bases.has(base.id):
			continue
		for affix: ItemAffix in ItemAffixPool.compatibles(base):
			if not out.has(affix):
				out.append(affix)
	return out


## Pose la règle `from` au rang `to`, les autres se décalant : le geste d'une carte
## glissée sur une autre.
func move_to(from: int, to: int) -> void:
	if from < 0 or from >= rules.size() or to < 0 or to >= rules.size():
		return
	var rule := rules[from]
	rules.remove_at(from)
	rules.insert(to, rule)


## Le code d'un filtre, à copier ou à écrire dans un fichier : le préfixe et sa
## version, puis le JSON en base64. **Sans compression** : un code tronqué au
## copier-coller échoue proprement à la lecture du JSON, là où un flux compressé
## coupé fait crier le décompresseur.
const CODE_PREFIX := "HNSF1:"
static var _base64 := RegEx.create_from_string("^[A-Za-z0-9+/]*={0,2}$")


func to_code() -> String:
	return CODE_PREFIX + Marshalls.utf8_to_base64(JSON.stringify(to_dict()))


## null si le texte n'est pas un code de filtre. Les blancs et retours à la ligne
## d'un copier-coller ne comptent pas ; ce qu'une règle a de faux retombe sur le
## défaut, comme à la lecture des réglages.
static func from_code(text_value: String) -> LootFilter:
	var code := "".join(text_value.split("\n")).replace("\r", "").replace(" ", "").strip_edges()
	if not code.begins_with(CODE_PREFIX):
		return null
	var body := code.trim_prefix(CODE_PREFIX)
	# Vérifié avant le décodage, qui journalise une erreur du moteur sur un texte faux.
	if body.is_empty() or body.length() % 4 != 0 or _base64.search(body) == null:
		return null
	var reader := JSON.new()
	if reader.parse(Marshalls.base64_to_utf8(body)) != OK:
		return null
	# Une liste nue : les premiers codes, d'avant les filtres nommés.
	if reader.data is Array:
		return from_list(reader.data)
	return from_dict(reader.data) if reader.data is Dictionary and reader.data.get("rules") is Array else null


func to_dict() -> Dictionary:
	return {"name": name, "rules": to_list()}


static func from_dict(source: Dictionary) -> LootFilter:
	var out := from_list(source.get("rules"))
	out.name = String(source.get("name", "")) if source.get("name") is String else ""
	return out


## Une copie qui ne partage aucune règle : modifier l'une ne touche pas l'autre.
func duplicated() -> LootFilter:
	return from_dict(to_dict())


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
