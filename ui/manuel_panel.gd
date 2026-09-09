class_name ManuelPanel
extends Control

## Le râtelier et la page du manuel choisi, à la touche M.
##
## Les trois emplacements en haut, la page dessous : une seule fenêtre et aucune
## navigation. Ouvrir un livre, c'est cliquer sur son dos — et l'on voit du même
## coup ce qu'on étudie et ce qu'on n'étudie pas.
##
## **On n'investit que d'ici**, donc seulement dans un livre posé au râtelier.
## C'est une règle de jeu et non une commodité : équiper est l'engagement, et
## l'engagement précède l'investissement. Un livre qu'on feuillette dans le sac
## permettrait de tout monter sans jamais rien choisir.

## Ce qu'on jette faute de place, comme le sac : c'est la zone qui le pose au sol.
signal drop_requested(item: Item)

const PAD := 6.0
const HEADER := 15.0
const SLOT := 40.0
const SLOT_GAP := 6.0
const FONT_SIZE := 8
const TITLE_SIZE := 9
const LINE := 10.0

## La barre d'expérience du livre, en haut de sa page. C'est la première chose
## que montre le dessin du jalon, et la seule qui bouge en se battant.
const XP_H := 5.0

## Une case de compétence. Trente-quatre pixels : de quoi écrire « 3/5 » au
## centre et garder un liseré lisible, à un viewport de 640 × 360.
const CASE := 34.0
const CASE_GAP := 6.0

## Les trois états d'une case, qui doivent se distinguer **sans lire** : le
## liseré fait la différence, pas le texte.
## Verrouillée : le niveau du livre n'y donne pas encore droit.
const VERROU := Color(0.26, 0.24, 0.31)
## Ouverte, et il reste un point à y mettre — le vert des points à placer de la
## fiche de personnage, pour dire la même chose au même endroit du regard.
const OUVERTE := Color(0.52, 0.88, 0.48)
## Pleine : l'or, qui dans ce jeu veut dire « ça compte plus que d'habitude ».
const PLEINE := Color(0.95, 0.82, 0.30)
## Ouverte mais sans point disponible : ni promesse, ni interdit.
const ATTENTE := Color(0.55, 0.53, 0.64)

const CASE_FOND := Color(0.14, 0.13, 0.18, 0.9)
const XP_FOND := Color(0.10, 0.09, 0.13)
## Le bleu du joueur, celui de sa barre d'expérience : un livre progresse comme
## son porteur, et l'œil doit le reconnaître.
const XP_PLEIN := Color(0.24, 0.45, 0.86)
const TEXTE := Color(0.90, 0.88, 0.95)

var _player: Player
var _font: Font
## L'emplacement dont la page est ouverte. Zéro par défaut : la fenêtre montre
## quelque chose dès l'ouverture plutôt que d'attendre un clic.
var _choisi := 0
var _survol_slot := -1
var _survol_case := -1
## L'expérience du livre affiché à la dernière image, pour ne redessiner que
## lorsqu'elle bouge — la page reste ouverte pendant qu'on se bat.
var _exp_affichee := -1


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font


func _exit_tree() -> void:
	if visible:
		Game.grab_ui_input(self, false)


func bind(player: Player) -> void:
	_player = player
	queue_redraw()


func toggle() -> void:
	visible = not visible
	Game.grab_ui_input(self, visible)
	if visible:
		_track(get_local_mouse_position())
	queue_redraw()


func _process(_delta: float) -> void:
	if not visible:
		return
	var livre := _livre()
	var exp_courante := livre.manuel.experience if livre != null else -1
	if exp_courante != _exp_affichee:
		_exp_affichee = exp_courante
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or _player == null:
		return
	# La position vient de l'événement, comme dans le sac : c'est elle qui est
	# vraie au moment du clic, et elle rend le geste rejouable dans un test sans
	# déplacer la souris de l'écran.
	var souris := make_input_local(event) as InputEventMouse
	if souris == null:
		return

	if souris is InputEventMouseMotion:
		_track(souris.position)
		return

	var bouton := souris as InputEventMouseButton
	if not bouton.pressed:
		return
	if not _possede_le_clic(bouton.position):
		return
	_track(bouton.position)

	match bouton.button_index:
		MOUSE_BUTTON_LEFT:
			if _survol_slot >= 0:
				_choisi = _survol_slot
			elif _survol_case >= 0:
				_investir(_survol_case)
		MOUSE_BUTTON_RIGHT:
			if _survol_slot >= 0:
				_ranger(_survol_slot)
		_:
			return

	queue_redraw()
	get_viewport().set_input_as_handled()


