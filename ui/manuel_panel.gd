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
##
## **La page a deux vues** depuis le jalon 10 : la grille des cases, et l'arbre
## d'une compétence ouverte. La fenêtre ne change pas de taille — 210 × 196 —
## donc les deux ne peuvent pas tenir ensemble, et une bande qui suivrait le
## survol changerait de contenu pendant qu'on traverse la grille pour aller
## cliquer un nœud.

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

## Un nœud d'arbre, et l'écart entre deux. Plus petit qu'une case — un nœud est
## un détail d'une compétence, pas une compétence — et l'écart est large parce
## que c'est **dedans** que passent les liens de parenté.
##
## Trois colonnes et deux rangées tiennent à droite de la racine, pas plus : les
## arbres du jeu en ont trois nœuds, et la troisième colonne est la place du
## quatrième.
const NOEUD := 28.0
const NOEUD_GAP := 16.0

## Les trois états d'une case, qui doivent se distinguer **sans lire** : le
## liseré fait la différence, pas le texte.
## Verrouillée : le niveau du livre n'y donne pas encore droit.
const VERROU := Color(0.26, 0.24, 0.31)
## Ouverte, et il reste un point à y mettre : le vert des points à placer.
const OUVERTE := UiPalette.A_PLACER
## Pleine : l'or, qui dans ce jeu veut dire « ça compte plus que d'habitude ».
const PLEINE := Color(0.95, 0.82, 0.30)
## Ouverte mais sans point disponible : ni promesse, ni interdit.
const ATTENTE := Color(0.55, 0.53, 0.64)

const CASE_FOND := Color(0.14, 0.13, 0.18, 0.9)
const XP_FOND := Color(0.10, 0.09, 0.13)
## Le bleu de la barre d'expérience du joueur : un livre progresse comme son
## porteur, et l'œil doit le reconnaître.
const XP_PLEIN := Hud.FILL
## Les mots-clés de la fiche : un bleu acier, ni le gris des nombres ni la couleur
## d'une nature — « Foudre » écrit en violet se lirait comme un type de dégâts, et
## non comme ce qui peut améliorer la compétence.
const MOT_CLE := Color(0.62, 0.72, 0.88)

## Le lien de parenté entre deux nœuds, éteint puis allumé : un trait qui ne
## change pas ne dit pas si la branche est prise.
const LIEN := Color(0.24, 0.23, 0.29)
const LIEN_VIF := Color(0.52, 0.62, 0.55)

## Les pans coupés d'une case de passif : c'est **la forme** qui dit « toujours
## actif », parce que la couleur est déjà prise par l'état de la case.
const PAN := 7.0

## La fiche de la case survolée, posée à côté de la page. Assez large pour
## « par projectile   123–456 » sans que l'intitulé touche la valeur, et pas plus :
## elle couvre le sac quand il est ouvert.
const FICHE_W := 170.0
const FICHE_PAD := 6.0
const FICHE_GAP := 4.0
## Le nom et les mots-clés, au-dessus des lignes.
const FICHE_ENTETE := LINE * 2.0
const FICHE_SEPARATION := 5.0
## Ce qui manque pour ouvrir la case : un rouge doux, qui dit « pas encore » sans
## crier à l'erreur.
const MANQUE := Color(0.92, 0.50, 0.44)

## Les groupes de la fiche, dans l'ordre où l'on se pose les questions : puis-je
## la prendre, que coûte-t-elle, combien frappe-t-elle, comment part-elle, et ce
## que tout cela donne. `EFFET` est celui d'un passif et d'un nœud, qui n'ont ni
## coût ni portée : ce qu'ils donnent, et rien d'autre.
enum Groupe { ETAT, EFFET, COUT, DEGATS, TIR, ESTIMATION }


## Une ligne de la fiche : un intitulé à gauche, une valeur alignée à droite dans
## sa couleur — celle de la nature, pour une ligne de dégâts.
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


## Une fiche de survol entière : son titre, la ligne qui dit ce que c'est, et ses
## lignes. Une classe et non trois valeurs rendues séparément, parce que ce qu'une
## fiche contient se décide **à un seul endroit** — sinon le sous-titre finirait
## par parler d'autre chose que les lignes en dessous.
class Fiche:
	var titre: String
	## Ce que la case est, sous son nom : les mots-clés d'une compétence,
	## « toujours actif » pour un passif, « talent » pour un nœud. Toujours dans
	## la même couleur — c'est la ligne qui dit la sorte, pas une valeur.
	var sous_titre: String
	var lignes: Array[LigneDeFiche]

	func _init(p_titre: String, p_sous_titre: String, p_lignes: Array[LigneDeFiche]) -> void:
		titre = p_titre
		sous_titre = p_sous_titre
		lignes = p_lignes

