class_name Character
extends RefCounted

## Un personnage tel qu'il survit à la fermeture : nom, silhouette, progression, sac,
## équipement, manuels — jamais la partie ; le Player est son corps en scène.
## En JSON et non en Resource : une Resource exécute du code au chargement, et une
## sauvegarde peut venir de quelqu'un d'autre.

## Le numéro de format **écrit** ; il monte avec chaque champ nouveau.
const VERSION := 8

## Les numéros qu'on sait **lire** (invariant 7) ; un numéro inconnu est refusé.
## v1 → objets de niveau 1 ; v2 → râtelier vide, barre de départ, manuel pas encore
## offert ; v3 → rien ; v1 à v4 → dégâts plats convertis par `_current_line` ; v1 à v5 →
## noms français, traduits par `LegacyFrench` ; v1 à v6 → attributs placés abandonnés,
## arbre de passifs vide ; v1 à v7 → Vive lame.
const READABLE_VERSIONS := [1, 2, 3, 4, 5, 6, 7, 8]

## Les dégâts plats d'avant le jalon 8, nommés ici pour être convertis.
const LEGACY_ATTACK_DAMAGE := "attack_damage"
const LEGACY_SPELL_DAMAGE := "spell_damage"

## Les classes jouables : l'archétype de la forge qui les dessine, et leur nom
## affiché (clé de traduction). Le gameplay est encore le même pour toutes.
const SWIFTBLADE := "swiftblade"
const WITCH := "witch"
const CLASSES := {
	SWIFTBLADE: {"archetype": "swiftblade", "name": "Vive lame"},
	WITCH: {"archetype": "witch", "name": "Sorcière"},
}
## Le nom qu'a porté la Vive lame dans les premières sauvegardes v8.
const LEGACY_CLASSES := {"warrior": SWIFTBLADE}

## Borné pour tenir sur une ligne de la sélection. Vingt et non seize : « Jean-Luc
## de l'Est » doit passer.
const NAME_MAX := 20

var id := ""
var name := ""
## Une clé de `CLASSES`.
var character_class := SWIFTBLADE
## L'index de variante de la forge, pas un chemin de sprite.
var silhouette := 0
var created_on := ""
var played_on := ""

var level := 1
var experience := 0

## Les nœuds pris de l'arbre de passifs. Les points restants se déduisent du niveau.
var passives := PackedStringArray()

var bag := Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)
## Les emplacements sont validés par le Player, pas ici.
var equipment := {}

## Écrits ici et nulle part ailleurs, sinon deux vérités sur leurs points.
var rack := Rack.new()

## Par défaut celle de départ, ce que devient aussi une sauvegarde v2.
var bar := SkillBar.starting()

## Sauvegardé et non déduit du sac : un joueur qui jette le sien n'en reçoit pas un
## second.
var manual_given := false

## Un fichier qu'on n'a pas su lire : montré grisé plutôt que disparu.
var unreadable := false


static func create_new(p_name: String, p_silhouette: int, p_class := SWIFTBLADE) -> Character:
	var p := Character.new()
	p.id = new_id()
	p.name = p_name.strip_edges()
	p.character_class = p_class
	p.silhouette = p_silhouette
	p.created_on = Time.get_date_string_from_system()
	p.played_on = p.created_on
	return p


static func unreadable_with(p_id: String) -> Character:
	var p := Character.new()
	p.id = p_id
	p.unreadable = true
	return p


## Généré, jamais dérivé du nom (homonymes, caractères interdits). Tiré sur le
## générateur global et non sur Game.rng (invariant 3).
## Le corps que la forge dessine pour cette classe.
func archetype() -> String:
	return CLASSES[character_class]["archetype"]


static func new_id() -> String:
	return "p_%d_%04d" % [int(Time.get_unix_time_from_system()), randi() % 10000]


## Sans caractères de contrôle, invisibles mais écrits dans le fichier.
static func valid_name(p_name: String) -> bool:
	var n := p_name.strip_edges()
	if n.is_empty() or n.length() > NAME_MAX:
		return false
	for i in n.length():
		var code := n.unicode_at(i)
		if code < 32 or code == 127:
			return false
	return true


## Aucune statistique calculée : elles se recalculent au chargement.
func to_dict() -> Dictionary:
	var placed_items := []
	for placed in bag.placed:
		var entry := _item_to_dict(placed.data)
		entry["cell"] = [placed.cell.x, placed.cell.y]
		placed_items.append(entry)

	var worn := {}
	for slot in equipment:
		var item: Item = equipment[slot]
		if item != null and item.base != null:
			worn[slot] = _item_to_dict(item)

	# Trois entrées même vides : le fichier se relit sans deviner laquelle manquait.
	var books := []
	for item in rack.manuals:
		books.append(_item_to_dict(item) if item != null and item.base != null else null)

	# Une case vide s'écrit null : « rien » y ressemble à rien.
	var cells := []
	for i in SkillBar.SLOT_COUNT:
		var id := bar.id_of(i)
		cells.append(null if id.is_empty() else id)

	return {
		"version": VERSION,
		"id": id,
		"name": name,
		"class": character_class,
		"silhouette": silhouette,
		"created_on": created_on,
		"played_on": played_on,
		"level": level,
		"experience": experience,
		"passives": Array(passives),
		"bag": placed_items,
		"equipment": worn,
		"rack": books,
		"bar": cells,
		"manual_given": manual_given,
	}


