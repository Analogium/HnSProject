extends GutTest

## L'anglais du jeu : qu'il existe pour chaque texte affiché, qu'aucune traduction
## ne soit devenue orpheline, et que les gabarits gardent leurs valeurs.
##
## C'est la seule garde du choix du jalon 9 : **le texte français est la clé**.
## Retoucher un texte affiché change donc sa clé, l'anglais ne la trouve plus, et
## le mot reste en français sur un écran anglais — sans erreur, sans
## avertissement, sans rien à l'écran qui le signale.
##
## Les textes relevés dans les sources sont ceux qu'enveloppe `Textes.t()` : c'est
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
const SCENES := ["res://ui/pause_menu.tscn", "res://ui/selection_personnage.tscn"]

## Ce qui sépare un contexte de son texte dans une clé de ce test. Le même
## séparateur que gettext, et que Godot emploie en interne.
const CONTEXTE := ""


## Le filet du §9 : un test qui laisse le jeu en anglais fait échouer les suivants
## loin de sa propre cause.
func after_each() -> void:
	if Settings.langue != Settings.FRANCAIS:
		Settings.depuis_dict({"langue": Settings.FRANCAIS})


# --------------------------------------------------------------------------
# La complétude
# --------------------------------------------------------------------------

## Chaque texte que le joueur peut lire a son anglais. Le message nomme ce qui
## manque **et d'où ça vient** : une base d'objet ajoutée sans sa traduction
## s'annonce par son identifiant, pas par une ligne de test.
func test_chaque_texte_affiche_a_son_anglais() -> void:
	var anglais := _traductions()
	var attendus := _attendus()
	var manquants := PackedStringArray()
	for cle in attendus:
		if not anglais.has(cle):
			manquants.append("« %s » (%s)" % [cle.replace(CONTEXTE, " » dans « "), attendus[cle]])
	assert_eq(
		manquants.size(), 0,
		"sans traduction anglaise :\n  %s" % "\n  ".join(manquants)
	)


## Aucune traduction orpheline. Une entrée d'`en.po` que plus rien n'affiche est
## le signe qu'un texte français a changé : sa nouvelle version, elle, n'est
## traduite nulle part.
func test_aucune_traduction_orpheline() -> void:
	var attendus := _attendus()
	var orphelines := PackedStringArray()
	for cle in _traductions():
		if not attendus.has(cle):
			orphelines.append("« %s »" % cle.replace(CONTEXTE, " » dans « "))
	assert_eq(
		orphelines.size(), 0,
		"plus rien ne les affiche :\n  %s" % "\n  ".join(orphelines)
	)


## Les gabarits gardent leurs valeurs, ni plus ni moins. Un « {bas} » oublié dans
## la traduction donnerait « adds to 7 cold damage », et un `%d` de trop planterait
## le formatage — les deux en anglais seulement.
func test_les_gabarits_gardent_leurs_valeurs() -> void:
	var anglais := _traductions()
	var fautifs := PackedStringArray()
	for cle in anglais:
		var attendues := _valeurs_du_gabarit(cle)
		var trouvees := _valeurs_du_gabarit(anglais[cle])
		if attendues != trouvees:
			fautifs.append("« %s » : %s contre %s" % [cle, attendues, trouvees])
	assert_eq(fautifs.size(), 0, "valeurs perdues en chemin :\n  %s" % "\n  ".join(fautifs))


# --------------------------------------------------------------------------
# Ce que ça donne en anglais
# --------------------------------------------------------------------------

## La phrase entière, et pas des morceaux collés : l'ordre des mots n'est pas le
## même dans les deux langues, et « ajoute » + « à » + « dégâts de froid » donnerait
## un anglais dans l'ordre du français.
func test_une_ligne_d_objet_se_lit_en_anglais() -> void:
	var ligne := ItemAffixPool.by_id("froid_aux_sorts").modificateur(3.0, 7.0)
	assert_eq(ligne.label(), "ajoute 3 à 7 dégâts de froid aux sorts")

	Settings.depuis_dict({"langue": Settings.ANGLAIS})
	assert_eq(ligne.label(), "adds 3 to 7 cold damage to spells")


## Le contenu passe par ses accesseurs. Un `.tres` lu directement — `competence.nom`
## plutôt que `nom_affiche()` — donne un nom qui ne se traduira jamais.
func test_le_contenu_se_lit_en_anglais() -> void:
	var epee := ItemCatalog.by_id("epee")
	var manuel := ItemCatalog.by_id("manuel_foudre")
	var salve := CompetenceCatalog.by_id("salve_d_eclairs")

	Settings.depuis_dict({"langue": Settings.ANGLAIS})
	assert_eq(Item.new(epee).display_name(), "Sword")
	assert_eq(Item.new(manuel).display_name(), "Manual of Lightning")
	assert_eq(manuel.manuel.nom_affiche(), "Master of Lightning")
	assert_eq(salve.nom_affiche(), "Bolt Volley")
	assert_eq(salve.libelle_des_mots_cles(), "Projectile · Lightning · Spell")
	assert_eq(EquipmentSlots.label("offhand"), "OFF-HAND")
	assert_eq(DamageType.nom(DamageType.Kind.NECROTIC), "necrotic")


