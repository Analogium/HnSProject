class_name AtelierPanel
extends Control

## L'établi : fabriquer un objet précis et le poser au sol, pour régler et
## éprouver sans attendre qu'il tombe.
##
## **Outil de réglage, à retirer avant publication.** Il tient en trois attaches :
## le nœud `UI/Atelier` de la zone, la touche B, et le branchement de
## `drop_requested`. Rien d'autre du jeu ne le connaît.
##
## Il ne fabrique que des objets que le jeu **pourrait** produire : les affixes
## proposés sont ceux que la base accepte, les paliers ceux que le niveau d'objet
## ouvre, et le compte est borné par la table des poids. Un établi qui
## fabriquerait l'impossible ferait chasser des bugs qui n'existent pas.
##
## Il ne tire **rien** au hasard : les valeurs sont le haut de la fourchette du
## palier. Passer par `Game.rng` décalerait toutes les graines de zone tirées
## ensuite (invariant 3), et un outil de réglage n'a pas à changer la partie
## qu'on règle.

## Ce qu'on fabrique et qu'on veut voir tomber. C'est la zone qui le pose, par le
## même chemin que ce qu'on jette du sac.
signal drop_requested(item: Item)

const PAD := 6.0
const LINE := 10.0
const FONT_SIZE := 8
const TITLE_SIZE := 9
const HEADER := 16.0
## Largeur de la colonne des bases. Assez pour le plus long nom du catalogue.
const COL := 150.0

## Le plafond vient de la table des poids et n'est pas réécrit ici : le jour où
## un objet pourra porter sept affixes, l'établi le saura sans qu'on y touche.
##
## Une fonction et non une constante : `COUNT_WEIGHTS.size()` n'est pas repliable
## à la compilation, et une `const` bâtie dessus reste introuvable depuis un autre
## script — c'est le test qui l'a découvert.
static func maximum_d_affixes() -> int:
	return ItemAffixPool.COUNT_WEIGHTS.size() - 1

const CHOISI := Color(0.52, 0.88, 0.48)
const REFUS := Color(0.92, 0.46, 0.42)
const SURVOL := Color(1.0, 1.0, 1.0, 0.10)
const BOUTON := Color(0.18, 0.17, 0.23)

var _font: Font
var _base := 0
var _page := 0
## La page de la liste des affixes. Un bijou en accepte plus de vingt, et une
## liste coupée au bas du panneau cacherait des affixes qu'on croirait absents de
## la réserve.
var _page_affixes := 0
var _niveau := 1
## Identifiant d'affixe → indice de palier, **0 étant le meilleur**, comme dans
## `ItemAffix.tiers`. Vidé dès que la base change : un affixe compatible avec une
## épée ne l'est pas forcément avec des bottes.
var _choisis := {}
## Les zones cliquables de la dernière mise en page : rectangle, action, texte.
## Construites par `_disposer()`, que le dessin **et** le clic appellent — deux
## mises en page calculées séparément finiraient par ne plus se superposer, et
## c'est le clic qui tomberait à côté.
var _lignes: Array[Dictionary] = []
var _survol := ""


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font


func _exit_tree() -> void:
	if visible:
		Game.grab_ui_input(self, false)


func toggle() -> void:
	visible = not visible
	Game.grab_ui_input(self, visible)
	if visible:
		_survol = ""
	queue_redraw()


# --------------------------------------------------------------------------
# L'état
# --------------------------------------------------------------------------


func bases() -> Array:
	return ItemCatalog.ALL


func base_courante() -> ItemBase:
	var toutes := bases()
	return toutes[_base] if _base >= 0 and _base < toutes.size() else null


## Les affixes que cette base accepte, quel que soit son niveau. La question du
## niveau vient après, palier par palier.
func compatibles() -> Array:
	return ItemAffixPool.compatibles(base_courante())


