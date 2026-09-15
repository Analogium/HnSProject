class_name ManuelPanel
extends Control

## Le râtelier et la page du manuel choisi (M) : les trois dos en haut, la page
## dessous. **On n'investit que d'ici**, donc dans un livre étudié : équiper est
## l'engagement. Deux vues de même taille, la grille et l'arbre d'une compétence.

## Ce qu'on jette faute de place, comme le sac : c'est la zone qui le pose au sol.
signal drop_requested(item: Item)

const PAD := 6.0
const HEADER := 15.0
const SLOT := 40.0
const SLOT_GAP := 6.0
const FONT_SIZE := 8
const TITLE_SIZE := 9
const LINE := 10.0

## La barre d'expérience du livre, en haut de sa page.
const XP_H := 5.0

## Une case : de quoi écrire « 3/5 » et garder un liseré lisible.
const CASE := 34.0
const CASE_GAP := 6.0

## Un nœud, plus petit qu'une case, et l'écart où passent les liens. Trois colonnes
## sur deux rangées à droite de la racine.
const NOEUD := 28.0
const NOEUD_GAP := 16.0

## Les états d'une case, lus au liseré **sans lire** le texte. Verrouillée : le
## niveau du livre n'y donne pas encore droit.
const VERROU := Color(0.26, 0.24, 0.31)
## Ouverte, et il reste un point à y mettre : le vert des points à placer.
const OUVERTE := UiPalette.A_PLACER
## Pleine : l'or, « ça compte plus ».
const PLEINE := Color(0.95, 0.82, 0.30)
## Ouverte mais sans point disponible : ni promesse, ni interdit.
const ATTENTE := Color(0.55, 0.53, 0.64)

const CASE_FOND := Color(0.14, 0.13, 0.18, 0.9)
const XP_FOND := Color(0.10, 0.09, 0.13)
## Le bleu de l'expérience du joueur : un livre progresse comme son porteur.
const XP_PLEIN := Hud.FILL
## Mots-clés en bleu acier : dans la couleur d'une nature, « Foudre » se lirait comme
## un type de dégâts.
const MOT_CLE := Color(0.62, 0.72, 0.88)

## Le lien entre deux nœuds, allumé quand la branche est prise.
const LIEN := Color(0.24, 0.23, 0.29)
const LIEN_VIF := Color(0.52, 0.62, 0.55)

## Les pans coupés d'un passif : la forme dit « toujours actif ».
const PAN := 7.0

## La fiche de survol : assez large pour « par projectile   123–456 », pas plus — elle
## couvre le sac.
const FICHE_W := 170.0
const FICHE_PAD := 6.0
const FICHE_GAP := 4.0
## Le nom et les mots-clés, au-dessus des lignes.
const FICHE_ENTETE := LINE * 2.0
const FICHE_SEPARATION := 5.0
## Ce qui manque pour ouvrir : « pas encore », pas une erreur.
const MANQUE := Color(0.92, 0.50, 0.44)

## Les groupes de la fiche, dans l'ordre des questions. `EFFET` : passif et nœud, qui
## n'ont ni coût ni portée.
enum Groupe { ETAT, EFFET, COUT, DEGATS, FORME, ESTIMATION }


## Une ligne de fiche : intitulé à gauche, valeur à droite dans sa couleur.
class LigneDeFiche:
	var groupe: int
	var libelle: String
	var valeur: String
	var teinte: Color

	func _init(p_groupe: int, p_libelle: String, p_valeur: String, p_teinte: Color) -> void:
		groupe = p_groupe
		libelle = p_libelle
		valeur = p_valeur
		teinte = p_teinte


## Une fiche de survol entière, décidée **à un seul endroit** : sous-titre et lignes
## ne peuvent pas se contredire.
class Fiche:
	var titre: String
	## Sous le nom, la sorte : mots-clés, « toujours actif » ou « talent ».
	var sous_titre: String
	var lignes: Array[LigneDeFiche]

	func _init(p_titre: String, p_sous_titre: String, p_lignes: Array[LigneDeFiche]) -> void:
		titre = p_titre
		sous_titre = p_sous_titre
		lignes = p_lignes

