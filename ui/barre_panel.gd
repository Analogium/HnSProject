class_name BarrePanel
extends Control

## Les cinq cases à portée de doigt, en bas à droite. **Permanente** : c'est le
## seul panneau du jeu qu'on ne ferme pas, parce qu'il dit ce que font les
## touches qu'on a sous les doigts.
##
## Elle ne prend la souris **que le menu ouvert**. Le joueur lit ses compétences
## par sondage, hors du système d'entrées de l'interface : sans ce drapeau, le
## clic qui choisit une compétence dans le menu la lancerait aussi.

const PAD := 4.0
const SLOT := 26.0
const GAP := 4.0
const FONT_SIZE := 8
const LINE := 10.0
## Hauteur réservée sous les cases pour le libellé de touche.
const TOUCHE_H := 10.0

const FOND := Color(0.10, 0.09, 0.13, 0.88)
const VIDE := Color(0.16, 0.15, 0.20, 0.85)
const TEXTE := Color(0.90, 0.88, 0.95)
## La case dont le menu est ouvert, et celle que la souris survole.
const CHOISIE := Color(0.95, 0.82, 0.30)
## Le voile de recharge : il descend, il ne tourne pas — un cadran demanderait un
## arc, et à vingt-six pixels on ne lit pas un arc.
const RECHARGE := Color(0.02, 0.02, 0.04, 0.62)

var _player: Player
var _font: Font
## L'index de la case dont le menu est ouvert, ou -1. Le menu est modal : il
## prend la souris, et rien d'autre ne s'affiche pendant ce temps.
var _menu := -1
var _survol := -1
var _survol_menu := -1
## L'état dessiné à la dernière image : quelles cases sont en recharge, et
## lesquelles la réserve ne permet pas. Retenu pour ne redessiner que lorsqu'il
## change — une barre permanente qui se repeint soixante fois par seconde paie
## ce dessin toute la partie, y compris debout dans un couloir vide.
var _etat_affiche := -1


func _ready() -> void:
	_font = ThemeDB.fallback_font
	# Au plus proche voisin : une icône de vingt-quatre pixels agrandie dans une
	# case de vingt-six serait lissée par défaut, et la trame du pixel art
	# deviendrait une bouillie grise.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _exit_tree() -> void:
	if _menu >= 0:
		Game.grab_ui_input(self, false)


func bind(player: Player) -> void:
	_player = player
	queue_redraw()


## Les recharges descendent à chaque image et le voile doit suivre, sinon la
## barre annonce prête une compétence qui ne part pas. Mais seulement **quand
## quelque chose bouge** : au repos, rien ne se repeint.
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
	# Tant qu'une recharge descend, le voile change à chaque image ; le reste du
	# temps, seul un changement d'état vaut un dessin.
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
		# Un clic dans le menu choisit ; un clic ailleurs referme sans rien
		# changer. Refermer par le dehors est le geste qu'on essaie d'abord.
		if _survol_menu >= 0:
			_assigner(_survol_menu)
		_fermer()
	elif _survol >= 0:
		_ouvrir(_survol)
	else:
		return
	get_viewport().set_input_as_handled()


## Le menu ouvert est **modal** : il a pris la souris, il possède donc tout
## l'écran, et un clic au-dehors le referme. Le menu fermé, la barre ne répond
## que des clics tombés sur elle — sinon elle mangerait ceux des panneaux
## ouverts en même temps.
func _possede_le_clic(point: Vector2) -> bool:
	return _menu >= 0 or Rect2(Vector2.ZERO, size).has_point(point)


func _ouvrir(index: int) -> void:
	_menu = index
	Game.grab_ui_input(self, true)
	queue_redraw()


func _fermer() -> void:
	_menu = -1
	_survol_menu = -1
	Game.grab_ui_input(self, false)
	queue_redraw()