var _player: Player
var _font: Font
## L'emplacement dont la page est ouverte. Zéro par défaut : la fenêtre montre
## quelque chose dès l'ouverture plutôt que d'attendre un clic.
var _choisi := 0
## L'identifiant de la compétence dont l'arbre est ouvert, ou vide pour la
## grille. Un identifiant et non une case : le livre choisi peut changer sous
## nos pieds — un clic droit sur son dos le range — et c'est `_case_ouverte()`
## qui retombe alors sur la grille, sans rien à remettre en ordre.
var _ouverte := ""
var _survol_slot := -1
var _survol_case := -1
## L'index du nœud survolé dans l'arbre ouvert, et le survol de la racine, qui
## est la case de la compétence elle-même.
var _survol_noeud := -1
var _survol_racine := false
## L'expérience du livre affiché à la dernière image, pour ne redessiner que
## lorsqu'elle bouge — la page reste ouverte pendant qu'on se bat.
var _exp_affichee := -1


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font
	# Au plus proche voisin : une icône de vingt-quatre pixels dans une case de
	# trente-quatre serait lissée par défaut, et la trame du pixel art deviendrait
	# une bouillie grise.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _exit_tree() -> void:
	if visible:
		Game.grab_ui_input(self, false)


## La langue a changé : la page et la fiche sont dessinées à la main, donc rien
## n'y bougerait avant le prochain survol.
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

	# Échap referme l'arbre avant la fenêtre. Pris ici — dans `_input`, qui passe
	# avant le `_unhandled_input` du menu de pause — et seulement quand un arbre
	# est ouvert : sur la grille, Échap doit continuer d'ouvrir le menu.
	if Touches.enfoncee(event) == KEY_ESCAPE and _case_ouverte() != null:
		_ouverte = ""
		_track(get_local_mouse_position())
		queue_redraw()
		get_viewport().set_input_as_handled()
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
			_clic_gauche()
		MOUSE_BUTTON_RIGHT:
			_clic_droit()
		_:
			return

	# Re-survolé après coup : le clic a pu changer de vue, et ce qui est sous le
	# curseur n'est plus la même chose — sans ça la fiche montrée serait celle de
	# la vue qu'on vient de quitter, jusqu'au prochain mouvement de souris.
	_track(bouton.position)
	queue_redraw()
	get_viewport().set_input_as_handled()


## Sur un dos : ouvrir ce livre. Sur la grille : ouvrir l'arbre d'une compétence,
## ou placer un point dans un passif — un passif n'a rien à orienter, donc rien à
## ouvrir. Dans l'arbre : placer un point.
func _clic_gauche() -> void:
	if _survol_slot >= 0:
		_choisi = _survol_slot
		# Le livre change, son arbre n'a plus de sens : la grille du nouveau est
		# ce qu'on veut voir.
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


## Sur un dos : ranger le livre. Dans l'arbre : reprendre un point d'un nœud, ou
## revenir à la grille quand le clic tombe à côté — le geste de retour est donc
## le même que celui qui range, et il n'y a pas une touche de plus à connaître.
func _clic_droit() -> void:
	if _survol_slot >= 0:
		_ranger(_survol_slot)
		return
	var ouverte := _case_ouverte()
	if ouverte == null:
		return
	if _survol_noeud >= 0 and _survol_noeud < ouverte.talents.size():
		_reprendre(ouverte.talents[_survol_noeud].id)
	else:
		_ouverte = ""


## Hors de la fenêtre, le clic ne nous appartient pas : il doit rester
## disponible pour le panneau ouvert à côté. Sans cette règle, deux fenêtres
## ouvertes en même temps et une seule répond.
func _possede_le_clic(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point)


## Le livre dont la page est ouverte, ou null.
func _livre() -> Item:
	return _player.ratelier.a(_choisi) if _player != null else null


## Le contenu du livre ouvert, ou null : ce que les règles du manuel demandent en
## argument. Nul, elles refusent tout — et la page dessine un emplacement vide.
func _archetype() -> ManuelArchetype:
	var livre := _livre()
	return livre.base.manuel if livre != null else null