## L'objet tel qu'il est réglé, ou null. Reconstruit à chaque appel : c'est un
## outil, pas une boucle de jeu, et un exemplaire retenu se désynchroniserait du
## panneau au premier clic.
func fabriquer() -> Item:
	var base := base_courante()
	if base == null:
		return null
	var explicits: Array[RolledAffix] = []
	for id in _choisis:
		var affixe := ItemAffixPool.by_id(id)
		if affixe == null:
			continue
		var index: int = _choisis[id]
		if index < 0 or index >= affixe.tiers.size():
			continue
		explicits.append(RolledAffix.new(id, index + 1, affixe.au_sommet(index)))
	return Item.new(base, explicits, _niveau)


func choisir_base(index: int) -> void:
	var toutes := bases()
	if index < 0 or index >= toutes.size() or index == _base:
		return
	_base = index
	_page_affixes = 0
	# Les affixes suivaient l'ancienne base : les garder poserait un « allonge »
	# sur une paire de bottes, c'est-à-dire exactement ce que l'établi refuse.
	_choisis.clear()


## Change le niveau d'objet et **élague** ce qui n'est plus atteignable. Sans cet
## élagage, descendre le niveau laisserait un palier trop haut sur l'objet : il
## sortirait de l'établi un objet que le jeu ne peut pas produire.
func changer_niveau(delta: int) -> void:
	_niveau = clampi(_niveau + delta, 1, 100)
	for id in _choisis.keys():
		var affixe := ItemAffixPool.by_id(id)
		if affixe == null or not affixe.ouverts(_niveau).has(_choisis[id]):
			_choisis.erase(id)


## Fait tourner un affixe : absent, puis chaque palier ouvert du meilleur au
## pire, puis absent de nouveau. Un seul geste pour les trois questions —
## le veut-on, à quel palier, et l'enlève-t-on.
func basculer_affixe(id: String) -> void:
	var affixe := ItemAffixPool.by_id(id)
	if affixe == null:
		return
	var ouverts := affixe.ouverts(_niveau)
	if ouverts.is_empty():
		return
	if not _choisis.has(id):
		if _choisis.size() >= maximum_d_affixes():
			return
		_choisis[id] = ouverts[0]
		return
	var suivant := ouverts.find(_choisis[id]) + 1
	if suivant >= ouverts.size():
		_choisis.erase(id)
	else:
		_choisis[id] = ouverts[suivant]


func reinitialiser() -> void:
	_base = 0
	_page = 0
	_page_affixes = 0
	_niveau = 1
	_choisis.clear()


func pages() -> int:
	return maxi(ceili(float(bases().size()) / float(_par_page())), 1)


func _par_page() -> int:
	return maxi(int((size.y - HEADER - LINE * 2.0 - PAD * 2.0) / LINE), 1)


func pages_d_affixes() -> int:
	return maxi(ceili(float(compatibles().size()) / float(_affixes_par_page())), 1)


## Autant de lignes qu'il en tient entre le haut de la liste et les deux boutons
## du bas.
func _affixes_par_page() -> int:
	return maxi(int((_bas_des_affixes() - _haut_des_affixes()) / LINE), 1)


## Le haut de la liste des affixes, sous le niveau d'objet et le compte.
func _haut_des_affixes() -> float:
	return HEADER + LINE * 5.0 + 6.0


## Le bas de la liste : le haut des deux boutons, moins une ligne d'air.
func _bas_des_affixes() -> float:
	return size.y - LINE * 2.0 - PAD


# --------------------------------------------------------------------------
# La mise en page, construite une fois et lue deux fois
# --------------------------------------------------------------------------


func _ajouter(rect: Rect2, action: String, texte: String, teinte: Color) -> void:
	_lignes.append({"rect": rect, "action": action, "texte": texte, "teinte": teinte})


