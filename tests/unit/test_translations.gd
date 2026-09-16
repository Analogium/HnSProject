extends GutTest

## L'anglais du jeu : qu'il existe pour chaque texte affiché, qu'aucune traduction
## ne soit devenue orpheline, et que les gabarits gardent leurs valeurs.
##
## C'est la seule garde du choix du jalon 9 : **le texte français est la clé**.
## Retoucher un texte affiché change donc sa clé, l'anglais ne la trouve plus, et
## le mot reste en français sur un écran anglais — sans erreur, sans
## avertissement, sans rien à l'écran qui le signale.
##
## Les textes relevés dans les sources sont ceux qu'enveloppe `Texts.t()` : c'est
## à ça que sert un traducteur unique et nommé court. Ce que le code affiche sans
## passer par lui échappe à ces tests — c'est le filet des lettres accentuées qui
## le cherche.

const PO := "res://i18n/en.po"

## Les dossiers de scripts relus. Pas `res://art` ni `res://tools` : la forge et
## le générateur de catalogue sont des outils de réglage, et restent en français.
const SOURCES := ["res://core", "res://ui", "res://actors", "res://fx", "res://world"]

## Les scènes que le joueur voit, dont Godot traduit seul les `Label` et les
## `Button`. Pas `zone.tscn` : ses deux textes de scène sont des amorces que le
## code réécrit à la première image.
const SCENES := ["res://ui/pause_menu.tscn", "res://ui/character_select.tscn"]

## Ce qui sépare un contexte de son texte dans une clé de ce test. Le même
## séparateur que gettext, et que Godot emploie en interne.
const CONTEXT := ""


## Le filet du §9 : un test qui laisse le jeu en anglais fait échouer les suivants
## loin de sa propre cause.
func after_each() -> void:
	if Settings.language != Settings.FRENCH:
		Settings.from_dict({"language": Settings.FRENCH})


# --------------------------------------------------------------------------
# La complétude
# --------------------------------------------------------------------------

## Chaque texte que le joueur peut lire a son anglais. Le message nomme ce qui
## manque **et d'où ça vient** : une base d'objet ajoutée sans sa traduction
## s'annonce par son identifiant, pas par une ligne de test.
func test_each_displayed_text_has_its_english() -> void:
	var english := _translations()
	var expected_all := _expected()
	var missing := PackedStringArray()
	for key in expected_all:
		if not english.has(key):
			missing.append("« %s » (%s)" % [key.replace(CONTEXT, " » dans « "), expected_all[key]])
	assert_eq(
		missing.size(), 0,
		"sans traduction anglaise :\n  %s" % "\n  ".join(missing)
	)


## Aucune traduction orpheline. Une entrée d'`en.po` que plus rien n'affiche est
## le signe qu'un texte français a changé : sa nouvelle version, elle, n'est
## traduite nulle part.
func test_no_orphan_translation() -> void:
	var expected_all := _expected()
	var orphans := PackedStringArray()
	for key in _translations():
		if not expected_all.has(key):
			orphans.append("« %s »" % key.replace(CONTEXT, " » dans « "))
	assert_eq(
		orphans.size(), 0,
		"plus rien ne les affiche :\n  %s" % "\n  ".join(orphans)
	)


## Les gabarits gardent leurs valeurs, ni plus ni moins. Un « {bas} » oublié dans
## la traduction donnerait « adds to 7 cold damage », et un `%d` de trop planterait
## le formatage — les deux en anglais seulement.
func test_templates_keep_their_values() -> void:
	var english := _translations()
	var faulty := PackedStringArray()
	for key in english:
		var expected_list := _template_values(key)
		var found_ones := _template_values(english[key])
		if expected_list != found_ones:
			faulty.append("« %s » : %s contre %s" % [key, expected_list, found_ones])
	assert_eq(faulty.size(), 0, "valeurs perdues en chemin :\n  %s" % "\n  ".join(faulty))


# --------------------------------------------------------------------------
# Ce que ça donne en anglais
# --------------------------------------------------------------------------

## La phrase entière, et pas des morceaux collés : l'ordre des mots n'est pas le
## même dans les deux langues, et « ajoute » + « à » + « dégâts de froid » donnerait
## un anglais dans l'ordre du français.
func test_an_item_line_reads_in_english() -> void:
	var line := ItemAffixPool.by_id("cold_to_spells").modifier(3.0, 7.0)
	assert_eq(line.label(), "ajoute 3 à 7 dégâts de froid aux sorts")

	Settings.from_dict({"language": Settings.ENGLISH})
	assert_eq(line.label(), "adds 3 to 7 cold damage to spells")


## Le contenu passe par ses accesseurs. Un `.tres` lu directement — `skill.name`
## plutôt que `displayed_name()` — donne un nom qui ne se traduira jamais.
func test_the_content_reads_in_english() -> void:
	var sword := ItemCatalog.by_id("sword")
	var manual := ItemCatalog.by_id("manual_lightning")
	var nova := SkillCatalog.by_id("lightning_nova")

	Settings.from_dict({"language": Settings.ENGLISH})
	assert_eq(Item.new(sword).display_name(), "Sword")
	assert_eq(Item.new(manual).display_name(), "Manual of Lightning")
	assert_eq(manual.manual.displayed_name(), "Master of Lightning")
	assert_eq(nova.displayed_name(), "Lightning Nova")
	assert_eq(nova.keywords_label(), "Projectile · Lightning · Spell")
	assert_eq(EquipmentSlots.label("offhand"), "OFF-HAND")
	assert_eq(DamageType.name(DamageType.Kind.NECROTIC), "necrotic")