## La case dont l'arbre est ouvert, ou null pour la grille.
##
## **Relue à chaque fois plutôt que retenue** : le livre choisi peut avoir été
## rangé, ou remplacé par un autre qui n'enseigne pas cette compétence. La vue
## retombe alors sur la grille toute seule, au lieu de dessiner les nœuds d'un
## livre qui n'est plus là.
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


## Un point de plus. Les conditions sont dans `Manuel` et le recalcul de la fiche
## chez le joueur : une interface qui referait le test finirait par en oublier un,
## et c'est le clic qui donnerait le point de trop.
func _investir(identifiant: String) -> void:
	if _player != null:
		_player.investir(_choisi, identifiant)


## Un point de moins — d'un nœud seulement, et c'est `Manuel` qui le dit.
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


## Le haut de la ligne d'aide, en bas de la page : la borne basse des cases. Le
## dessin comme le test la lisent ici — mesurée deux fois, l'une des deux finirait
## par laisser les carrés descendre dessus.
func _aide_top() -> float:
	return size.y - LINE - 5.0


## Le coin haut-gauche de ce que la page dessine, sous l'en-tête et sa barre
## d'expérience. La grille des cases et l'arbre partent tous deux de là : deux
## origines calculées séparément se décaleraient au premier réglage d'en-tête.
func _origine() -> Vector2:
	return Vector2(PAD, _page_top() + LINE * 2.0 + XP_H + PAD)


func _case_rect(position: Vector2i) -> Rect2:
	return Rect2(_origine() + Vector2(position) * (CASE + CASE_GAP), Vector2(CASE, CASE))


## La racine de l'arbre : la case de la compétence elle-même, à gauche et centrée
## sur la hauteur des deux rangées de nœuds. C'est **là** que se placent ses
## points, et c'est ce qui fait de l'arbre la seule vue où l'on investit dans une
## compétence.
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
			Textes.t("[clic] ouvrir ou investir     [clic droit] ranger"),
			Vector2(PAD, _aide_top() + LINE), FONT_SIZE, UiPalette.HINT
		)
		var survolee := _case_survolee()
		if survolee != null:
			fiche = _fiche_de_case(livre.manuel, survolee)
			ancre = _case_rect(survolee.position)
	else:
		# Le chevron dit d'où l'on revient : la fenêtre n'a pas de barre de titre
		# où poser un bouton, et le clic droit fait le retour.
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

	# En dernier : la fiche déborde de la page et doit passer par-dessus ce qu'elle
	# recouvre, le sac compris.
	if fiche != null:
		_draw_fiche(fiche, ancre)


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


## Le haut de la page : le titre de la vue, le niveau du livre, ce qui reste à
## placer, et la barre d'expérience. **Le même dans les deux vues** : les points
## restants décident de ce qu'on peut faire, et les cacher dans l'arbre
## obligerait à revenir sur la grille pour savoir si l'on a de quoi payer.
func _draw_entete(livre: Item, titre: String, teinte: Color) -> void:
	var manuel := livre.manuel
	var y := _page_top() + 8.0
	_texte(titre, Vector2(PAD, y), TITLE_SIZE, teinte)

	var restants := manuel.points_restants()
	# Le pluriel passe par la traduction, parce que sa règle n'est pas la même
	# d'une langue à l'autre. Zéro ne passe pas par ici : il a sa propre phrase,
	# et le français y met le singulier là où l'anglais met le pluriel.
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

	# La barre d'expérience du livre. Vide et sans promesse au plafond : une jauge
	# pleine qui ne bougera plus se lit mieux ainsi qu'avec un dénominateur inventé.
	var avancement := manuel.avancement()
	var barre := Rect2(PAD, y + LINE * 1.6, size.x - PAD * 2.0, XP_H)
	draw_rect(barre, XP_FOND)
	if avancement.y > 0:
		var ratio := clampf(float(avancement.x) / float(avancement.y), 0.0, 1.0)
		draw_rect(Rect2(barre.position, Vector2(barre.size.x * ratio, barre.size.y)), XP_PLEIN)
	draw_rect(barre, UiPalette.BORDER, false, 1.0)