## Un même mot français peut avoir deux sens, et deux traductions : « vitesse »
## nomme le déplacement sur la fiche de personnage et la vitesse d'un trait sur la
## fiche de compétence. C'est à ça que sert le contexte.
func test_un_contexte_separe_deux_sens_du_meme_mot() -> void:
	Settings.depuis_dict({"langue": Settings.ANGLAIS})
	assert_eq(StatMod.nom("move_speed"), "movement speed")
	assert_eq(Textes.t("vitesse", "fiche de compétence"), "projectile speed")
	assert_eq(Textes.t("esquive", "coup évité"), "dodged", "et « esquive » de la fiche")
	assert_eq(StatMod.nom("evasion"), "evasion")


## La typographie suit la langue : l'espace devant le signe pour cent est une
## règle française, et l'anglais colle le signe au nombre.
func test_le_pourcentage_suit_la_typographie_de_la_langue() -> void:
	assert_eq(StatMod.pourcentage(20), "20 %")
	assert_eq(StatMod.pourcentage(20, true), "+20 %")
	assert_eq(
		StatMod.range_label("res_cold", StatMod.Mode.FLAT, 8.0, 11.0), "8–11 %",
		"et une plage ne répète pas l'unité"
	)

	Settings.depuis_dict({"langue": Settings.ANGLAIS})
	assert_eq(StatMod.pourcentage(20), "20%")
	assert_eq(StatMod.pourcentage(20, true), "+20%")
	assert_eq(StatMod.range_label("res_cold", StatMod.Mode.FLAT, 8.0, 11.0), "8–11%")


## Les explications de la fiche gardent leurs nombres, qui viennent des règles :
## ils sont posés à la lecture, et pas figés dans la clé de traduction.
func test_une_explication_garde_ses_nombres_en_anglais() -> void:
	var fiche := CharacterStats.new()
	Settings.depuis_dict({"langue": Settings.ANGLAIS})
	var texte := StatHelp.lines("strength", fiche)[0]
	assert_string_contains(texte, "Strength")
	assert_string_contains(
		texte, "%.0f" % CharacterStats.HEALTH_PER_STRENGTH,
		"le nombre de la règle, pas celui d'un texte recopié"
	)
	assert_false(texte.contains("{"), "et aucune valeur laissée en place")


# --------------------------------------------------------------------------
# Les outils
# --------------------------------------------------------------------------

## Les paires du fichier anglais, clé française → texte anglais. Un lecteur
## minimal : le fichier est écrit à la main, une entrée par ligne. Les pluriels
## entrent comme deux paires — le singulier et le pluriel sont deux clés que le
## code peut demander.
func _traductions() -> Dictionary:
	var out := {}
	var contexte := ""
	var singulier := ""
	var pluriel := ""
	for brut in FileAccess.get_file_as_string(PO).split("\n"):
		var ligne := brut.strip_edges()
		if ligne.begins_with("msgctxt "):
			contexte = _litteral(ligne.trim_prefix("msgctxt "))
		elif ligne.begins_with("msgid_plural "):
			pluriel = _litteral(ligne.trim_prefix("msgid_plural "))
		elif ligne.begins_with("msgid "):
			singulier = _litteral(ligne.trim_prefix("msgid "))
			pluriel = ""
		elif ligne.begins_with("msgstr[0] "):
			out[_cle(contexte, singulier)] = _litteral(ligne.trim_prefix("msgstr[0] "))
		elif ligne.begins_with("msgstr[1] "):
			out[_cle(contexte, pluriel)] = _litteral(ligne.trim_prefix("msgstr[1] "))
			contexte = ""
		elif ligne.begins_with("msgstr "):
			if not singulier.is_empty():
				out[_cle(contexte, singulier)] = _litteral(ligne.trim_prefix("msgstr "))
			contexte = ""
	return out


## La clé d'un texte : lui-même, ou son contexte devant lui.
func _cle(contexte: String, texte: String) -> String:
	return texte if contexte.is_empty() else "%s%s%s" % [contexte, CONTEXTE, texte]


func _litteral(brut: String) -> String:
	return brut.strip_edges().trim_prefix("\"").trim_suffix("\"").c_unescape()