## Un même mot français peut avoir deux sens, et deux traductions : « vitesse »
## nomme le déplacement sur la fiche de personnage et la vitesse d'un trait sur la
## fiche de compétence. C'est à ça que sert le contexte.
func test_a_context_separates_two_meanings_of_the_same_word() -> void:
	Settings.from_dict({"language": Settings.ENGLISH})
	assert_eq(StatMod.name("move_speed"), "movement speed")
	assert_eq(Texts.t("vitesse", "fiche de compétence"), "projectile speed")
	assert_eq(Texts.t("esquive", "coup évité"), "dodged", "et « esquive » de la fiche")
	assert_eq(StatMod.name("evasion"), "evasion")


## La typographie suit la langue : l'espace devant le signe pour cent est une
## règle française, et l'anglais colle le signe au nombre.
func test_the_percentage_follows_the_language_typography() -> void:
	assert_eq(StatMod.percentage(20), "20 %")
	assert_eq(StatMod.percentage(20, true), "+20 %")
	assert_eq(
		StatMod.range_label("res_cold", StatMod.Mode.FLAT, 8.0, 11.0), "8–11 %",
		"et une plage ne répète pas l'unité"
	)

	Settings.from_dict({"language": Settings.ENGLISH})
	assert_eq(StatMod.percentage(20), "20%")
	assert_eq(StatMod.percentage(20, true), "+20%")
	assert_eq(StatMod.range_label("res_cold", StatMod.Mode.FLAT, 8.0, 11.0), "8–11%")


## Les explications de la fiche gardent leurs nombres, qui viennent des règles :
## ils sont posés à la lecture, et pas figés dans la clé de traduction.
func test_an_explanation_keeps_its_numbers_in_english() -> void:
	var sheet := CharacterStats.new()
	Settings.from_dict({"language": Settings.ENGLISH})
	var text_value := StatHelp.lines("strength", sheet)[0]
	assert_string_contains(text_value, "Strength")
	assert_string_contains(
		text_value, "%.0f" % CharacterStats.HEALTH_PER_STRENGTH,
		"le nombre de la règle, pas celui d'un texte recopié"
	)
	assert_false(text_value.contains("{"), "et aucune valeur laissée en place")


# --------------------------------------------------------------------------
# Les outils
# --------------------------------------------------------------------------

## Les paires du fichier anglais, clé française → texte anglais. Un lecteur
## minimal : le fichier est écrit à la main, une entrée par ligne. Les pluriels
## entrent comme deux paires — le singulier et le pluriel sont deux clés que le
## code peut demander.
func _translations() -> Dictionary:
	var out := {}
	var context := ""
	var singular := ""
	var plural := ""
	for raw in FileAccess.get_file_as_string(PO).split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("msgctxt "):
			context = _literal(line.trim_prefix("msgctxt "))
		elif line.begins_with("msgid_plural "):
			plural = _literal(line.trim_prefix("msgid_plural "))
		elif line.begins_with("msgid "):
			singular = _literal(line.trim_prefix("msgid "))
			plural = ""
		elif line.begins_with("msgstr[0] "):
			out[_key(context, singular)] = _literal(line.trim_prefix("msgstr[0] "))
		elif line.begins_with("msgstr[1] "):
			out[_key(context, plural)] = _literal(line.trim_prefix("msgstr[1] "))
			context = ""
		elif line.begins_with("msgstr "):
			if not singular.is_empty():
				out[_key(context, singular)] = _literal(line.trim_prefix("msgstr "))
			context = ""
	return out


## La clé d'un texte : lui-même, ou son contexte devant lui.
func _key(context: String, text_value: String) -> String:
	return text_value if context.is_empty() else "%s%s%s" % [context, CONTEXT, text_value]


func _literal(raw: String) -> String:
	return raw.strip_edges().trim_prefix("\"").trim_suffix("\"").c_unescape()