## Une case de la grille, ou la racine d'un arbre. Le rectangle est passé plutôt
## que déduit de la position : la même case se dessine à deux endroits, et deux
## calculs se seraient décalés.
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

	# Un passif se distingue **par la forme**, pans coupés : la couleur est déjà
	# prise par l'état de la case, et un joueur doit voir « toujours actif » sans
	# survoler.
	if passif != null:
		draw_colored_polygon(_pans(r), CASE_FOND)
		draw_polyline(_pans(r, true), teinte, epaisseur)
	else:
		draw_rect(r, CASE_FOND)

	# L'icône d'abord, le liseré par-dessus : c'est lui qui dit l'état de la case,
	# et une icône claire qui déborderait dessus en effacerait le message.
	_draw_icone(r, case, teinte == VERROU)
	if passif == null:
		draw_rect(r, teinte, false, epaisseur)
		# Le chevron dit que la case s'ouvre sur un arbre. Dans le coin bas
		# gauche, à l'opposé du compte : les deux au même endroit, et l'un mange
		# l'autre.
		if not case.talents.is_empty():
			_draw_chevron(r.position + Vector2(4.0, r.size.y - 5.0), MOT_CLE)

	# Verrouillée, la case annonce ce qu'elle demande plutôt que zéro : « niv. 4 »
	# explique, « 0/5 » laisse croire à une case qu'on a le droit d'ouvrir.
	var libelle := "%d/%d" % [places, maximum]
	if places == 0 and teinte == VERROU:
		libelle = Textes.t("niv. %d") % case.niveau_requis()
	# Rentrée dans les pans coupés d'un passif : posée au coin comme sur un carré,
	# la plaque dépassait du liseré — vu sur capture, invisible à toute assertion.
	_draw_compte(
		r.grow(-PAN * 0.5) if passif != null else r,
		libelle, UiPalette.TEXTE if teinte != VERROU else UiPalette.LABEL, FONT_SIZE
	)


## L'arbre d'une compétence : sa racine, les liens, puis les nœuds. Les liens
## d'abord, pour que les nœuds en couvrent les bouts.
func _draw_arbre(manuel: Manuel, arch: ManuelArchetype, case: CaseDeManuel) -> void:
	var racine := _racine_rect()
	for noeud in case.talents:
		var r := _noeud_rect(noeud.position)
		var depuis := racine if noeud.parent.is_empty() else _noeud_rect(
			case.noeud_de(noeud.parent).position
		)
		# Le lien s'allume quand le nœud porte un point : un trait qui ne change
		# pas ne dit pas si la branche est prise.
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

	# La nature d'arrivée d'un nœud de conversion, en pastille : c'est le seul
	# effet qui change ce que la compétence **est**, et le seul qu'on reconnaisse
	# à une couleur.
	if noeud.convertit():
		draw_circle(r.position + Vector2(5.0, 5.0), 2.0, DamageType.COLORS[noeud.convertit_vers])

	_draw_compte(
		r, "%d/%d" % [places, noeud.points_max],
		UiPalette.TEXTE if teinte != VERROU else UiPalette.LABEL, FONT_SIZE
	)


## La couleur du liseré, pour une case comme pour un nœud : c'est le seul endroit
## qui traduit un état en couleur, et les deux dessins doivent dire la même chose.
func _teinte(manuel: Manuel, ouvert: bool, places: int, maximum: int) -> Color:
	if places >= maximum:
		return PLEINE
	if not ouvert:
		return VERROU
	return OUVERTE if manuel.points_restants() > 0 else ATTENTE


## Le rectangle à pans coupés d'un passif. `boucle` ferme le contour : une
## polyligne ouverte laisserait un coin manquant en haut à gauche.
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


## L'icône de ce que la case porte, **assombrie tant qu'elle est verrouillée**.
## Une icône grise se lit comme « pas encore » d'un coup d'œil, là où il faut lire
## le « niv. 4 » du coin pour comprendre la même chose.
##
## Rien à dessiner quand elle n'a pas d'image : la case garde son fond, et c'est
## le compte qui l'identifie. Une page de manuel reste utilisable sans une seule
## icône.
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


## Le compte des points investis, **en bas à droite sur une plaque sombre**.
##
## Au centre — là où il était avant les icônes — il tombait en plein milieu du
## dessin. Et posé à même l'icône sans sa plaque, il disparaîtrait dès que
## celle-ci est claire à cet endroit : c'est le chiffre qui compte pour décider
## d'un point, il ne peut pas dépendre de ce que le dessin fait derrière.
func _draw_compte(r: Rect2, libelle: String, teinte: Color, taille: int) -> void:
	var largeur := _font.get_string_size(
		libelle, HORIZONTAL_ALIGNMENT_LEFT, -1.0, taille
	).x + 4.0
	# Décalée d'un pixel : posée sur le bord, la plaque mangerait le liseré qui
	# dit l'état de la case.
	var plaque := Rect2(r.end - Vector2(largeur + 1.0, LINE + 1.0), Vector2(largeur, LINE))
	draw_rect(plaque, Color(0.06, 0.05, 0.09, 0.82))
	_texte(libelle, plaque.position + Vector2(2.0, LINE - 2.0), taille, teinte)