var _player: Player
var _font: Font
## L'emplacement ouvert ; zéro, pour montrer quelque chose dès l'ouverture.
var _choisi := 0
## La compétence dont l'arbre est ouvert, ou vide pour la grille. Un identifiant :
## `_case_ouverte()` retombe sur la grille si le livre change.
var _ouverte := ""
var _survol_slot := -1
var _survol_case := -1
## Le nœud survolé dans l'arbre ouvert, et le survol de la racine.
var _survol_noeud := -1
var _survol_racine := false
## Pour ne redessiner que quand elle bouge : la page reste ouverte en combat.
var _exp_affichee := -1


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font
	# Au plus proche voisin : lissée, la trame du pixel art tournerait au gris.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _exit_tree() -> void:
	if visible:
		Game.grab_ui_input(self, false)


## La page et la fiche sont dessinées à la main : à redessiner.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


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

	# Échap referme l'arbre avant la fenêtre : pris dans `_input`, avant le menu de
	# pause, et seulement quand un arbre est ouvert.
	if Touches.enfoncee(event) == KEY_ESCAPE and _case_ouverte() != null:
		_ouverte = ""
		_track(get_local_mouse_position())
		queue_redraw()
		get_viewport().set_input_as_handled()
		return

	# La position de l'événement : vraie au moment du clic, et rejouable dans un test.
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
			_clic_gauche()
		MOUSE_BUTTON_RIGHT:
			_clic_droit()
		_:
			return

	# Re-survolé : le clic a pu changer de vue.
	_track(bouton.position)
	queue_redraw()
	get_viewport().set_input_as_handled()


## Sur un dos : ouvrir le livre. Sur la grille : ouvrir l'arbre, ou placer un point
## dans un passif. Dans l'arbre : placer un point.
func _clic_gauche() -> void:
	if _survol_slot >= 0:
		_choisi = _survol_slot
		# Le livre change : on revient à sa grille.
		_ouverte = ""
		return

	var ouverte := _case_ouverte()
	if ouverte != null:
		if _survol_racine:
			_investir(ouverte.competence.id)
		elif _survol_noeud >= 0 and _survol_noeud < ouverte.talents.size():
			_investir(ouverte.talents[_survol_noeud].id)
		return

	var case := _case_survolee()
	if case == null:
		return
	if case.competence != null:
		_ouverte = case.competence.id
	else:
		_investir(case.passif.id)


## Le pendant du clic gauche : un point de moins là où il en ajoute un. Sur un dos,
## ranger le livre ; dans le vide de l'arbre, revenir à la grille.
func _clic_droit() -> void:
	if _survol_slot >= 0:
		_ranger(_survol_slot)
		return
	var ouverte := _case_ouverte()
	if ouverte == null:
		var case := _case_survolee()
		if case != null:
			_reprendre(case.identifiant())
		return
	if _survol_racine:
		_reprendre(ouverte.competence.id)
	elif _survol_noeud >= 0 and _survol_noeud < ouverte.talents.size():
		_reprendre(ouverte.talents[_survol_noeud].id)
	else:
		_ouverte = ""


## Hors de la fenêtre, le clic reste au panneau voisin.
func _possede_le_clic(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point)


## Le livre dont la page est ouverte, ou null.
func _livre() -> Item:
	return _player.ratelier.a(_choisi) if _player != null else null


## L'archétype ouvert, ou null : les règles refusent alors tout.
func _archetype() -> ManuelArchetype:
	var livre := _livre()
	return livre.base.manuel if livre != null else null


## La case dont l'arbre est ouvert, ou null. **Relue à chaque fois** : le livre a pu
## être rangé ou remplacé, et la vue retombe seule sur la grille.
func _case_ouverte() -> CaseDeManuel:
	if _ouverte.is_empty():
		return null
	var livre := _livre()
	return livre.base.manuel.case_de(_ouverte) if livre != null else null


## La case de la grille sous le curseur, ou null.
func _case_survolee() -> CaseDeManuel:
	var livre := _livre()
	if livre == null or _survol_case < 0:
		return null
	var cases := livre.base.manuel.cases
	return cases[_survol_case] if _survol_case < cases.size() else null


## Les conditions sont dans `Manuel`, le recalcul chez le joueur.
func _investir(identifiant: String) -> void:
	if _player != null:
		_player.investir(_choisi, identifiant)


## Un point de moins ; `Manuel` dit quand.
func _reprendre(identifiant: String) -> void:
	if _player != null:
		_player.reprendre(_choisi, identifiant)


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
	var noeud := -1
	var racine := false
	var ouverte := _case_ouverte()
	if ouverte != null:
		racine = _racine_rect().has_point(point)
		for i in ouverte.talents.size():
			if _noeud_rect(ouverte.talents[i].position).has_point(point):
				noeud = i
				break
	else:
		var livre := _livre()
		if livre != null:
			var cases := livre.base.manuel.cases
			for i in cases.size():
				if _case_rect(cases[i].position).has_point(point):
					case = i
					break

	if (
		slot == _survol_slot and case == _survol_case
		and noeud == _survol_noeud and racine == _survol_racine
	):
		return
	_survol_slot = slot
	_survol_case = case
	_survol_noeud = noeud
	_survol_racine = racine
	queue_redraw()


