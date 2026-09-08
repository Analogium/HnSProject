class_name ForgeGallery
extends Control

## La planche-contact de la forge : un archétype par page, ses quatre variantes
## en lignes, ses neuf animations en colonnes, le tout en train de jouer.
##
## Et, depuis les planches d'objets, la **fiche d'une base** : cliquer dessus dit
## ce qu'elle est, entre quels niveaux de zone elle tombe, et tout ce qu'elle
## peut recevoir comme affixe — chaque palier avec le niveau d'objet qui l'ouvre
## et la plage dans laquelle il tire. C'est un outil de réglage : ces trois
## informations vivent dans trois fichiers différents, et les rapprocher à la
## main pour juger une base était le vrai coût de chaque retouche d'équilibrage.
##
## C'est l'outil qui rend la génération procédurale utilisable. Sans lui on
## règle une silhouette à l'aveugle, en relançant le jeu et en cherchant un
## ennemi du bon type ; ici les quatre variantes sont côte à côte et le moindre
## défaut de proportion saute aux yeux.
##
## [S] écrit toutes les planches en PNG. C'est la porte de sortie du procédural :
## un sprite exporté peut être retouché dans un éditeur d'image et rechargé comme
## un asset ordinaire — la forge ne t'enferme pas dans le code.

const CELL := 64          # 32 px de sprite, agrandis 2 fois
const SCALE := 2
const COLS := 9           # 3 animations x 3 directions
## Dans le projet et non dans user:// : un dossier enfoui sous AppData, on ne
## le retrouve jamais. En jeu exporté res:// n'est pas inscriptible, on
## retombe donc sur user://.
const EXPORT_DIR := "res://art/generated"
const EXPORT_FALLBACK := "user://forge_export"

const ANIMS := ["idle", "walk", "attack"]

## Les planches d'objets, après les archétypes. Elles existent pour la même
## raison qu'eux : quarante et une icônes se règlent côte à côte ou ne se règlent
## pas. Les bases y arrivent dans l'ordre du catalogue — par lignée, puis par
## palier — donc les trois âges d'un même objet sont voisins, et c'est exactement
## la comparaison qu'on vient faire.
##
## Agrandies deux fois, comme les archétypes : à leur taille native l'icône fait
## seize pixels sur la planche alors que le sac l'agrandit pour remplir sa case.
## Une planche qui montre plus petit que le jeu ne sert à rien.
const ITEM_COLS := 6
const ITEM_ROWS := 4
const ITEM_CELL := Vector2(104.0, 60.0)
const ITEM_SCALE := 2

## La fiche d'une base, quand on a cliqué dessus. Elle remplace la planche au
## lieu de se poser à côté : le pire cas mesuré — le pendentif — compte dix-sept
## affixes et soixante-huit lignes, et rien de tout ça ne tient dans la marge
## d'un cadrage de 640 × 360.
##
## Le pire cas n'est pas la base qui accepte le plus d'affixes mais celle dont la
## **fenêtre de chute est la plus large** : un pendentif tombe des zones 35 à la
## fin, donc il atteint quatre-vingt-treize paliers, là où l'anneau, cantonné aux
## zones 1 à 22, n'en atteint que quarante-quatre. C'est contre-intuitif, et
## c'est pour ça que la hauteur se mesure au lieu de se supposer.
##
## Trois colonnes et deux paliers par ligne : c'est le seul découpage où le pire
## cas tient d'une pièce, sans page à tourner au milieu d'une liste qu'on
## parcourt justement pour comparer. `test_la_fiche_d_objet_tient_dans_sa_hauteur`
## garde l'invariant — un affixe de plus le cassera en silence autrement.
const DETAIL_TOP := 82.0
const DETAIL_COLS := 3
const DETAIL_LINE := 9.0
const DETAIL_TIERS_PAR_LIGNE := 2
## Largeur d'une entrée de palier dans sa colonne. « T4  26→42  10–15 % » est le
## cas le plus large : deux niveaux, puis une plage en pourcentage à deux
## chiffres des deux côtés.
const DETAIL_TIER_W := 100.0
const DETAIL_MARGE := 10.0