## Construit les lignes cliquables **et** ce qu'elles affichent. Appelée par le
## dessin et par le clic : c'est ce qui garantit qu'on clique bien sur ce qu'on
## voit.
func _disposer() -> void:
	_lignes.clear()
	var droite := PAD + COL + PAD
	var largeur_droite := size.x - droite - PAD

	# --- la colonne des bases ---
	var toutes := bases()
	var par_page := _par_page()
	_page = clampi(_page, 0, pages() - 1)
	_ajouter(Rect2(PAD, HEADER, 14.0, LINE), "page:-1", "<", UiPalette.TEXTE)
	_ajouter(Rect2(PAD + COL - 14.0, HEADER, 14.0, LINE), "page:1", ">", UiPalette.TEXTE)

	var y := HEADER + LINE + 2.0
	for i in range(_page * par_page, mini((_page + 1) * par_page, toutes.size())):
		var base: ItemBase = toutes[i]
		_ajouter(
			Rect2(PAD, y, COL, LINE), "base:%d" % i, base.display_name,
			CHOISI if i == _base else UiPalette.TEXTE
		)
		y += LINE

	# --- le niveau d'objet ---
	var yd := HEADER + LINE * 3.0 + 4.0
	var x := droite + largeur_droite - 4.0 * 18.0
	for pas in [-10, -1, 1, 10]:
		_ajouter(
			Rect2(x, yd, 16.0, LINE), "niveau:%d" % pas, "%+d" % pas, UiPalette.TEXTE
		)
		x += 18.0

	# --- les affixes, par page ---
	var yp := yd + LINE
	x = droite + largeur_droite - 2.0 * 18.0
	for pas in [-1, 1]:
		_ajouter(Rect2(x, yp, 16.0, LINE), "affixes:%d" % pas, "<" if pas < 0 else ">", UiPalette.TEXTE)
		x += 18.0

	var tous := compatibles()
	var par_page_d_affixes := _affixes_par_page()
	_page_affixes = clampi(_page_affixes, 0, pages_d_affixes() - 1)
	var ya := _haut_des_affixes()
	var debut := _page_affixes * par_page_d_affixes
	for i in range(debut, mini(debut + par_page_d_affixes, tous.size())):
		var affixe: ItemAffix = tous[i]
		var ouverts := affixe.ouverts(_niveau)
		var pris := _choisis.has(affixe.id)
		var teinte := UiPalette.LABEL
		var etat := "—"
		if ouverts.is_empty():
			etat = "niv. %d" % affixe.niveau_minimum()
		elif pris:
			var index: int = _choisis[affixe.id]
			etat = "T%d  %s" % [index + 1, affixe.au_sommet(index).valeur_lisible()]
			teinte = CHOISI
		else:
			teinte = UiPalette.TEXTE
		# Le « (%) » dit lequel des deux on pose quand deux affixes visent le même
		# champ, l'un à plat, l'autre en pourcentage. L'identifiant ne tient plus à
		# côté d'un nom comme « dégâts nécrotiques aux attaques ».
		_ajouter(
			Rect2(droite, ya, largeur_droite, LINE), "affixe:%s" % affixe.id,
			"%s%s|%s" % [
				StatMod.nom(affixe.stat, affixe.portee), " (%)" if affixe.percent else "", etat
			], teinte
		)
		ya += LINE

	# --- les deux boutons ---
	var yb := size.y - LINE - PAD
	_ajouter(Rect2(droite, yb, 74.0, LINE), "lacher", "Lâcher au sol", UiPalette.TEXTE)
	_ajouter(Rect2(droite + 80.0, yb, 66.0, LINE), "reset", "Réinitialiser", UiPalette.TEXTE)


func _action_sous(point: Vector2) -> String:
	_disposer()
	for ligne in _lignes:
		if (ligne["rect"] as Rect2).has_point(point):
			return String(ligne["action"])
	return ""


# --------------------------------------------------------------------------
# Les entrées
# --------------------------------------------------------------------------


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var souris := make_input_local(event) as InputEventMouse
	if souris == null:
		return

	if souris is InputEventMouseMotion:
		var vu := _action_sous(souris.position)
		if vu != _survol:
			_survol = vu
			queue_redraw()
		return

	var bouton := souris as InputEventMouseButton
	if not bouton.pressed or bouton.button_index != MOUSE_BUTTON_LEFT:
		return
	# Hors de la fenêtre, le clic ne nous appartient pas : il doit rester
	# disponible pour le panneau ouvert à côté.
	if not Rect2(Vector2.ZERO, size).has_point(bouton.position):
		return

	_appliquer(_action_sous(bouton.position))
	queue_redraw()
	get_viewport().set_input_as_handled()