## Hors de la fenêtre, le clic ne nous appartient pas : il doit rester
## disponible pour le panneau ouvert à côté. Sans cette règle, deux fenêtres
## ouvertes en même temps et une seule répond.
func _possede_le_clic(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point)


## Le livre dont la page est ouverte, ou null.
func _livre() -> Item:
	return _player.ratelier.a(_choisi) if _player != null else null


## Un point de plus dans cette case. Les quatre conditions sont dans `Manuel` et
## nulle part ici : une interface qui referait le test finirait par en oublier
## une, et c'est le clic qui donnerait le point de trop.
func _investir(index: int) -> void:
	var livre := _livre()
	if livre == null:
		return
	var cases := livre.base.manuel.cases
	if index < 0 or index >= cases.size() or cases[index].competence == null:
		return
	livre.manuel.investir(livre.base.manuel, cases[index].competence.id)


## Le livre quitte le râtelier et retourne au sac ; s'il n'y tient plus, il tombe.
func _ranger(index: int) -> void:
	var parti := _player.cesser_d_etudier(index)
	if parti != null and not _player.inventory.add(parti):
		drop_requested.emit(parti)


func _track(point: Vector2) -> void:
	var slot := -1
	for i in Ratelier.EMPLACEMENTS:
		if _slot_rect(i).has_point(point):
			slot = i
			break

	var case := -1
	var livre := _livre()
	if livre != null:
		var cases := livre.base.manuel.cases
		for i in cases.size():
			if _case_rect(cases[i].position).has_point(point):
				case = i
				break

	if slot == _survol_slot and case == _survol_case:
		return
	_survol_slot = slot
	_survol_case = case
	queue_redraw()


func _slot_rect(index: int) -> Rect2:
	return Rect2(PAD + float(index) * (SLOT + SLOT_GAP), HEADER, SLOT, SLOT)


## Le haut de la page : sous les trois dos, avec de l'air.
func _page_top() -> float:
	return HEADER + SLOT + PAD * 2.0


## Le haut de la fiche du bas — celle qui décrit la case survolée. C'est la
## borne basse des cases, et le dessin comme le test la lisent ici : mesurée
## séparément, l'une des deux finirait par laisser les carrés descendre dessus.
func _fiche_top() -> float:
	return size.y - LINE * 4.0


func _case_rect(position: Vector2i) -> Rect2:
	var origine := Vector2(PAD, _page_top() + LINE * 2.0 + XP_H + PAD)
	return Rect2(
		origine + Vector2(position) * (CASE + CASE_GAP), Vector2(CASE, CASE)
	)


# --------------------------------------------------------------------------


func _draw() -> void:
	if _font == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BACK)
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BORDER, false, 1.0)
	_texte("MANUELS", Vector2(PAD, 11.0), TITLE_SIZE, Color(0.80, 0.77, 0.86))

	for i in Ratelier.EMPLACEMENTS:
		_draw_slot(i)

	var livre := _livre()
	if livre == null:
		_texte(
			"aucun manuel à cet emplacement", Vector2(PAD, _page_top() + 8.0),
			FONT_SIZE, UiPalette.HINT
		)
		return
	_draw_page(livre)

	_texte(
		"[clic] investir     [clic droit] ranger un manuel",
		Vector2(PAD, size.y - 5.0), FONT_SIZE, UiPalette.HINT
	)


func _draw_slot(index: int) -> void:
	var r := _slot_rect(index)
	draw_rect(r, CASE_FOND)
	var item := _player.ratelier.a(index) if _player != null else null
	# Le liseré dit lequel est ouvert : la page dessous est la sienne, et sans ce
	# repère on ne sait pas de quel livre on lit les cases.
	var teinte := UiPalette.BORDER
	if index == _choisi:
		teinte = PLEINE if item != null else ATTENTE
	draw_rect(r, teinte, false, 1.0)

	if item == null:
		return
	var tex := SpriteForge.inventory_icon(
		item.base.kind, Vector2i(int(SLOT) - 8, int(SLOT) - 8), item.base.palier
	)
	if tex != null:
		var taille := tex.get_size()
		draw_texture_rect(tex, Rect2(r.position + (r.size - taille) * 0.5, taille), false)