const DETAIL_TITRE := Color(0.86, 0.84, 0.92)
const DETAIL_PALIER := Color(0.62, 0.68, 0.80)
const DETAIL_LEGENDE := Color(0.55, 0.53, 0.62)
const DETAIL_SIZE := 8

@onready var header: Label = $Header
@onready var footer: Label = $Footer
@onready var columns: Label = $Columns
@onready var stage: Node2D = $Stage

## La page courante : un archétype, ou la planche d'objets en dernier.
var _index := 0
var _status := ""
## L'index dans ItemCatalog.ALL de la base dont on regarde la fiche, -1 sur la
## planche. C'est le seul état qui distingue les deux écrans.
var _detail := -1


## Une ligne de la fiche : un ou deux textes, chacun à son décalage dans la
## colonne. Une petite classe et non un tableau indexé à la main — `ligne.textes`
## se relit là où `l[0]` oblige à se souvenir de ce qu'était la colonne zéro.
class Ligne:
	var textes := PackedStringArray()
	var decalages := PackedFloat32Array()
	var couleur: Color

	func _init(p_couleur: Color) -> void:
		couleur = p_couleur

	func ajouter(texte: String, x: float) -> void:
		textes.append(texte)
		decalages.append(x)


## Les archétypes, puis autant de planches d'objets qu'il en faut.
static func _item_pages() -> int:
	return ceili(float(ItemCatalog.ALL.size()) / float(ITEM_COLS * ITEM_ROWS))


static func _pages() -> int:
	return SpriteForge.ARCHETYPES.size() + _item_pages()