func _slot_rect(index: int) -> Rect2:
	return Rect2(PAD + float(index) * (SLOT + SLOT_GAP), HEADER, SLOT, SLOT)


## Le haut de la page : sous les trois dos, avec de l'air.
func _page_top() -> float:
	return HEADER + SLOT + PAD * 2.0


## Le haut de la ligne d'aide, borne basse des cases : lu ici par le dessin et le test.
func _aide_top() -> float:
	return size.y - LINE - 5.0


## L'origine commune de la grille et de l'arbre, sous l'en-tête.
func _origine() -> Vector2:
	return Vector2(PAD, _page_top() + LINE * 2.0 + XP_H + PAD)


func _case_rect(position: Vector2i) -> Rect2:
	return Rect2(_origine() + Vector2(position) * (CASE + CASE_GAP), Vector2(CASE, CASE))


## La racine de l'arbre : la case de la compétence, à gauche, centrée sur les deux
## rangées de nœuds.
func _racine_rect() -> Rect2:
	var bande := NOEUD * 2.0 + NOEUD_GAP
	return Rect2(_origine() + Vector2(0.0, (bande - CASE) * 0.5), Vector2(CASE, CASE))


func _noeud_rect(position: Vector2i) -> Rect2:
	var depart := _origine() + Vector2(CASE + NOEUD_GAP + 4.0, 0.0)
	return Rect2(
		depart + Vector2(position) * (NOEUD + NOEUD_GAP), Vector2(NOEUD, NOEUD)
	)


# --------------------------------------------------------------------------


func _draw() -> void:
	if _font == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BACK)
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BORDER, false, 1.0)
	_texte(Textes.t("MANUELS"), Vector2(PAD, 11.0), TITLE_SIZE, UiPalette.TITRE)

	for i in Ratelier.EMPLACEMENTS:
		_draw_slot(i)

	var livre := _livre()
	if livre == null:
		_texte(
			Textes.t("aucun manuel à cet emplacement"), Vector2(PAD, _page_top() + 8.0),
			FONT_SIZE, UiPalette.HINT
		)
		return

	var ouverte := _case_ouverte()
	var fiche: Fiche = null
	var ancre := Rect2()
	if ouverte == null:
		_draw_entete(livre, livre.base.manuel.nom_affiche(), livre.color())
		for case in livre.base.manuel.cases:
			_draw_case(livre.manuel, case, _case_rect(case.position), case == _case_survolee())
		_texte(
			Textes.t("[clic] ouvrir ou +1     [clic droit] -1 ou ranger"),
			Vector2(PAD, _aide_top() + LINE), FONT_SIZE, UiPalette.HINT
		)
		var survolee := _case_survolee()
		if survolee != null:
			fiche = _fiche_de_case(livre.manuel, survolee)
			ancre = _case_rect(survolee.position)
	else:
		# Le chevron dit d'où l'on revient ; le clic droit fait le retour.
		_draw_entete(livre, "‹ %s" % ouverte.competence.nom_affiche(), UiPalette.TEXTE)
		_draw_arbre(livre.manuel, livre.base.manuel, ouverte)
		_texte(
			Textes.t("[clic] +1     [clic droit] -1     [échap] retour"),
			Vector2(PAD, _aide_top() + LINE), FONT_SIZE, UiPalette.HINT
		)
		if _survol_racine:
			fiche = _fiche_de_competence(livre.manuel, ouverte.competence)
			ancre = _racine_rect()
		elif _survol_noeud >= 0 and _survol_noeud < ouverte.talents.size():
			var noeud := ouverte.talents[_survol_noeud]
			fiche = _fiche_de_noeud(livre.manuel, ouverte, noeud)
			ancre = _noeud_rect(noeud.position)

	# En dernier : la fiche passe par-dessus tout, le sac compris.
	if fiche != null:
		_draw_fiche(fiche, ancre)


func _draw_slot(index: int) -> void:
	var r := _slot_rect(index)
	draw_rect(r, CASE_FOND)
	var item := _player.ratelier.a(index) if _player != null else null
	# Le liseré dit quel livre est ouvert.
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