## **Le seul endroit** qui fait confiance à des données du dehors : tout est
## reconverti (le JSON n'a qu'un type de nombre). Null si inexploitable ; un champ
## absent reprend son défaut plutôt que de perdre le personnage.
static func from_dict(source: Dictionary) -> Character:
	var version := _int(source, "version", 0)
	if not READABLE_VERSIONS.has(version):
		push_warning("Sauvegarde de version %d, connues %s : refusée." % [version, READABLE_VERSIONS])
		return null
	if version <= 5:
		source = LegacyFrench.save(source)

	var p := Character.new()
	p.id = String(source.get("id", ""))
	if p.id.is_empty():
		push_warning("Sauvegarde sans identifiant : refusée.")
		return null

	p.name = String(source.get("name", ""))
	p.character_class = String(source.get("class", SWIFTBLADE))
	p.character_class = LEGACY_CLASSES.get(p.character_class, p.character_class)
	if not CLASSES.has(p.character_class):
		push_warning("Classe « %s » inconnue : refusée." % p.character_class)
		return null
	p.silhouette = _int(source, "silhouette", 0)
	p.created_on = String(source.get("created_on", ""))
	p.played_on = String(source.get("played_on", ""))
	p.level = maxi(_int(source, "level", 1), 1)
	p.experience = maxi(_int(source, "experience", 0), 0)

	# Les attributs placés d'avant la v7 sont abandonnés : trois points libres n'ont
	# pas d'équivalent juste en nœuds. Relu par les règles de prise, pas cru.
	var taken := PackedStringArray()
	for id in _list(source.get("passives")):
		if id is String:
			taken.append(id)
	p.passives = PassiveTree.shared().legal(taken, p.level)

	for entry in _list(source.get("bag")):
		var item := _item_from_dict(entry)
		if item == null:
			continue
		var cell := _cell(entry)
		# Sa place d'abord, n'importe laquelle ensuite : si la grille a rétréci
		# ou si deux objets se recouvrent, on les range plutôt que de les perdre.
		if not p.bag.place(item, cell) and not p.bag.add(item):
			push_warning("Objet « %s » abandonné : plus de place dans le sac." % item.display_name())

	var worn: Dictionary = source.get("equipment", {}) if source.get("equipment") is Dictionary else {}
	for slot in worn:
		var item := _item_from_dict(worn[slot])
		if item != null:
			p.equipment[String(slot)] = item

	var books := _list(source.get("rack"))
	for i in mini(books.size(), Rack.SLOT_COUNT):
		var item := _item_from_dict(books[i])
		if item == null:
			continue
		# Refusé — un fichier trafiqué, un objet qui n'est pas un manuel — il
		# retombe dans le sac plutôt que de disparaître.
		if p.rack.put(i, item) != null and not p.bag.add(item):
			push_warning("Manuel « %s » abandonné : le râtelier l'a refusé." % item.display_name())

	# Clé absente : la barre de départ (sauvegarde d'avant le jalon 6). Clé présente :
	# ce qu'elle dit, cases vides comprises.
	if source.has("bar"):
		p.bar = SkillBar.new()
		var cells := _list(source.get("bar"))
		for i in mini(cells.size(), SkillBar.SLOT_COUNT):
			var id := String(cells[i]) if cells[i] is String else ""
			# Une compétence retirée du projet laisse sa case vide. Le fichier
			# reste lisible : c'est une case de barre, pas un personnage.
			if not id.is_empty() and SkillCatalog.by_id(id) != null:
				p.bar.put(i, id)

	p.manual_given = source.get("manual_given", false) == true

	return p


## La base par identifiant et les affixes résolus, jamais la base elle-même : elle
## figerait l'équilibrage du jour.
static func _item_to_dict(item: Item) -> Dictionary:
	var affixes := []
	for r in item.explicits:
		var entry := {"stat": r.mod.stat, "mode": int(r.mod.mode), "value": r.mod.value}
		# Écrite, jamais déduite de l'affixe d'origine : un objet sans provenance perdrait
		# sa portée.
		if not r.mod.scope.is_empty():
			entry["scope"] = r.mod.scope
		if r.mod.is_a_range():
			entry["value_max"] = r.mod.value_max
		# La provenance seulement quand on l'a : pas de palier inventé.
		if r.known():
			entry["affix"] = r.affix_id
			entry["tier"] = r.tier
		affixes.append(entry)
	var entry := {
		"base": item.base.id, "level": item.item_level,
		"base_roll": item.implicit_roll, "affixes": affixes,
	}
	# Le niveau d'un manuel ne s'écrit pas : il se déduit de son expérience.
	if item.manual != null:
		entry["manual"] = {
			"exp": item.manual.experience,
			"points": item.manual.points.duplicate(),
		}
	return entry