func _ready() -> void:
	# Posés ici et non dans la scène : le clic sur un objet doit arriver jusqu'à
	# _gui_input, et le fond comme les trois étiquettes le mangeraient avant —
	# ils couvrent toute la largeur. Un filtre par défaut est un détail qui
	# change d'une version du moteur à l'autre ; celui-ci est écrit.
	mouse_filter = Control.MOUSE_FILTER_STOP
	for enfant in get_children():
		if enfant is Control:
			(enfant as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


## Clic gauche : sur la planche d'objets il ouvre la fiche de l'objet visé, sur
## une fiche il la referme. Pas de bouton « retour » à viser — on ressort par où
## l'on est entré, et Échap fait la même chose.
func _gui_input(event: InputEvent) -> void:
	var clic := event as InputEventMouseButton
	if clic == null or not clic.pressed or clic.button_index != MOUSE_BUTTON_LEFT:
		return

	if _detail >= 0:
		_fermer_fiche()
	else:
		var vise := _item_at(clic.position)
		if vise < 0:
			return
		_detail = vise
		_build()
	accept_event()


## L'objet sous un point, ou -1. Hors d'une planche d'objets, il n'y a rien à
## viser : les archétypes ne sont pas des bases du catalogue.
func _item_at(point: Vector2) -> int:
	if _index < SpriteForge.ARCHETYPES.size():
		return -1
	var premier := (_index - SpriteForge.ARCHETYPES.size()) * ITEM_COLS * ITEM_ROWS
	for rang in ITEM_COLS * ITEM_ROWS:
		if premier + rang >= ItemCatalog.ALL.size():
			break
		if _item_rect(rang).has_point(point):
			return premier + rang
	return -1


## Referme la fiche **sur la page où se trouve l'objet regardé**, et non sur
## celle d'où l'on venait : les flèches font défiler le catalogue entier depuis
## la fiche, et retomber trois planches plus tôt donnerait l'impression d'avoir
## perdu sa place.
func _fermer_fiche() -> void:
	if _detail >= 0:
		_index = SpriteForge.ARCHETYPES.size() + _detail / (ITEM_COLS * ITEM_ROWS)
	_detail = -1
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# Retenu avant le match : un changement de scène détache ce nœud de l'arbre
	# et get_viewport() renverrait null.
	var vp := get_viewport()

	match (event as InputEventKey).keycode:
		# Sur une fiche, les flèches parcourent le catalogue entier plutôt que
		# les pages : les paliers d'une même lignée s'y suivent, donc comparer
		# une épée à l'épée large est une seule touche.
		KEY_RIGHT, KEY_SPACE:
			if _detail >= 0:
				_detail = (_detail + 1) % ItemCatalog.ALL.size()
			else:
				_index = (_index + 1) % _pages()
			_build()
		KEY_LEFT:
			if _detail >= 0:
				_detail = (_detail - 1 + ItemCatalog.ALL.size()) % ItemCatalog.ALL.size()
			else:
				_index = (_index - 1 + _pages()) % _pages()
			_build()
		KEY_S:
			_export()
		# La touche qui a ouvert la forge la referme, comme pour la carte de
		# réglage (F3) — et Échap referme n'importe quel aperçu. Une fiche
		# ouverte se referme d'abord : c'est la règle du menu de pause, où Échap
		# sort des options avant de sortir du menu.
		KEY_F4, KEY_ESCAPE:
			if _detail >= 0:
				_fermer_fiche()
			else:
				Game.go_back("res://world/zone.tscn")
		_:
			return

	vp.set_input_as_handled()


func _build() -> void:
	for child in stage.get_children():
		child.queue_free()

	if _detail >= 0:
		_build_detail()
		return

	if _index >= SpriteForge.ARCHETYPES.size():
		_build_items()
		return

	var archetype: String = SpriteForge.ARCHETYPES[_index]
	var x0 := (size.x - COLS * CELL) * 0.5
	var y0 := 62.0

	for variant in SpriteForge.VARIANTS:
		var frames := SpriteForge.frames(archetype, variant)
		var col := 0
		for anim in ANIMS:
			for dir in SpriteForge.DIRS:
				var s := AnimatedSprite2D.new()
				s.sprite_frames = frames
				s.scale = Vector2(SCALE, SCALE)
				s.position = Vector2(
					x0 + col * CELL + CELL * 0.5,
					y0 + variant * CELL + CELL * 0.5
				)
				s.play("%s_%s" % [anim, dir])
				# L'attaque ne boucle pas dans le jeu — sur la planche, si :
				# une pose figée ne dit rien du mouvement.
				s.animation_finished.connect(_replay.bind(s))
				stage.add_child(s)
				col += 1

	header.text = "FORGE  —  %s   (variante 0 a %d, de haut en bas)" % [
		archetype.to_upper(), SpriteForge.VARIANTS - 1
	]
	columns.text = "        repos  ^  |  marche  ^  |  attaque  ^"
	footer.text = "\n".join([
		"[<-] [->] page          [S] exporter les planches en PNG",
		"[F4] ou [ECHAP] retour",
		_status,
	])


## Une planche d'objets : les bases du catalogue sous leur nom et leur palier,
## dessinées comme le sac les dessine puis agrandies d'ITEM_SCALE.
##
## L'agrandissement est celui des planches d'archétypes, et il a remplacé la
## taille native de la première version : une icône de seize pixels sur un écran
## de réglage se juge moins bien que dans le sac, qui l'agrandit déjà pour
## remplir sa case. Une planche qui montre plus petit que le jeu ne sert à rien.
func _build_items() -> void:
	var page := _index - SpriteForge.ARCHETYPES.size()
	var par_page := ITEM_COLS * ITEM_ROWS
	var premier := page * par_page
	var dernier := mini(premier + par_page, ItemCatalog.ALL.size())

	for i in range(premier, dernier):
		var base: ItemBase = ItemCatalog.ALL[i]
		var rang := i - premier
		var centre := _item_centre(rang)

		var s := Sprite2D.new()
		s.texture = SpriteForge.inventory_icon(base.kind, Vector2i.ZERO, base.palier)
		s.scale = Vector2(ITEM_SCALE, ITEM_SCALE)
		s.position = centre
		stage.add_child(s)

		var l := Label.new()
		l.text = "%s %d" % [base.display_name, base.palier]
		l.add_theme_font_size_override("font_size", 8)
		l.add_theme_color_override("font_color", Color(0.70, 0.68, 0.76))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Largeur imposée **et** texte coupé : sans la largeur un nom long se
		# centre sur lui-même et déborde sur l'objet voisin, sans la coupe il
		# déborde quand même. « Marteau de guerre » et « Baguette » se
		# recouvraient exactement comme ça.
		l.size = Vector2(ITEM_CELL.x, 10.0)
		l.clip_text = true
		# Sans ça l'étiquette mange le clic sur l'objet qu'elle nomme : elle est
		# posée dans sa case, et c'est le bas de la case qu'on vise naturellement.
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.position = centre + Vector2(-ITEM_CELL.x * 0.5, ITEM_CELL.y * 0.5 - 14.0)
		stage.add_child(l)

	header.text = "FORGE  —  OBJETS  %d/%d   (%d bases, par lignee puis par palier)" % [
		page + 1, _item_pages(), ItemCatalog.ALL.size()
	]
	columns.text = "        palier 1 terne  |  2 acier  |  3 clair"
	footer.text = "\n".join([
		"[<-] [->] page          [clic sur un objet] sa fiche : chutes, affixes, paliers",
		"[F4] ou [ECHAP] retour",
		_status,
	])


## La fiche d'une base : son identité et sa fenêtre de chute en tête, puis tout
## ce qu'elle peut recevoir, palier par palier.
func _build_detail() -> void:
	var base: ItemBase = ItemCatalog.ALL[_detail]

	header.text = "FORGE  —  %s   (palier %d de la lignée « %s »)" % [
		base.display_name.to_upper(), base.palier, base.lignee
	]
	columns.text = _identite(base)

	var icone := Sprite2D.new()
	icone.texture = SpriteForge.inventory_icon(base.kind, Vector2i.ZERO, base.palier)
	icone.scale = Vector2(ITEM_SCALE, ITEM_SCALE)
	icone.position = Vector2(size.x - 40.0, 44.0)
	stage.add_child(icone)

	_etiquette(
		"chaque palier : T numéro  ·  niveaux d'objet où il peut sortir  ·  plage tirée",
		Vector2(DETAIL_MARGE, DETAIL_TOP - DETAIL_LINE - 3.0), DETAIL_LEGENDE
	)

	var lignes := lignes_affixes(base)
	# Au moins une ligne par colonne : une base sans aucun affixe compatible
	# donnerait sinon une division par zéro. Le cas n'existe pas dans le
	# catalogue d'aujourd'hui — il naîtrait d'une base à qui on oublierait ses
	# étiquettes, ce qui est précisément ce qu'on vient vérifier ici.
	var par_colonne := maxi(ceili(float(lignes.size()) / float(DETAIL_COLS)), 1)
	var largeur := (size.x - DETAIL_MARGE * 2.0) / float(DETAIL_COLS)

	for i in lignes.size():
		var ligne: Ligne = lignes[i]
		var x := DETAIL_MARGE + float(i / par_colonne) * largeur
		var y := DETAIL_TOP + float(i % par_colonne) * DETAIL_LINE
		for k in ligne.textes.size():
			_etiquette(ligne.textes[k], Vector2(x + ligne.decalages[k], y), ligne.couleur)

	footer.text = "\n".join([
		"[<-] [->] objet précédent / suivant       %d affixes possibles" % (
			ItemAffixPool.compatibles(base).size()
		),
		"[ECHAP] [F4] ou [clic] retour à la planche",
		_status,
	])


## L'en-tête d'une fiche : ce que la base **est**, et entre quels niveaux de zone
## elle tombe. Cette dernière est la seule information de l'écran qu'on ne peut
## lire nulle part ailleurs — ni dans le `.tres` de la base, ni dans le
## catalogue : elle naît de la rencontre entre le niveau requis et la règle des
## paliers visibles.
static func _identite(base: ItemBase) -> String:
	var morceaux := [", ".join(base.tags)]
	var implicite := base.implicit()
	if implicite != null:
		morceaux.append("implicite %s" % implicite.label())
	# « 1 × 1 case » et non « 1 × 1 cases » : l'anneau est le seul objet du
	# catalogue à n'en occuper qu'une, et c'est le premier qu'on regarde.
	var cases := base.grid_size.x * base.grid_size.y
	morceaux.append("%d × %d %s" % [
		base.grid_size.x, base.grid_size.y, "case" if cases <= 1 else "cases"
	])
	morceaux.append(_fenetre_texte(base))
	return "   ·   ".join(morceaux)


## Statique, et testée : c'est une phrase, donc rien de ce qui l'entoure ne
## signale qu'elle est fausse. Elle a annoncé « tombe dans les zones 35 à 0 »
## pendant tout le temps où le zéro de « sans fin » n'avait pas été reporté ici,
## et seule une capture l'a vu.
static func _fenetre_texte(base: ItemBase) -> String:
	var fenetre := ItemCatalog.fenetre_de_chute(base)
	if fenetre.y <= 0:
		return "tombe dans les zones %d et au-delà" % fenetre.x
	if fenetre.x > fenetre.y:
		return "NE TOMBE JAMAIS"
	return "tombe dans les zones %d à %d" % [fenetre.x, fenetre.y]


## Les lignes de la fiche, sans rien dessiner. Publique et statique pour la même
## raison que StatsPanel.content_height : le test qui vérifie qu'aucune fiche ne
## déborde sur l'aide du bas ne doit pas recopier ce calcul, sinon il validerait
## sa propre copie.
##
## **Seuls les paliers que cette base peut réellement sortir.** Une base ne tombe
## que dans sa fenêtre de zones, et le niveau d'un objet est celui de la zone où
## il tombe : une épée large, qui ne tombe qu'entre 16 et 40, n'atteint jamais un
## palier qui demande le niveau 52. Les afficher décrivait un objet qui ne peut
## pas exister — le défaut le plus coûteux pour un outil de réglage, puisqu'on
## équilibre en le lisant.
##
## Triées par identifiant : on vient chercher un affixe qu'on a en tête, et
## l'ordre de la réserve — thématique, puis chronologique — ne se devine pas.
static func lignes_affixes(base: ItemBase) -> Array:
	var out := []
	var affixes := ItemAffixPool.compatibles(base)
	affixes.sort_custom(func(a: ItemAffix, b: ItemAffix) -> bool: return a.id < b.id)

	var fenetre := ItemCatalog.fenetre_de_chute(base)
	# Un y de zéro veut dire « rien ne la remplace » : elle tombe jusqu'au
	# dernier niveau de zone du jeu.
	var dernier := Game.NIVEAU_MAX if fenetre.y <= 0 else fenetre.y

	# Typée à l'entrée : la réserve rend un tableau non typé, et sans ça
	# l'inférence part en Variant jusqu'au calcul de la place du palier.
	for brut in affixes:
		var affixe: ItemAffix = brut
		var atteignables := affixe.ouverts_entre(fenetre.x, dernier)
		if atteignables.is_empty():
			continue

		var titre := Ligne.new(DETAIL_TITRE)
		titre.ajouter("%s · %s ×%d" % [
			affixe.id, StatMod.LABELS.get(affixe.stat, affixe.stat), affixe.weight
		], 0.0)
		out.append(titre)

		var courante: Ligne = null
		for rang in atteignables.size():
			var place := rang % DETAIL_TIERS_PAR_LIGNE
			if place == 0:
				courante = Ligne.new(DETAIL_PALIER)
				out.append(courante)
			courante.ajouter(
				_texte_palier(affixe, int(atteignables[rang])), float(place) * DETAIL_TIER_W
			)

	return out


## « T3  34→51  27–34 », ou « T1  52+  44–54 » pour un palier que rien ne ferme.
##
## Le numéro est la **position** dans l'échelle, T1 en tête : c'est la règle
## d'ItemAffix, et la recopier autrement ferait mentir la fiche sur ce que
## l'infobulle du sac affiche pour le même objet.
##
## Deux niveaux et non un seul depuis que les paliers se ferment : n'afficher que
## celui qui ouvre laisserait croire qu'un objet de niveau 60 peut encore sortir
## le T8, ce qui est exactement ce que le tirage refuse maintenant.
static func _texte_palier(affixe: ItemAffix, index: int) -> String:
	var palier: ItemAffixTier = affixe.tiers[index]
	var mode := StatMod.Mode.PERCENT if affixe.percent else StatMod.Mode.FLAT
	var fenetre := affixe.fenetre_du_palier(index)
	var niveaux := "%d+" % fenetre.x if fenetre.y <= 0 else "%d→%d" % [fenetre.x, fenetre.y]
	return "T%d  %s  %s" % [
		index + 1,
		niveaux,
		StatMod.range_label(affixe.stat, mode, palier.min_value, palier.max_value),
	]


## La hauteur qu'occupe la plus longue colonne d'une fiche. C'est elle que le
## test compare au haut de l'aide : l'anneau tient aujourd'hui à quatre lignes
## près, et un affixe de plus le ferait déborder sans que rien ne le dise.
static func hauteur_de_fiche(base: ItemBase) -> float:
	var lignes := lignes_affixes(base)
	return ceilf(float(lignes.size()) / float(DETAIL_COLS)) * DETAIL_LINE


## Une étiquette de la fiche. Elles sont nombreuses — jusqu'à cent quinze pour un
## anneau — mais posées une fois et jamais retouchées : cet écran ne s'anime pas.
## Un Label par entrée plutôt qu'un bloc de texte par colonne, parce que la
## police n'est pas à chasse fixe et qu'un tableau aligné à coups d'espaces y
## serait en escalier.
func _etiquette(texte: String, at: Vector2, teinte: Color) -> void:
	var l := Label.new()
	l.text = texte
	l.position = at
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", DETAIL_SIZE)
	l.add_theme_color_override("font_color", teinte)
	stage.add_child(l)


## Le centre de la case d'un objet sur la planche, et **le seul endroit qui le
## sait**. Le dessin et le clic le calculaient sinon chacun de son côté, avec les
## mêmes quatre nombres réécrits : ce genre de paire ne se contredit pas le jour
## où on l'écrit, elle se contredit le jour où l'on décale la grille de deux
## pixels et où le clic reste sur l'ancienne, sans que rien ne le signale.
func _item_centre(rang: int) -> Vector2:
	var x0 := (size.x - ITEM_COLS * ITEM_CELL.x) * 0.5 + ITEM_CELL.x * 0.5
	return Vector2(
		x0 + (rang % ITEM_COLS) * ITEM_CELL.x,
		76.0 + (rang / ITEM_COLS) * ITEM_CELL.y
	)


func _item_rect(rang: int) -> Rect2:
	return Rect2(_item_centre(rang) - ITEM_CELL * 0.5, ITEM_CELL)


func _replay(s: AnimatedSprite2D) -> void:
	if is_instance_valid(s):
		s.play()


## Compose une planche par variante : une ligne d'images par animation, dans
## l'ordre de SpriteForge. Le fichier obtenu s'ouvre tel quel dans un éditeur
## de pixel art.
func _export() -> void:
	# out_dir et pas dir : la boucle plus bas itère déjà sur les directions.
	# On teste l'existence plutôt que le code de retour, qui vaut aussi erreur
	# quand le dossier est simplement déjà là.
	var out_dir := EXPORT_DIR
	DirAccess.make_dir_recursive_absolute(out_dir)
	if not DirAccess.dir_exists_absolute(out_dir):
		out_dir = EXPORT_FALLBACK
		DirAccess.make_dir_recursive_absolute(out_dir)

	var written := 0
	for archetype in SpriteForge.ARCHETYPES:
		for variant in SpriteForge.VARIANTS:
			var cfg := SpriteForge.config(archetype, variant)
			var rows: Array[Array] = []
			for anim in ANIMS:
				for dir in SpriteForge.DIRS:
					var row: Array = []
					for i in _frame_count(anim):
						row.append(SpriteForge.frame_image(cfg, dir, anim, i))
					rows.append(row)

			var sheet := _compose(rows)
			var path := "%s/%s_v%d.png" % [out_dir, archetype, variant]
			if sheet.save_png(path) == OK:
				written += 1

	_status = "%d planches ecrites dans %s" % [
		written, ProjectSettings.globalize_path(out_dir)
	]
	_build()


func _frame_count(anim: String) -> int:
	match anim:
		"walk": return SpriteForge.WALK_SWING.size()
		"attack": return SpriteForge.ATTACK_FRAMES
		_: return SpriteForge.IDLE_BOB.size()


func _compose(rows: Array[Array]) -> Image:
	var widest := 0
	for row in rows:
		widest = maxi(widest, row.size())

	var f := SpriteForge.FRAME
	var sheet := Image.create_empty(widest * f, rows.size() * f, false, Image.FORMAT_RGBA8)
	var region := Rect2i(0, 0, f, f)

	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			sheet.blit_rect(row[x], region, Vector2i(x * f, y * f))

	return sheet