## Titre, niveau, points restants et barre d'expérience, **les mêmes dans les deux
## vues** : on doit savoir dans l'arbre si l'on a de quoi payer.
func _draw_entete(livre: Item, titre: String, teinte: Color) -> void:
	var manuel := livre.manuel
	var y := _page_top() + 8.0
	_texte(titre, Vector2(PAD, y), TITLE_SIZE, teinte)

	var restants := manuel.points_restants()
	# Le pluriel par la traduction ; zéro a sa propre phrase.
	var a_placer := Textes.tn(
		"{points} point à placer", "{points} points à placer", restants
	).format({"points": restants})
	_texte(
		Textes.t("niveau %d") % manuel.niveau(), Vector2(PAD, y + LINE),
		FONT_SIZE, UiPalette.LABEL
	)
	_texte(
		a_placer if restants > 0 else Textes.t("aucun point à placer"),
		Vector2(size.x - PAD - 78.0, y + LINE), FONT_SIZE,
		OUVERTE if restants > 0 else UiPalette.LABEL
	)

	# Vide au plafond : pas de dénominateur inventé.
	var avancement := manuel.avancement()
	var barre := Rect2(PAD, y + LINE * 1.6, size.x - PAD * 2.0, XP_H)
	draw_rect(barre, XP_FOND)
	if avancement.y > 0:
		var ratio := clampf(float(avancement.x) / float(avancement.y), 0.0, 1.0)
		draw_rect(Rect2(barre.position, Vector2(barre.size.x * ratio, barre.size.y)), XP_PLEIN)
	draw_rect(barre, UiPalette.BORDER, false, 1.0)


## Une case ou une racine d'arbre : le rectangle est passé, la même case se dessinant
## à deux endroits.
func _draw_case(manuel: Manuel, case: CaseDeManuel, r: Rect2, survolee: bool) -> void:
	var passif := case.passif
	var identifiant := case.identifiant()
	if identifiant.is_empty():
		draw_rect(r, CASE_FOND)
		draw_rect(r, VERROU, false, 1.0)
		return

	var places := manuel.points_de(identifiant)
	var maximum := case.points_max()
	var teinte := _teinte(manuel, case.niveau_requis() <= manuel.niveau(), places, maximum)
	var epaisseur := 2.0 if survolee else 1.0

	# Un passif se distingue par ses pans coupés.
	if passif != null:
		draw_colored_polygon(_pans(r), CASE_FOND)
		draw_polyline(_pans(r, true), teinte, epaisseur)
	else:
		draw_rect(r, CASE_FOND)

	# L'icône d'abord, le liseré par-dessus : c'est lui qui dit l'état.
	_draw_icone(r, case, teinte == VERROU)
	if passif == null:
		draw_rect(r, teinte, false, epaisseur)
		# Le chevron d'arbre en bas à gauche, à l'opposé du compte.
		if not case.talents.is_empty():
			_draw_chevron(r.position + Vector2(4.0, r.size.y - 5.0), MOT_CLE)

	# Verrouillée, la case annonce « niv. 4 » plutôt que « 0/5 ».
	var libelle := "%d/%d" % [places, maximum]
	if places == 0 and teinte == VERROU:
		libelle = Textes.t("niv. %d") % case.niveau_requis()
	# Rentrée dans les pans coupés : au coin, la plaque dépassait (vu sur capture).
	_draw_compte(
		r.grow(-PAN * 0.5) if passif != null else r,
		libelle, UiPalette.TEXTE if teinte != VERROU else UiPalette.LABEL, FONT_SIZE
	)


## Racine, liens puis nœuds : les nœuds couvrent les bouts des liens.
func _draw_arbre(manuel: Manuel, arch: ManuelArchetype, case: CaseDeManuel) -> void:
	var racine := _racine_rect()
	for noeud in case.talents:
		var r := _noeud_rect(noeud.position)
		var depuis := racine if noeud.parent.is_empty() else _noeud_rect(
			case.noeud_de(noeud.parent).position
		)
		# Le lien s'allume quand le nœud porte un point.
		var vif := manuel.points_de(noeud.id) > 0
		draw_line(
			Vector2(depuis.end.x, depuis.get_center().y),
			Vector2(r.position.x, r.get_center().y),
			LIEN_VIF if vif else LIEN, 1.0
		)

	_draw_case(manuel, case, racine, _survol_racine)
	for i in case.talents.size():
		_draw_noeud(manuel, arch, case.talents[i], i == _survol_noeud)