## La fiche complète de la case survolée. Les carrés ne portent qu'un compte : à
## trente-quatre pixels, un nom se tronque et deux cases voisines finissent par
## annoncer la même chose.
func _draw_fiche(fiche: Fiche, ancre: Rect2) -> void:
	var r := _fiche_rect(ancre, _hauteur_de_fiche(fiche.lignes))
	draw_rect(r, UiPalette.TIP_BACK)
	draw_rect(r, UiPalette.BORDER, false, 1.0)

	var gauche := r.position.x + FICHE_PAD
	var largeur := r.size.x - FICHE_PAD * 2.0
	var y := r.position.y + FICHE_PAD
	_texte(fiche.titre, Vector2(gauche, y + LINE - 1.0), TITLE_SIZE, UiPalette.TEXTE)
	# Ce que c'est, ou ce qui peut l'améliorer : ici et pas sur la barre, parce
	# qu'on lit une page de manuel pour comprendre une compétence, et la barre
	# pour la lancer.
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


## La fiche de ce qu'une case porte, quelle que soit sa sorte : c'est le survol de
## la grille, où les deux se côtoient.
func _fiche_de_case(manuel: Manuel, case: CaseDeManuel) -> Fiche:
	if case.competence != null:
		return _fiche_de_competence(manuel, case.competence)
	return _fiche_de_passif(manuel, case.passif) if case.passif != null else null


## Tout ce que fait la compétence de la case, une caractéristique par ligne.
##
## **Tous les nombres viennent de `Player.resoudre()`**, le chemin même du lancer.
## Lus sur la compétence, ils ignoreraient l'équipement et les talents, et la
## fiche annoncerait un projectile de moins que ce qui part. Une ligne qui ne dit
## rien ne s'écrit pas : pas de « 0 froid », pas d'écart pour un trait droit.
##
## Sans point placé, ce sont les nombres du premier : une case qui annoncerait
## zéro ne dirait pas ce qu'elle vaut.
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
	# Ce qu'un nœud de conversion a déplacé, dans la couleur de la nature
	# d'arrivée : c'est la ligne qui dit à quelle résistance le coup s'oppose
	# maintenant, et elle ne se déduit d'aucune autre.
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
			Groupe.TIR, Textes.t("projectiles"), str(geste.nombre_de_projectiles()),
			UiPalette.TEXTE
		))
		if geste.dispersion_en_degres > 0.0:
			out.append(LigneDeFiche.new(
				Groupe.TIR, Textes.t("écart"), "%d°" % roundi(geste.dispersion_en_degres),
				UiPalette.TEXTE
			))
		if geste.vitesse_de_projectile > 0.0:
			out.append(LigneDeFiche.new(
				# Un contexte : « vitesse » nomme aussi le déplacement sur la fiche
				# de personnage, et l'anglais ne dit pas les deux pareil.
				Groupe.TIR, Textes.t("vitesse", "fiche de compétence"),
				"%d px/s" % roundi(geste.vitesse_de_projectile), UiPalette.TEXTE
			))

	# Ce que la compétence inflige, la ligne qu'on cherche pour comparer deux sorts :
	# les bornes d'un projectile ne disent pas ce que vaut une salve de quatre.
	var par_lancer := geste.moyenne_par_lancer()
	if par_lancer > 0.0:
		out.append(LigneDeFiche.new(
			Groupe.ESTIMATION, Textes.t("moyenne par lancer"), str(roundi(par_lancer)), PLEINE
		))
		if geste.intervalle > 0.0:
			out.append(LigneDeFiche.new(
				Groupe.ESTIMATION, Textes.t("par seconde"),
				str(roundi(geste.moyenne_par_seconde())), PLEINE
			))
		# Ce que les deux moyennes supposent, dit sous elles et non dans leur
		# intitulé : une estimation qu'on croit garantie fait passer l'armure de
		# l'ennemi pour un bug de la fiche. Sans valeur à droite — c'est une note
		# de bas de page, pas une caractéristique de plus.
		out.append(LigneDeFiche.new(
			Groupe.ESTIMATION, Textes.t("si tout touche, avant défenses"), "", UiPalette.HINT
		))
	return Fiche.new(competence.nom_affiche(), geste.libelle_des_mots_cles(), out)


