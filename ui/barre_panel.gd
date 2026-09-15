class_name BarrePanel
extends Control

## Les cinq cases, en bas à droite, **permanentes**. La souris n'est prise que menu
## ouvert : sinon le clic qui choisit une compétence la lancerait aussi.

const PAD := 4.0
const SLOT := 26.0
const GAP := 4.0
const FONT_SIZE := 8
## Hauteur réservée sous les cases pour le libellé de touche.
const TOUCHE_H := 10.0
## Une entrée du menu : l'icône à sa taille de grille, sans réduction fractionnaire.
const ENTREE_H := IconeDeCompetence.COTE + 2.0

const FOND := Color(0.10, 0.09, 0.13, 0.88)
const VIDE := Color(0.16, 0.15, 0.20, 0.85)
## La case dont le menu est ouvert, et celle que la souris survole.
const CHOISIE := Color(0.95, 0.82, 0.30)
## Le voile de recharge descend : à vingt-six pixels, un arc ne se lit pas.
const RECHARGE := Color(0.02, 0.02, 0.04, 0.62)

var _player: Player
var _font: Font
## La case dont le menu, modal, est ouvert, ou -1.
var _menu := -1
var _survol := -1
var _survol_menu := -1
## L'état dessiné, pour ne repeindre que lorsqu'il change.
var _etat_affiche := -1


func _ready() -> void:
	_font = ThemeDB.fallback_font
	# Au plus proche voisin : lissée, la trame du pixel art tournerait au gris.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _exit_tree() -> void:
	if _menu >= 0:
		Game.grab_ui_input(self, false)


## Noms et libellés dessinés à la main.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func bind(player: Player) -> void:
	_player = player
	queue_redraw()


## Le voile suit les recharges, et rien ne se repeint au repos.
func _process(_delta: float) -> void:
	if _player == null:
		return
	var etat := 0
	for i in BarreDeCompetences.EMPLACEMENTS:
		if _player.recharge_restante(i) > 0.0:
			etat |= 1 << i
		var competence := _player.barre.competence_de(i)
		if competence != null and _player.mana < competence.cout_en_mana:
			etat |= 1 << (i + BarreDeCompetences.EMPLACEMENTS)
	# Une recharge qui descend repeint à chaque image ; sinon, seul un changement d'état.
	if etat != _etat_affiche or (etat & ((1 << BarreDeCompetences.EMPLACEMENTS) - 1)) != 0:
		_etat_affiche = etat
		queue_redraw()


func _input(event: InputEvent) -> void:
	if _player == null:
		return
	var souris := make_input_local(event) as InputEventMouse
	if souris == null:
		return

	if souris is InputEventMouseMotion:
		_track(souris.position)
		return

	var bouton := souris as InputEventMouseButton
	if not bouton.pressed or bouton.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _possede_le_clic(bouton.position):
		return
	_track(bouton.position)

	if _menu >= 0:
		# Dans le menu, on choisit ; ailleurs, on referme.
		if _survol_menu >= 0:
			_assigner(_survol_menu)
		_fermer()
	elif _survol >= 0:
		_ouvrir(_survol)
	else:
		return
	get_viewport().set_input_as_handled()


## Menu ouvert : **modal**, tout l'écran. Fermé : seuls les clics tombés sur la barre.
func _possede_le_clic(point: Vector2) -> bool:
	return _menu >= 0 or Rect2(Vector2.ZERO, size).has_point(point)


func _ouvrir(index: int) -> void:
	_menu = index
	Game.grab_ui_input(self, true)
	queue_redraw()


func menu_ouvert() -> bool:
	return _menu >= 0


## Pour Échap, que la zone traite : la barre ne lit pas le clavier.
func fermer_le_menu() -> void:
	if menu_ouvert():
		_fermer()


func _fermer() -> void:
	_menu = -1
	_survol_menu = -1
	Game.grab_ui_input(self, false)
	queue_redraw()


## La première entrée vide la case. Une compétence posée ailleurs **se déplace**.
func _assigner(entree: int) -> void:
	if _menu < 0:
		return
	if entree == 0:
		_player.barre.vider(_menu)
		return
	var choix := _player.competences_disponibles()
	var index := entree - 1
	if index < 0 or index >= choix.size():
		return
	var id := choix[index].id
	for i in BarreDeCompetences.EMPLACEMENTS:
		if _player.barre.id_de(i) == id:
			_player.barre.vider(i)
	_player.barre.poser(_menu, id)


func _track(point: Vector2) -> void:
	var case := -1
	for i in BarreDeCompetences.EMPLACEMENTS:
		if _slot_rect(i).has_point(point):
			case = i
			break

	var entree := -1
	if _menu >= 0:
		for i in _entrees().size():
			if _menu_rect(i).has_point(point):
				entree = i
				break

	if case == _survol and entree == _survol_menu:
		return
	_survol = case
	_survol_menu = entree
	queue_redraw()


func _slot_rect(index: int) -> Rect2:
	return Rect2(PAD + float(index) * (SLOT + GAP), PAD, SLOT, SLOT)