## La première entrée vide la case ; les suivantes sont ce qu'on peut y poser.
##
## Une compétence déjà posée ailleurs **se déplace** au lieu de se dédoubler :
## deux cases qui lancent la même chose sont deux touches perdues.
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


## Les entrées du menu : « vider », puis ce qu'on peut poser.
func _entrees() -> Array[String]:
	var out: Array[String] = ["— vider la case —"]
	if _player != null:
		for competence in _player.competences_disponibles():
			out.append(competence.nom)
	return out


## Le cadre du menu, **mesuré ici et nulle part ailleurs**. Le fond et les lignes
## le calculaient chacun de leur côté à partir du nombre d'entrées ; une compétence
## de plus, et il suffisait d'en corriger un pour que le texte déborde du cadre.
##
## Le menu monte depuis la barre : il n'y a rien au-dessus, et tout en dessous.
func _menu_cadre(entrees: int) -> Rect2:
	var hauteur := float(entrees) * LINE + PAD * 2.0
	return Rect2(PAD, -hauteur - PAD, size.x - PAD * 2.0, hauteur)


func _menu_rect(entree: int) -> Rect2:
	var cadre := _menu_cadre(_entrees().size())
	return Rect2(
		cadre.position.x, cadre.position.y + PAD + float(entree) * LINE,
		cadre.size.x, LINE
	)


## Le libellé de la touche, lu dans la **carte d'entrées** et non réécrit ici :
## deux vérités sur une touche, et la barre finit par annoncer un geste qui n'est
## plus celui qui marche.
##
## Le jeu lie des **positions** de touches et non des lettres — c'est ce qui fait
## que ZQSD tombe sous les doigts d'un clavier français comme WASD sous ceux d'un
## clavier américain. Mais une position n'a pas de nom : il faut la retraduire
## dans la disposition **du joueur**, sinon la barre annonce « A » pour une touche
## sur laquelle il lit « Q ». C'est le défaut qu'avait la première version.
static func libelle_de_touche(index: int) -> String:
	for evenement in InputMap.action_get_events("competence_%d" % (index + 1)):
		var clavier := evenement as InputEventKey
		if clavier != null:
			if clavier.keycode != 0:
				return OS.get_keycode_string(clavier.keycode)
			# Le serveur d'affichage muet des tests n'a aucune disposition à
			# consulter : lui demander la traduction pousse une erreur moteur, que
			# la campagne compte — à raison — comme un échec. On garde alors le
			# nom de la position, faute de mieux.
			var lue := clavier.physical_keycode
			if DisplayServer.get_name() != "headless":
				var traduite := DisplayServer.keyboard_get_keycode_from_physical(lue)
				if traduite != 0:
					lue = traduite
			return OS.get_keycode_string(lue)
		var clic := evenement as InputEventMouseButton
		if clic != null:
			return "clic G" if clic.button_index == MOUSE_BUTTON_LEFT else "clic D"
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

	# Le voile de recharge descend depuis le haut : la case se remplit à mesure
	# qu'elle redevient disponible.
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


## Ce qui identifie la compétence dans sa case : son icône si elle en a une, à
## défaut un disque de la couleur de sa nature.
##
## Le disque n'est pas un bouchon en attendant mieux : à vingt-six pixels une
## teinte se lit d'un coup d'œil, et une compétence sans image reste jouable et
## reconnaissable. Le menu, lui, écrit les noms en clair.
func _draw_marque(r: Rect2, competence: Competence) -> void:
	var tex := IconeDeCompetence.texture(competence)
	if tex == null:
		draw_circle(r.get_center(), SLOT * 0.30, DamageType.COLORS[competence.nature])
		return
	var taille := tex.get_size() * float(IconeDeCompetence.facteur(tex, SLOT))
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
		draw_string(
			_font, Vector2(r.position.x + 3.0, r.position.y + LINE - 2.0), entrees[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE,
			UiPalette.HINT if i == 0 else TEXTE
		)