## Tout ce que le joueur doit pouvoir lire en anglais : le contenu des `.tres`,
## les tables de libellés, les textes des scènes, et chaque texte enveloppé dans
## `Textes.t()`. La valeur dit d'où vient le texte, pour que l'échec nomme le
## fichier à corriger.
func _attendus() -> Dictionary:
	var out := {}
	for brut in ItemCatalog.ALL:
		var base: ItemBase = brut
		out[base.display_name] = "base « %s »" % base.id
		if base.manuel == null:
			continue
		out[base.manuel.nom] = "manuel « %s »" % base.manuel.id
		# Ce qu'un manuel contient en plus de ses compétences, qui sont dans le
		# catalogue : les passifs et les nœuds d'arbre ne sont listés nulle part
		# ailleurs, et c'est ici qu'un nœud ajouté sans son anglais s'annonce.
		for passif in base.manuel.passifs():
			out[passif.nom] = "passif « %s »" % passif.id
		for case: CaseDeManuel in base.manuel.cases:
			for noeud: NoeudDeTalent in case.talents:
				out[noeud.nom] = "nœud « %s »" % noeud.id
	for brut in CompetenceCatalog.ALL:
		var competence: Competence = brut
		out[competence.nom] = "compétence « %s »" % competence.id
	for brut in AffixPool.ALL:
		var affixe: Affix = brut
		out[affixe.display_name] = "affixe d'élite « %s »" % affixe.id

	for nature in DamageType.NAMES:
		out[nature] = "nature de dégâts"
	for libelle in DamageType.LIBELLES_DE_DEGATS:
		out[libelle] = "dégâts d'une nature"
	for id in MotsCles.LIBELLES:
		out[MotsCles.LIBELLES[id]] = "mot-clé"
	for id in MotsCles.DESTINATAIRES:
		out[MotsCles.DESTINATAIRES[id]] = "destinataire d'une ligne"
	for id in EquipmentSlots.SLOTS:
		out[EquipmentSlots.SLOTS[id]["label"]] = "emplacement d'équipement"
	for champ in StatMod.LABELS:
		out[StatMod.LABELS[champ]] = "nom de statistique"
	for champ in StatsDeCompetence.LABELS:
		out[StatsDeCompetence.LABELS[champ]] = "nombre de compétence"
	for champ in StatHelp.TEXTS:
		out[StatHelp.TEXTS[champ]] = "explication de « %s »" % champ
	for champ in StatHelp.COMPETENCES:
		out[StatHelp.COMPETENCES[champ]] = "explication de « %s »" % champ

	# Les titres de groupes de la fiche et le mot de la suppression : traduits par
	# une variable, donc invisibles au relevé des littéraux.
	for groupe in StatsPanel.GROUPS:
		out[groupe[0]] = "titre de groupe de la fiche"
	out[SelectionPersonnage.MOT_SANS_NOM] = "mot à taper pour supprimer"

	for chemin in SCENES:
		for texte in _textes_de_la_scene(chemin):
			out[texte] = chemin
	for chemin in _scripts():
		for cle in _textes_du_script(chemin):
			out[cle] = chemin
	return out


## Les scripts des dossiers du jeu, sous-dossiers compris.
func _scripts() -> PackedStringArray:
	var out := PackedStringArray()
	var restants := SOURCES.duplicate()
	while not restants.is_empty():
		var dossier: String = restants.pop_back()
		var acces := DirAccess.open(dossier)
		if acces == null:
			continue
		for sous in acces.get_directories():
			restants.append("%s/%s" % [dossier, sous])
		for fichier in acces.get_files():
			if fichier.ends_with(".gd"):
				out.append("%s/%s" % [dossier, fichier])
	return out


## Les textes qu'un script confie à `Textes` : `t("…")` et son contexte
## facultatif, `tn("…", "…", n)` et ses deux formes.
func _textes_du_script(chemin: String) -> PackedStringArray:
	var out := PackedStringArray()
	var source := FileAccess.get_file_as_string(chemin)

	var simple := RegEx.create_from_string('Textes\\.t\\(\\s*"([^"]*)"(?:\\s*,\\s*"([^"]*)")?')
	for trouve in simple.search_all(source):
		out.append(_cle(trouve.get_string(2), trouve.get_string(1)))

	var pluriel := RegEx.create_from_string('Textes\\.tn\\(\\s*"([^"]*)"\\s*,\\s*"([^"]*)"')
	for trouve in pluriel.search_all(source):
		out.append(trouve.get_string(1))
		out.append(trouve.get_string(2))
	return out


## Les textes d'une scène : ceux que Godot traduit tout seul sur un `Label`, un
## `Button` ou le fantôme d'un champ de saisie.
func _textes_de_la_scene(chemin: String) -> PackedStringArray:
	var out := PackedStringArray()
	for brut in FileAccess.get_file_as_string(chemin).split("\n"):
		var ligne := brut.strip_edges()
		for prefixe in ["text = ", "placeholder_text = "]:
			if not ligne.begins_with(prefixe):
				continue
			var texte := _litteral(ligne.trim_prefix(prefixe))
			if not texte.is_empty():
				out.append(texte)
	return out


## Les valeurs qu'un gabarit attend : celles qui sont nommées — `{bas}` — et les
## conversions de `%`. Triées, pour que l'ordre des mots ne compte pas : c'est
## justement ce qu'une traduction a le droit de changer.
func _valeurs_du_gabarit(texte: String) -> Array:
	var out := []
	for motif in ['\\{[a-z_]+\\}', '%[-+0-9.]*[dfsx]']:
		for trouve in RegEx.create_from_string(motif).search_all(texte):
			out.append(trouve.get_string())
	out.sort()
	return out