func _draw_noeud(
	manuel: Manuel, arch: ManuelArchetype, noeud: NoeudDeTalent, survole: bool
) -> void:
	var r := _noeud_rect(noeud.position)
	var places := manuel.points_de(noeud.id)
	var teinte := _teinte(manuel, manuel.est_ouvert(arch, noeud.id), places, noeud.points_max)
	draw_rect(r, CASE_FOND)
	draw_rect(r, teinte, false, 2.0 if survole else 1.0)

	# Pastille de la nature d'arrivée d'une conversion : seul effet lisible en couleur.
	if noeud.convertit():
		draw_circle(r.position + Vector2(5.0, 5.0), 2.0, DamageType.COLORS[noeud.convertit_vers])

	_draw_compte(
		r, "%d/%d" % [places, noeud.points_max],
		UiPalette.TEXTE if teinte != VERROU else UiPalette.LABEL, FONT_SIZE
	)


## **Le seul endroit** qui traduit un état en couleur, cases et nœuds.
func _teinte(manuel: Manuel, ouvert: bool, places: int, maximum: int) -> Color:
	if places >= maximum:
		return PLEINE
	if not ouvert:
		return VERROU
	return OUVERTE if manuel.points_restants() > 0 else ATTENTE


## `boucle` ferme le contour.
static func _pans(r: Rect2, boucle := false) -> PackedVector2Array:
	var pts := PackedVector2Array([
		Vector2(r.position.x + PAN, r.position.y),
		Vector2(r.end.x - PAN, r.position.y),
		Vector2(r.end.x, r.position.y + PAN),
		Vector2(r.end.x, r.end.y - PAN),
		Vector2(r.end.x - PAN, r.end.y),
		Vector2(r.position.x + PAN, r.end.y),
		Vector2(r.position.x, r.end.y - PAN),
		Vector2(r.position.x, r.position.y + PAN),
	])
	if boucle:
		pts.append(pts[0])
	return pts


static func _chevron(at: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		at + Vector2(0.0, -2.5), at + Vector2(2.0, 0.0), at + Vector2(0.0, 2.5)
	])


func _draw_chevron(at: Vector2, teinte: Color) -> void:
	draw_polyline(_chevron(at), teinte, 1.0)


## L'icône, **assombrie tant qu'elle est verrouillée** ; sans image, la case reste
## utilisable.
func _draw_icone(r: Rect2, case: CaseDeManuel, verrouillee: bool) -> void:
	var tex := IconeDeCompetence.texture(case.competence)
	if tex == null and case.passif != null:
		tex = IconeDeCompetence.depuis(case.passif.id, case.passif.icone)
	if tex == null:
		return
	var taille := tex.get_size() * float(IconeDeCompetence.facteur(tex, r.size.x))
	draw_texture_rect(
		tex, Rect2(r.position + (r.size - taille) * 0.5, taille), false,
		Color(0.42, 0.40, 0.48) if verrouillee else Color.WHITE
	)


## Le compte, **en bas à droite sur une plaque sombre** : lisible quel que soit le
## dessin derrière.
func _draw_compte(r: Rect2, libelle: String, teinte: Color, taille: int) -> void:
	var largeur := _font.get_string_size(
		libelle, HORIZONTAL_ALIGNMENT_LEFT, -1.0, taille
	).x + 4.0
	# Décalée d'un pixel pour ne pas manger le liseré.
	var plaque := Rect2(r.end - Vector2(largeur + 1.0, LINE + 1.0), Vector2(largeur, LINE))
	draw_rect(plaque, Color(0.06, 0.05, 0.09, 0.82))
	_texte(libelle, plaque.position + Vector2(2.0, LINE - 2.0), taille, teinte)