## Null quand la base n'existe plus : l'objet est ignoré, le personnage se charge.
static func _item_from_dict(source: Variant) -> Item:
	if not source is Dictionary:
		return null
	var item_dict := source as Dictionary
	var identifier := String(item_dict.get("base", ""))
	var base := ItemCatalog.by_id(identifier)
	if base == null:
		push_warning("Base d'objet inconnue « %s » : objet ignoré." % identifier)
		return null

	var explicits: Array[RolledAffix] = []
	for raw in _list(item_dict.get("affixes")):
		if not raw is Dictionary:
			continue
		var line := raw as Dictionary
		var stat := String(line.get("stat", ""))
		if stat.is_empty():
			continue
		var written := _int(line, "mode", 0)
		var mode: StatMod.Mode = written if written in StatMod.Mode.values() else StatMod.Mode.FLAT
		# Portée absente : une ligne de fiche, ce que sont toutes celles d'avant la
		# version 4.
		var value := _float(line, "value", 0.0)
		var mod := StatMod.new(stat, mode, value, String(line.get("scope", "")))
		if mod.is_a_range():
			mod.value_max = maxf(_float(line, "value_max", value), value)

		var current := _current_line(mod, base)
		if current == null:
			push_warning(
				"« %s » : ligne « %s » abandonnée, plus rien ne l'applique." % [identifier, stat]
			)
			continue
		# La valeur fait foi : sans provenance, la ligne s'applique quand même. Une ligne
		# **convertie** perd la sienne.
		var was_converted := current != mod
		explicits.append(RolledAffix.new(
			"" if was_converted else String(line.get("affix", "")),
			0 if was_converted else maxi(_int(line, "tier", 0), 0),
			current
		))
	# Absent, il vaut 1 : tous les objets d'une sauvegarde v1.
	var level := _int(item_dict, "level", 1)
	var item := Item.new(base, explicits, level)
	# Absent, le bas de la plage : c'était la valeur fixe d'avant les plages.
	item.implicit_roll = _float(item_dict, "base_roll", 0.0)
	_manual_from_dict(item, item_dict.get("manual"))
	return item


## Une ligne d'avant les fourchettes (jalon 8) : elle-même, sa conversion, ou null
## quand plus rien ne l'applique. **Équivalence exacte** avec le jeu d'alors — la
## seule attaque était physique, tous les sorts de foudre ; seuls les pourcentages
## de `murderous` n'ont plus d'équivalent. Testée sur le nom, pas sur la version.
##
## Une chance critique plate hors d'une arme (jalon 18) : seule l'arme donne une base, et
## un plat n'a pas d'équivalent en accru.
static func _current_line(mod: StatMod, base: ItemBase) -> StatMod:
	if mod.stat == SkillStats.CRIT_CHANCE and mod.mode == StatMod.Mode.FLAT \
			and base.family != ItemBase.WEAPON_FAMILY:
		return null
	if not mod.scope.is_empty():
		return mod
	var nature: DamageType.Kind
	var family := ""
	match mod.stat:
		LEGACY_ATTACK_DAMAGE:
			nature = DamageType.Kind.PHYSICAL
			family = Keywords.ATTACK
		LEGACY_SPELL_DAMAGE:
			nature = DamageType.Kind.LIGHTNING
			family = Keywords.SPELL
		_:
			return mod
	if mod.mode != StatMod.Mode.FLAT:
		return null
	return StatMod.ranged(
		SkillStats.added_stat(nature), mod.value, mod.value, family
	)


## Remplit l'état du manuel que `Item.new()` a déjà créé vierge. On le remplit,
## on ne le remplace pas : c'est l'objet qui décide s'il en a un, d'après sa base.
static func _manual_from_dict(item: Item, source: Variant) -> void:
	if item.manual == null or not source is Dictionary:
		return
	var state := source as Dictionary
	item.manual.experience = maxi(_int(state, "exp", 0), 0)

	var points: Variant = state.get("points")
	if not points is Dictionary:
		return
	for id in points:
		# « Ce livre le connaît-il », pour les trois sortes : des points hors de
		# l'archétype ne se dépensent nulle part, et `teaches()` jetterait les arbres.
		if item.knows(String(id)):
			item.manual.points[String(id)] = maxi(int(points[id]), 0)


static func _cell(source: Variant) -> Vector2i:
	var raw := _list((source as Dictionary).get("cell") if source is Dictionary else null)
	if raw.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(raw[0]), int(raw[1]))


static func _list(value: Variant) -> Array:
	return value if value is Array else []


static func _int(source: Dictionary, key: String, default_value: int) -> int:
	var v: Variant = source.get(key, default_value)
	return int(v) if (v is float or v is int) else default_value


static func _float(source: Dictionary, key: String, default_value: float) -> float:
	var v: Variant = source.get(key, default_value)
	return float(v) if (v is float or v is int) else default_value