func _draw_page(livre: Item) -> void:
	var manuel := livre.manuel
	var y := _page_top() + 8.0
	_texte(livre.base.manuel.nom, Vector2(PAD, y), TITLE_SIZE, livre.color())

	var restants := manuel.points_restants()
	var a_placer := "%d point%s à placer" % [restants, "s" if restants > 1 else ""]
	_texte(
		"niveau %d" % manuel.niveau(), Vector2(PAD, y + LINE), FONT_SIZE, UiPalette.LABEL
	)
	_texte(
		a_placer if restants > 0 else "aucun point à placer",
		Vector2(size.x - PAD - 78.0, y + LINE), FONT_SIZE,
		OUVERTE if restants > 0 else UiPalette.LABEL
	)

	# La barre d'expérience du livre. Vide et sans promesse au plafond : une jauge
	# pleine qui ne bougera plus se lit mieux ainsi qu'avec un dénominateur inventé.
	var avancement := manuel.avancement()
	var barre := Rect2(PAD, y + LINE * 1.6, size.x - PAD * 2.0, XP_H)
	draw_rect(barre, XP_FOND)
	if avancement.y > 0:
		var ratio := clampf(float(avancement.x) / float(avancement.y), 0.0, 1.0)
		draw_rect(Rect2(barre.position, Vector2(barre.size.x * ratio, barre.size.y)), XP_PLEIN)
	draw_rect(barre, UiPalette.BORDER, false, 1.0)

	var cases := livre.base.manuel.cases
	for i in cases.size():
		_draw_case(manuel, cases[i], i == _survol_case)

	# La ligne du bas : ce que la case survolée fait vraiment. Les carrés ne
	# portent qu'un compte — à trente-quatre pixels, un nom se tronque et deux
	# cases voisines finissent par annoncer la même chose.
	if _survol_case >= 0 and _survol_case < cases.size():
		_draw_fiche(manuel, cases[_survol_case])


func _draw_case(manuel: Manuel, case: CaseDeManuel, survolee: bool) -> void:
	var r := _case_rect(case.position)
	draw_rect(r, CASE_FOND)

	var competence := case.competence
	if competence == null:
		draw_rect(r, VERROU, false, 1.0)
		return

	var places := manuel.points_de(competence.id)
	var maximum := competence.points_max()
	var teinte := VERROU
	if places >= maximum:
		teinte = PLEINE
	elif manuel.niveau() >= competence.niveau_de_manuel_requis:
		teinte = OUVERTE if manuel.points_restants() > 0 else ATTENTE

	draw_rect(r, teinte, false, 2.0 if survolee else 1.0)

	# Le compte au centre, la seule chose qui tienne à cette taille. Verrouillée,
	# la case annonce ce qu'elle demande plutôt que zéro : « niv. 4 » explique,
	# « 0/5 » laisse croire à une case qu'on a le droit d'ouvrir.
	var libelle := "%d/%d" % [places, maximum]
	if places == 0 and manuel.niveau() < competence.niveau_de_manuel_requis:
		libelle = "niv. %d" % competence.niveau_de_manuel_requis
	var largeur := _font.get_string_size(
		libelle, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE
	).x
	_texte(
		libelle, r.position + Vector2((CASE - largeur) * 0.5, CASE * 0.5 + 3.0),
		FONT_SIZE, TEXTE if teinte != VERROU else UiPalette.LABEL
	)


## Ce que la case survolée donne, calculé par la **même** fonction que le
## lancement : deux calculs séparés divergent d'un arrondi, et c'est l'affichage
## qui passe alors pour un menteur.
func _draw_fiche(manuel: Manuel, case: CaseDeManuel) -> void:
	var competence := case.competence
	if competence == null or _player == null:
		return
	var places := maxi(manuel.points_de(competence.id), 1)
	var degats := competence.degats(places, _player.stats)

	var y := _fiche_top() + LINE
	_texte(competence.nom, Vector2(PAD, y), FONT_SIZE, TEXTE)
	var detail := "%d dégâts %s" % [roundi(degats), DamageType.NAMES[competence.nature]]
	if competence.cout_en_mana > 0.0:
		detail += "   %d mana" % roundi(competence.cout_en_mana)
	_texte(detail, Vector2(PAD, y + LINE), FONT_SIZE, UiPalette.LABEL)


func _texte(texte: String, at: Vector2, taille: int, teinte: Color) -> void:
	draw_string(_font, at, texte, HORIZONTAL_ALIGNMENT_LEFT, -1.0, taille, teinte)