## La fiche de la case survolée : à trente-quatre pixels, un nom se tronque.
func _draw_fiche(fiche: Fiche, ancre: Rect2) -> void:
	var r := _fiche_rect(ancre, _hauteur_de_fiche(fiche.lignes))
	draw_rect(r, UiPalette.TIP_BACK)
	draw_rect(r, UiPalette.BORDER, false, 1.0)

	var gauche := r.position.x + FICHE_PAD
	var largeur := r.size.x - FICHE_PAD * 2.0
	var y := r.position.y + FICHE_PAD
	_texte(fiche.titre, Vector2(gauche, y + LINE - 1.0), TITLE_SIZE, UiPalette.TEXTE)
	# Ce qui peut l'améliorer : ici plutôt que sur la barre, qui sert à lancer.
	_texte(fiche.sous_titre, Vector2(gauche, y + LINE * 2.0 - 2.0), FONT_SIZE, MOT_CLE)
	y += FICHE_ENTETE

	for i in fiche.lignes.size():
		if _ouvre_un_groupe(fiche.lignes, i):
			draw_rect(Rect2(gauche, roundf(y + FICHE_SEPARATION * 0.5), largeur, 1.0), UiPalette.BORDER)
			y += FICHE_SEPARATION
		var ligne := fiche.lignes[i]
		var base := y + LINE - 2.0
		_texte(ligne.libelle, Vector2(gauche, base), FONT_SIZE, UiPalette.HINT)
		draw_string(
			_font, Vector2(gauche, base), ligne.valeur,
			HORIZONTAL_ALIGNMENT_RIGHT, largeur, FONT_SIZE, ligne.teinte
		)
		y += LINE


## La fiche de la case, quelle que soit sa sorte.
func _fiche_de_case(manuel: Manuel, case: CaseDeManuel) -> Fiche:
	if case.competence != null:
		return _fiche_de_competence(manuel, case.competence)
	return _fiche_de_passif(manuel, case.passif) if case.passif != null else null


## Chaque caractéristique de la compétence, **tous les nombres par
## `Player.resoudre()`**, le chemin du lancer. Une ligne qui ne dit rien ne s'écrit
## pas ; sans point placé, ceux du premier.
func _fiche_de_competence(manuel: Manuel, competence: Competence) -> Fiche:
	var places := manuel.points_de(competence.id)
	var geste := _player.resoudre(competence, maxi(places, 1))
	var projectile := geste.mots_cles.has(MotsCles.PROJECTILE)
	var out: Array[LigneDeFiche] = []

	out.append(LigneDeFiche.new(
		Groupe.ETAT, Textes.t("points"), "%d / %d" % [places, competence.points_max()],
		UiPalette.TEXTE
	))
	if manuel.niveau() < competence.niveau_de_manuel_requis:
		out.append(LigneDeFiche.new(
			Groupe.ETAT, Textes.t("verrouillée"),
			Textes.t("niveau %d du manuel") % competence.niveau_de_manuel_requis,
			MANQUE
		))
	if places == 0:
		out.append(_ligne_du_premier_point())

	if geste.cout_en_mana > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.COUT, Textes.t("coût"),
			Textes.t("%d mana") % roundi(geste.cout_en_mana), UiPalette.TEXTE
		))
	if geste.intervalle > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.COUT, Textes.t("recharge"), "%.2f s" % geste.intervalle, UiPalette.TEXTE
		))

	if geste.degats_de_base > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.DEGATS, Textes.t("de base"),
			_en_nature(geste.degats_de_base, geste.degats_de_base, competence.nature),
			DamageType.COLORS[competence.nature]
		))
	for nature in DamageType.Kind.size():
		if geste.ajoutes_max[nature] > 0.0:
			out.append(LigneDeFiche.new(
				Groupe.DEGATS, Textes.t("ajoutés"),
				_en_nature(geste.ajoutes_min[nature], geste.ajoutes_max[nature], nature),
				DamageType.COLORS[nature]
			))
	# Ce qu'une conversion a déplacé, dans la couleur d'arrivée.
	for nature in DamageType.Kind.size():
		if geste.convertis[nature] > 0.0:
			out.append(LigneDeFiche.new(
				Groupe.DEGATS, Textes.t("converti"),
				_part_convertie(geste.convertis[nature], nature), DamageType.COLORS[nature]
			))
	if not is_equal_approx(geste.facteur_d_attribut, 1.0):
		out.append(LigneDeFiche.new(
			Groupe.DEGATS, StatMod.nom(competence.attribut),
			_accroissement(geste.facteur_d_attribut), UiPalette.TEXTE
		))
	if not is_equal_approx(geste.accroissement, 1.0):
		out.append(LigneDeFiche.new(
			Groupe.DEGATS, Textes.t("dégâts accrus"),
			_accroissement(geste.accroissement), UiPalette.TEXTE
		))
	if geste.total_max() > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.DEGATS, Textes.t("par projectile") if projectile else Textes.t("par coup"),
			StatsDeCompetence.fourchette_lisible(geste.total_min(), geste.total_max()), PLEINE
		))

	if projectile:
		out.append(LigneDeFiche.new(
			Groupe.FORME, Textes.t("projectiles"), str(geste.nombre_de_projectiles()),
			UiPalette.TEXTE
		))
		if geste.dispersion_en_degres > 0.0:
			out.append(LigneDeFiche.new(
				Groupe.FORME, Textes.t("écart"), "%d°" % roundi(geste.dispersion_en_degres),
				UiPalette.TEXTE
			))
		if geste.vitesse_de_projectile > 0.0:
			out.append(LigneDeFiche.new(
				# Un contexte : « vitesse » est aussi le déplacement.
				Groupe.FORME, Textes.t("vitesse", "fiche de compétence"),
				"%d px/s" % roundi(geste.vitesse_de_projectile), UiPalette.TEXTE
			))
	# Les autres formes, lues sur leurs valeurs : la page ne connaît pas les formes.
	if geste.nombre_de_cibles() > 1:
		out.append(LigneDeFiche.new(
			Groupe.FORME, Textes.t("cibles"), str(geste.nombre_de_cibles()), UiPalette.TEXTE
		))
	if geste.coups > 1:
		out.append(LigneDeFiche.new(Groupe.FORME, Textes.t("coups"), str(geste.coups), UiPalette.TEXTE))
	if geste.duree > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.FORME, Textes.t("durée"), "%.1f s" % geste.duree, UiPalette.TEXTE
		))
	if geste.rayon > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.FORME, Textes.t("rayon"), "%d px" % roundi(geste.rayon), UiPalette.TEXTE
		))
	if geste.periode > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.FORME, Textes.t("toutes les"), "%.2f s" % geste.periode, UiPalette.TEXTE
		))
	if geste.maximum_simultane() > 0:
		out.append(LigneDeFiche.new(
			Groupe.FORME, Textes.t("en même temps"), str(geste.maximum_simultane()), UiPalette.TEXTE
		))
	if geste.brulure > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.FORME, Textes.t("brûlure"),
			"%s %s" % [StatMod.pourcentage(roundi(geste.brulure * 100.0)), Textes.t("PV/s")], MANQUE
		))

	# Ce qu'elle inflige, pour comparer deux sorts ; une aura n'a que la seconde.
	var par_lancer := geste.moyenne_par_lancer()
	var par_seconde := geste.moyenne_par_seconde()
	if par_lancer > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.ESTIMATION, Textes.t("moyenne par lancer"), str(roundi(par_lancer)), PLEINE
		))
	if par_seconde > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.ESTIMATION, Textes.t("par seconde"), str(roundi(par_seconde)), PLEINE
		))
	if par_lancer > 0.0 or par_seconde > 0.0:
		# Ce que les moyennes supposent, en note sous elles.
		out.append(LigneDeFiche.new(
			Groupe.ESTIMATION, Textes.t("si tout touche, avant défenses"), "", UiPalette.HINT
		))
	return Fiche.new(competence.nom_affiche(), geste.libelle_des_mots_cles(), out)