## Tout ce que le joueur doit pouvoir lire en anglais : le contenu des `.tres`,
## les tables de libellés, les textes des scènes, et chaque texte enveloppé dans
## `Texts.t()`. La valeur dit d'où vient le texte, pour que l'échec nomme le
## fichier à corriger.
func _expected() -> Dictionary:
	var out := {}
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		out[base.display_name] = "base « %s »" % base.id
		if base.manual == null:
			continue
		out[base.manual.name] = "manuel « %s »" % base.manual.id
		# Ce qu'un manuel contient en plus de ses compétences, qui sont dans le
		# catalogue : les passifs et les nœuds d'arbre ne sont listés nulle part
		# ailleurs, et c'est ici qu'un nœud ajouté sans son anglais s'annonce.
		for passive in base.manual.passives():
			out[passive.name] = "passif « %s »" % passive.id
		for cell: ManualCell in base.manual.cells:
			for node: TalentNode in cell.talents:
				out[node.name] = "nœud « %s »" % node.id
	for node in PassiveTree.shared().nodes:
		if not node.name.is_empty():
			out[node.name] = "nœud de l'arbre de passifs « %s »" % node.id
	for raw in SkillCatalog.ALL:
		var skill: Skill = raw
		out[skill.name] = "compétence « %s »" % skill.id
	for raw in AffixPool.ALL:
		var affix: Affix = raw
		out[affix.display_name] = "affixe d'élite « %s »" % affix.id

	for nature in DamageType.NAMES:
		out[nature] = "nature de dégâts"
	for label_of in DamageType.DAMAGE_LABELS:
		out[label_of] = "dégâts d'une nature"
	for name in StatusEffects.NAMES:
		out[name] = "nom d'un état"
	for label_of in StatusEffects.AGAINST:
		out[label_of] = "dégâts contre un état"
	for id in Glossary.TERMS:
		for form in Glossary.TERMS[id]["forms"]:
			out[form] = "forme du terme « %s »" % id
	for entry in Glossary.ENTRIES:
		out[Glossary.ENTRIES[entry]["title"]] = "titre de l'encadré « %s »" % entry
		out[Glossary.ENTRIES[entry]["text"]] = "définition de « %s »" % entry
	for id in Keywords.LABELS:
		out[Keywords.LABELS[id]] = "mot-clé"
	for id in Keywords.RECIPIENTS:
		out[Keywords.RECIPIENTS[id]] = "destinataire d'une ligne"
	for id in EquipmentSlots.SLOTS:
		out[EquipmentSlots.SLOTS[id]["label"]] = "emplacement d'équipement"
	for field in StatMod.LABELS:
		out[StatMod.LABELS[field]] = "nom de statistique"
	for field in SkillStats.LABELS:
		out[SkillStats.LABELS[field]] = "nombre de compétence"
	for field in StatHelp.TEXTS:
		out[StatHelp.TEXTS[field]] = "explication de « %s »" % field
	for field in StatHelp.SKILLS:
		out[StatHelp.SKILLS[field]] = "explication de « %s »" % field

	# Les titres de groupes de la fiche et le mot de la suppression : traduits par
	# une variable, donc invisibles au relevé des littéraux.
	for group in StatsPanel.GROUPS:
		out[group[0]] = "titre de groupe de la fiche"
	out[CharacterSelect.UNNAMED_WORD] = "mot à taper pour supprimer"

	for path in SCENES:
		for text_value in _scene_texts(path):
			out[text_value] = path
	for path in _scripts():
		for key in _script_texts(path):
			out[key] = path
	return out


## Les scripts des dossiers du jeu, sous-dossiers compris.
func _scripts() -> PackedStringArray:
	var out := PackedStringArray()
	var remaining_all := SOURCES.duplicate()
	while not remaining_all.is_empty():
		var folder: String = remaining_all.pop_back()
		var access := DirAccess.open(folder)
		if access == null:
			continue
		for under in access.get_directories():
			remaining_all.append("%s/%s" % [folder, under])
		for file in access.get_files():
			if file.ends_with(".gd"):
				out.append("%s/%s" % [folder, file])
	return out


## Les textes qu'un script confie à `Texts` : `t("…")` et son contexte
## facultatif, `tn("…", "…", n)` et ses deux formes.
func _script_texts(path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var source := FileAccess.get_file_as_string(path)

	var simple := RegEx.create_from_string('Texts\\.t\\(\\s*"([^"]*)"(?:\\s*,\\s*"([^"]*)")?')
	for found in simple.search_all(source):
		out.append(_key(found.get_string(2), found.get_string(1)))

	var plural := RegEx.create_from_string('Texts\\.tn\\(\\s*"([^"]*)"\\s*,\\s*"([^"]*)"')
	for found in plural.search_all(source):
		out.append(found.get_string(1))
		out.append(found.get_string(2))
	return out


## Les textes d'une scène : ceux que Godot traduit tout seul sur un `Label`, un
## `Button` ou le fantôme d'un champ de saisie.
func _scene_texts(path: String) -> PackedStringArray:
	var out := PackedStringArray()
	for raw in FileAccess.get_file_as_string(path).split("\n"):
		var line := raw.strip_edges()
		for prefix in ["text = ", "placeholder_text = "]:
			if not line.begins_with(prefix):
				continue
			var text_value := _literal(line.trim_prefix(prefix))
			if not text_value.is_empty():
				out.append(text_value)
	return out


## Les valeurs qu'un gabarit attend : celles qui sont nommées — `{low}` — et les
## conversions de `%`. Triées, pour que l'ordre des mots ne compte pas : c'est
## justement ce qu'une traduction a le droit de changer.
func _template_values(text_value: String) -> Array:
	var out := []
	for motif in ['\\{[a-z_]+\\}', '%[-+0-9.]*[dfsx]']:
		for found in RegEx.create_from_string(motif).search_all(text_value):
			out.append(found.get_string())
	out.sort()
	return out