## Le seul endroit qui traduit un clic en changement d'état. Publique pour que le
## test rejoue les gestes sans déplacer la souris de l'écran.
func _appliquer(action: String) -> void:
	if action.is_empty():
		return
	var coupe := action.split(":")
	match coupe[0]:
		"base": choisir_base(int(coupe[1]))
		"page": _page = clampi(_page + int(coupe[1]), 0, pages() - 1)
		"affixes": _page_affixes = clampi(_page_affixes + int(coupe[1]), 0, pages_d_affixes() - 1)
		"niveau": changer_niveau(int(coupe[1]))
		"affixe": basculer_affixe(coupe[1])
		"lacher":
			var objet := fabriquer()
			if objet != null:
				drop_requested.emit(objet)
		"reset": reinitialiser()


# --------------------------------------------------------------------------
# Le dessin
# --------------------------------------------------------------------------


func _draw() -> void:
	if _font == null:
		return
	_disposer()
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BACK)
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BORDER, false, 1.0)
	_texte("ÉTABLI  —  outil de réglage", Vector2(PAD, 11.0), TITLE_SIZE, UiPalette.TITRE)

	var droite := PAD + COL + PAD
	draw_line(
		Vector2(droite - PAD * 0.5, HEADER), Vector2(droite - PAD * 0.5, size.y - PAD),
		UiPalette.BORDER
	)
	_texte(
		"bases  %d/%d" % [_page + 1, pages()], Vector2(PAD + 18.0, HEADER + LINE - 2.0),
		FONT_SIZE, UiPalette.LABEL
	)
	_dessiner_fiche(droite)

	for ligne in _lignes:
		var r: Rect2 = ligne["rect"]
		var action := String(ligne["action"])
		if action == _survol:
			draw_rect(r, SURVOL)
		if action == "lacher" or action == "reset" or action.begins_with("niveau:") \
				or action.begins_with("page:") or action.begins_with("affixes:"):
			draw_rect(r, BOUTON)
			draw_rect(r, UiPalette.BORDER, false, 1.0)
		# Le séparateur « | » sépare l'intitulé de son état : le premier à gauche,
		# le second calé à droite, pour que la colonne des paliers s'aligne.
		var texte := String(ligne["texte"])
		var teinte: Color = ligne["teinte"]
		if texte.contains("|"):
			var parts := texte.split("|")
			_texte(parts[0], r.position + Vector2(2.0, LINE - 2.0), FONT_SIZE, teinte)
			var w := _font.get_string_size(parts[1], HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x
			_texte(parts[1], r.position + Vector2(r.size.x - w - 2.0, LINE - 2.0), FONT_SIZE, teinte)
		else:
			_texte(texte, r.position + Vector2(2.0, LINE - 2.0), FONT_SIZE, teinte)


func _dessiner_fiche(droite: float) -> void:
	var base := base_courante()
	if base == null:
		return
	var objet := fabriquer()
	var y := HEADER + LINE - 2.0
	_texte(base.display_name, Vector2(droite, y), TITLE_SIZE, objet.color())
	_texte(
		"%s · %s · %d×%d · lignée %s p%d" % [
			base.family if not base.family.is_empty() else "—", base.kind,
			base.grid_size.x, base.grid_size.y, base.lignee, base.palier
		],
		Vector2(droite, y + LINE), FONT_SIZE, UiPalette.LABEL
	)
	_texte("niveau d'objet  %d" % _niveau, Vector2(droite, y + LINE * 2.0 + 6.0), FONT_SIZE, UiPalette.TEXTE)

	var pleine := _choisis.size() >= maximum_d_affixes()
	_texte(
		"affixes  %d/%d      page %d/%d" % [
			_choisis.size(), maximum_d_affixes(), _page_affixes + 1, pages_d_affixes()
		],
		Vector2(droite, y + LINE * 4.0 + 4.0), FONT_SIZE, REFUS if pleine else UiPalette.LABEL
	)


func _texte(texte: String, at: Vector2, taille: int, teinte: Color) -> void:
	draw_string(_font, at, texte, HORIZONTAL_ALIGNMENT_LEFT, -1.0, taille, teinte)