## Ce qu'un passif donne à ses points ; son sous-titre dit « toujours actif ».
func _fiche_de_passif(manuel: Manuel, passif: Passif) -> Fiche:
	var places := manuel.points_de(passif.id)
	var out: Array[LigneDeFiche] = []
	out.append(LigneDeFiche.new(
		Groupe.ETAT, Textes.t("points"), "%d / %d" % [places, passif.points_max],
		UiPalette.TEXTE
	))
	if manuel.niveau() < passif.niveau_de_manuel_requis:
		out.append(LigneDeFiche.new(
			Groupe.ETAT, Textes.t("verrouillé"),
			Textes.t("niveau %d du manuel") % passif.niveau_de_manuel_requis, MANQUE
		))
	if places == 0:
		out.append(_ligne_du_premier_point())
	out.append_array(_lignes_d_effet(passif.mods(maxi(places, 1))))
	return Fiche.new(passif.nom_affiche(), Textes.t("toujours actif"), out)


## Ce qu'un nœud change, et ce qu'il demande — lu sur le manuel, jamais recalculé.
func _fiche_de_noeud(manuel: Manuel, case: CaseDeManuel, noeud: NoeudDeTalent) -> Fiche:
	var places := manuel.points_de(noeud.id)
	var out: Array[LigneDeFiche] = []
	out.append(LigneDeFiche.new(
		Groupe.ETAT, Textes.t("points"), "%d / %d" % [places, noeud.points_max],
		UiPalette.TEXTE
	))
	if not manuel.est_ouvert(_archetype(), noeud.id):
		out.append(LigneDeFiche.new(
			Groupe.ETAT, Textes.t("demande"), _ce_qu_il_demande(manuel, case, noeud), MANQUE
		))
	if places == 0:
		out.append(_ligne_du_premier_point())

	out.append_array(_lignes_d_effet(noeud.mods(maxi(places, 1))))
	if noeud.convertit():
		out.append(LigneDeFiche.new(
			Groupe.EFFET, Textes.t("converti"),
			_part_convertie(noeud.conversion(maxi(places, 1)), noeud.convertit_vers),
			DamageType.COLORS[noeud.convertit_vers]
		))
	# Le mot-clé donné : il fait mordre l'équipement de la nature d'arrivée.
	for id in noeud.mots_cles_ajoutes:
		out.append(LigneDeFiche.new(
			Groupe.EFFET, Textes.t("mot-clé"), MotsCles.libelle(id), MOT_CLE
		))
	return Fiche.new(noeud.nom_affiche(), Textes.t("talent"), out)