## La fiche d'un passif : ce qu'il donne, aux points où il en est. Son sous-titre
## dit « toujours actif » là où une compétence écrit ses mots-clés — c'est ce
## qu'il faut savoir de lui avant ses nombres.
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


## La fiche d'un nœud d'arbre : ce qu'il change au lancer, et ce qu'il demande
## tant qu'il est fermé.
##
## Ce qu'il demande est lu sur le manuel et non recalculé : « ouvert » est une
## règle, et la page n'en porte aucune.
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
	# Le mot-clé donné, qui est ce qui distingue un nœud de conversion cher d'un
	# nœud de conversion simple : il fait mordre l'équipement de la nature
	# d'arrivée.
	for id in noeud.mots_cles_ajoutes:
		out.append(LigneDeFiche.new(
			Groupe.EFFET, Textes.t("mot-clé"), MotsCles.libelle(id), MOT_CLE
		))
	return Fiche.new(noeud.nom_affiche(), Textes.t("talent"), out)


## Ce qui manque pour ouvrir un nœud : son parent s'il est vide, sinon les points
## de sa compétence. Le parent d'abord — c'est la condition la plus proche, et
## celle qu'on peut satisfaire tout de suite.
func _ce_qu_il_demande(manuel: Manuel, case: CaseDeManuel, noeud: NoeudDeTalent) -> String:
	if not noeud.parent.is_empty() and manuel.points_de(noeud.parent) <= 0:
		var parent := case.noeud_de(noeud.parent)
		return Textes.t("le talent « {nom} »").format({"nom": parent.nom_affiche()})
	# « dans la compétence » et non son nom : l'en-tête de l'arbre l'écrit déjà
	# juste au-dessus, et « 2 points dans Lames tournoyantes » débordait de la
	# fiche — mesuré par `test_largeurs`, invisible sur une capture française.
	return Textes.tn(
		"{points} point dans la compétence", "{points} points dans la compétence",
		noeud.points_requis
	).format({"points": noeud.points_requis})


## Les lignes d'un passif ou d'un nœud, une par modificateur, écrites **par la
## même fonction que l'infobulle d'un objet** : « +25 armure » doit se lire
## pareil, qu'il vienne d'un plastron ou d'un livre.
func _lignes_d_effet(mods: Array[StatMod]) -> Array[LigneDeFiche]:
	var out: Array[LigneDeFiche] = []
	for m in mods:
		out.append(LigneDeFiche.new(
			Groupe.EFFET, StatMod.nom(m.stat, m.portee), m.valeur_lisible(), UiPalette.TEXTE
		))
	return out


## Ce qu'annoncent les nombres d'une case vide : ceux du premier point. Écrite une
## fois pour les trois sortes de fiche.
func _ligne_du_premier_point() -> LigneDeFiche:
	return LigneDeFiche.new(
		Groupe.ETAT, Textes.t("nombres du premier point"), "", UiPalette.TEXTE
	)


static func _ouvre_un_groupe(lignes: Array[LigneDeFiche], index: int) -> bool:
	return index == 0 or lignes[index].groupe != lignes[index - 1].groupe


## Mesurée sur les lignes mêmes que le dessin écrit : un compte tenu à part
## laisserait la dernière déborder du cadre au premier groupe ajouté.
func _hauteur_de_fiche(lignes: Array[LigneDeFiche]) -> float:
	var h := FICHE_PAD * 2.0 + FICHE_ENTETE + LINE * float(lignes.size())
	for i in lignes.size():
		if _ouvre_un_groupe(lignes, i):
			h += FICHE_SEPARATION
	return h


## Le cadre de la fiche, dans le repère du panneau : à droite de ce qu'elle
## décrit, à sa hauteur, et **tenu dans le cadrage** au-dessus des jauges du HUD.
## À gauche quand la droite n'a pas la place : un panneau qu'on déplacerait ne
## doit pas emmener sa fiche hors de l'écran.
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


## Un multiplicateur écrit comme le joueur le lit sur un objet, et **par la même
## fonction** que l'objet : 1,4 devient « +40 % ». Écrit à part, le pourcentage de
## la fiche et celui de l'infobulle divergeraient à la première retouche de
## typographie.
static func _accroissement(facteur: float) -> String:
	return StatMod.value_label("", StatMod.Mode.PERCENT, (facteur - 1.0) * 100.0)


func _texte(texte: String, at: Vector2, taille: int, teinte: Color) -> void:
	draw_string(_font, at, texte, HORIZONTAL_ALIGNMENT_LEFT, -1.0, taille, teinte)