## Les entrées du menu : « vider », qui n'a pas de compétence, puis ce qu'on peut
## poser.
func _entrees() -> Array[Competence]:
	var out: Array[Competence] = [null]
	if _player != null:
		out.append_array(_player.competences_disponibles())
	return out


## Le cadre du menu, **mesuré ici seulement**, qui monte depuis la barre.
func _menu_cadre(entrees: int) -> Rect2:
	var hauteur := float(entrees) * ENTREE_H + PAD * 2.0
	return Rect2(PAD, -hauteur - PAD, size.x - PAD * 2.0, hauteur)


func _menu_rect(entree: int) -> Rect2:
	var cadre := _menu_cadre(_entrees().size())
	return Rect2(
		cadre.position.x, cadre.position.y + PAD + float(entree) * ENTREE_H,
		cadre.size.x, ENTREE_H
	)


## La place de l'icône ; le clic la lit comme le dessin.
func _icone_d_entree(entree: int) -> Rect2:
	var r := _menu_rect(entree)
	var cote := float(IconeDeCompetence.COTE)
	return Rect2(r.position + Vector2(2.0, (r.size.y - cote) * 0.5), Vector2(cote, cote))


## Lu dans la **carte d'entrées**, jamais réécrit, et traduit dans la disposition du
## joueur : le jeu lie des positions (ZQSD comme WASD), et la barre doit dire la
## lettre qu'il lit.
static func libelle_de_touche(index: int) -> String:
	for evenement in InputMap.action_get_events("competence_%d" % (index + 1)):
		var clavier := evenement as InputEventKey
		if clavier != null:
			if clavier.keycode != 0:
				return OS.get_keycode_string(clavier.keycode)
			# Le serveur muet des tests n'a pas de disposition : on garde le nom de la position
			# plutôt que de pousser une erreur moteur.
			var lue := clavier.physical_keycode
			if DisplayServer.get_name() != "headless":
				var traduite := DisplayServer.keyboard_get_keycode_from_physical(lue)
				if traduite != 0:
					lue = traduite
			return OS.get_keycode_string(lue)
		var clic := evenement as InputEventMouseButton
		if clic != null:
			return Textes.t("clic G") if clic.button_index == MOUSE_BUTTON_LEFT else Textes.t("clic D")
	return ""


# --------------------------------------------------------------------------


func _draw() -> void:
	if _font == null or _player == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), FOND)

	for i in BarreDeCompetences.EMPLACEMENTS:
		_draw_slot(i)
	if _menu >= 0:
		_draw_menu()


func _draw_slot(index: int) -> void:
	var r := _slot_rect(index)
	draw_rect(r, VIDE)

	var competence := _player.barre.competence_de(index)
	if competence != null:
		_draw_marque(r, competence)
		if _player.mana < competence.cout_en_mana:
			draw_rect(r, RECHARGE)

	# Le voile descend : la case se remplit en redevenant disponible.
	var reste := _player.recharge_restante(index)
	if reste > 0.0 and competence != null:
		var total := maxf(competence.intervalle(_player.stats), 0.001)
		var ratio := clampf(reste / total, 0.0, 1.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * ratio)), RECHARGE)

	var teinte := UiPalette.BORDER
	if index == _menu or index == _survol:
		teinte = CHOISIE
	draw_rect(r, teinte, false, 1.0)

	var touche := libelle_de_touche(index)
	if not touche.is_empty():
		var largeur := _font.get_string_size(
			touche, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE
		).x
		draw_string(
			_font, Vector2(r.position.x + (SLOT - largeur) * 0.5, r.end.y + TOUCHE_H - 2.0),
			touche, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT
		)


## L'icône, à défaut un disque de la couleur de la nature, lisible à vingt-six pixels ;
## le menu montre la même marque.
func _draw_marque(r: Rect2, competence: Competence) -> void:
	var cote := minf(r.size.x, r.size.y)
	var tex := IconeDeCompetence.texture(competence)
	if tex == null:
		draw_circle(r.get_center(), cote * 0.30, DamageType.COLORS[competence.nature])
		return
	var taille := tex.get_size() * float(IconeDeCompetence.facteur(tex, cote))
	draw_texture_rect(tex, Rect2(r.position + (r.size - taille) * 0.5, taille), false)


func _draw_menu() -> void:
	var entrees := _entrees()
	var cadre := _menu_cadre(entrees.size())
	draw_rect(cadre, UiPalette.TIP_BACK)
	draw_rect(cadre, UiPalette.BORDER, false, 1.0)

	for i in entrees.size():
		var r := _menu_rect(i)
		if i == _survol_menu:
			draw_rect(r, Color(1.0, 1.0, 1.0, 0.08))
		var base := r.position.y + (r.size.y + FONT_SIZE) * 0.5 - 1.0
		var competence := entrees[i]
		if competence == null:
			draw_string(
				_font, Vector2(r.position.x + 3.0, base), Textes.t("— vider la case —"),
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT
			)
			continue
		var icone := _icone_d_entree(i)
		_draw_marque(icone, competence)
		draw_string(
			_font, Vector2(icone.end.x + 5.0, base), competence.nom_affiche(),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.TEXTE
		)