## Le parent vide d'abord, sinon les points de la compétence.
func _ce_qu_il_demande(manuel: Manuel, case: CaseDeManuel, noeud: NoeudDeTalent) -> String:
	if not noeud.parent.is_empty() and manuel.points_de(noeud.parent) <= 0:
		var parent := case.noeud_de(noeud.parent)
		return Textes.t("le talent « {nom} »").format({"nom": parent.nom_affiche()})
	# « dans la compétence » et non son nom, que l'en-tête écrit déjà : il débordait
	# (mesuré par `test_largeurs`).
	return Textes.tn(
		"{points} point dans la compétence", "{points} points dans la compétence",
		noeud.points_requis
	).format({"points": noeud.points_requis})


## Par la **même fonction que l'infobulle d'un objet**.
func _lignes_d_effet(mods: Array[StatMod]) -> Array[LigneDeFiche]:
	var out: Array[LigneDeFiche] = []
	for m in mods:
		out.append(LigneDeFiche.new(
			Groupe.EFFET, StatMod.nom(m.stat, m.portee), m.valeur_lisible(), UiPalette.TEXTE
		))
	return out


## Une case vide annonce les nombres du premier point.
func _ligne_du_premier_point() -> LigneDeFiche:
	return LigneDeFiche.new(
		Groupe.ETAT, Textes.t("nombres du premier point"), "", UiPalette.TEXTE
	)


static func _ouvre_un_groupe(lignes: Array[LigneDeFiche], index: int) -> bool:
	return index == 0 or lignes[index].groupe != lignes[index - 1].groupe


## Mesurée sur les lignes mêmes que le dessin écrit.
func _hauteur_de_fiche(lignes: Array[LigneDeFiche]) -> float:
	var h := FICHE_PAD * 2.0 + FICHE_ENTETE + LINE * float(lignes.size())
	for i in lignes.size():
		if _ouvre_un_groupe(lignes, i):
			h += FICHE_SEPARATION
	return h


## À droite de ce qu'elle décrit, **tenue dans le cadrage** au-dessus du HUD ; à
## gauche quand la droite manque.
func _fiche_rect(ancre: Rect2, hauteur: float) -> Rect2:
	var ecran := Vector2(Settings.taille_de_base())
	var x := size.x + FICHE_GAP
	if global_position.x + x + FICHE_W > ecran.x:
		x = -FICHE_GAP - FICHE_W
	var plancher := Hud.haut_des_jauges(ecran.y) - global_position.y
	var y := minf(ancre.position.y, plancher - hauteur)
	return Rect2(x, maxf(y, -global_position.y), FICHE_W, hauteur)


## « 3–7 froid », ou « 23 foudre » quand les deux bornes s'arrondissent au même
## nombre.
static func _en_nature(bas: float, haut: float, nature: int) -> String:
	return "%s %s" % [StatsDeCompetence.fourchette_lisible(bas, haut), DamageType.nom(nature)]


## « 60 % en feu » : la part d'un coup qu'une conversion emmène, et où.
static func _part_convertie(part: float, nature: int) -> String:
	return Textes.t("{part} en {nature}").format({
		"part": StatMod.pourcentage(roundi(part * 100.0)), "nature": DamageType.nom(nature)
	})


## « +40 % », par **la même fonction** qu'un objet.
static func _accroissement(facteur: float) -> String:
	return StatMod.value_label("", StatMod.Mode.PERCENT, (facteur - 1.0) * 100.0)


func _texte(texte: String, at: Vector2, taille: int, teinte: Color) -> void:
	draw_string(_font, at, texte, HORIZONTAL_ALIGNMENT_LEFT, -1.0, taille, teinte)
