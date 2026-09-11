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
## que tout cela donne.
enum Groupe { ETAT, COUT, DEGATS, TIR, ESTIMATION }


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


## Le haut de la ligne d'aide, en bas de la page : la borne basse des cases. Le
## dessin comme le test la lisent ici — mesurée deux fois, l'une des deux finirait
## par laisser les carrés descendre dessus.
func _aide_top() -> float:
	return size.y - LINE - 5.0


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
	_draw_page(livre)

	_texte(
		Textes.t("[clic] investir     [clic droit] ranger un manuel"),
		Vector2(PAD, _aide_top() + LINE), FONT_SIZE, UiPalette.HINT
	)

	# En dernier : la fiche déborde de la page et doit passer par-dessus ce qu'elle
	# recouvre, le sac compris.
	var cases := livre.base.manuel.cases
	if _survol_case >= 0 and _survol_case < cases.size():
		_draw_fiche(livre.manuel, cases[_survol_case])


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
	_texte(livre.base.manuel.nom_affiche(), Vector2(PAD, y), TITLE_SIZE, livre.color())

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

	var cases := livre.base.manuel.cases
	for i in cases.size():
		_draw_case(manuel, cases[i], i == _survol_case)


func _draw_case(manuel: Manuel, case: CaseDeManuel, survolee: bool) -> void:
	var r := _case_rect(case.position)
	draw_rect(r, CASE_FOND)

	var competence := case.competence
	if competence == null:
		draw_rect(r, VERROU, false, 1.0)
		return

	var places := manuel.points_de(competence.id)
	var maximum := competence.points_max()
	var verrouillee := manuel.niveau() < competence.niveau_de_manuel_requis
	var teinte := VERROU
	if places >= maximum:
		teinte = PLEINE
	elif not verrouillee:
		teinte = OUVERTE if manuel.points_restants() > 0 else ATTENTE

	# L'icône d'abord, le liseré par-dessus : c'est lui qui dit l'état de la case,
	# et une icône claire qui déborderait dessus en effacerait le message.
	_draw_icone(r, competence, verrouillee)
	draw_rect(r, teinte, false, 2.0 if survolee else 1.0)

	# Verrouillée, la case annonce ce qu'elle demande plutôt que zéro : « niv. 4 »
	# explique, « 0/5 » laisse croire à une case qu'on a le droit d'ouvrir.
	var libelle := "%d/%d" % [places, maximum]
	if places == 0 and verrouillee:
		libelle = Textes.t("niv. %d") % competence.niveau_de_manuel_requis
	_draw_compte(r, libelle, UiPalette.TEXTE if teinte != VERROU else UiPalette.LABEL)


## L'icône de la compétence, **assombrie tant que la case est verrouillée**. Une
## icône grise se lit comme « pas encore » d'un coup d'œil, là où il faut lire le
## « niv. 4 » du coin pour comprendre la même chose.
##
## Rien à dessiner quand la compétence n'a pas d'image : la case garde son fond,
## et c'est le compte qui l'identifie. Une page de manuel reste utilisable sans
## une seule icône.
func _draw_icone(r: Rect2, competence: Competence, verrouillee: bool) -> void:
	var tex := IconeDeCompetence.texture(competence)
	if tex == null:
		return
	var taille := tex.get_size() * float(IconeDeCompetence.facteur(tex, CASE))
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
func _draw_compte(r: Rect2, libelle: String, teinte: Color) -> void:
	var largeur := _font.get_string_size(
		libelle, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE
	).x + 4.0
	# Décalée d'un pixel : posée sur le bord, la plaque mangerait le liseré qui
	# dit l'état de la case.
	var plaque := Rect2(r.end - Vector2(largeur + 1.0, LINE + 1.0), Vector2(largeur, LINE))
	draw_rect(plaque, Color(0.06, 0.05, 0.09, 0.82))
	_texte(libelle, plaque.position + Vector2(2.0, LINE - 2.0), FONT_SIZE, teinte)


## La fiche complète de la case survolée. Les carrés ne portent qu'un compte : à
## trente-quatre pixels, un nom se tronque et deux cases voisines finissent par
## annoncer la même chose.
func _draw_fiche(manuel: Manuel, case: CaseDeManuel) -> void:
	var competence := case.competence
	if competence == null or _player == null:
		return
	var lignes := _lignes_de_fiche(manuel, competence)
	var r := _fiche_rect(case, _hauteur_de_fiche(lignes))
	draw_rect(r, UiPalette.TIP_BACK)
	draw_rect(r, UiPalette.BORDER, false, 1.0)

	var gauche := r.position.x + FICHE_PAD
	var largeur := r.size.x - FICHE_PAD * 2.0
	var y := r.position.y + FICHE_PAD
	_texte(competence.nom_affiche(), Vector2(gauche, y + LINE - 1.0), TITLE_SIZE, UiPalette.TEXTE)
	# Ce qui peut l'améliorer : ici et pas sur la barre, parce qu'on lit une page de
	# manuel pour comprendre une compétence, et la barre pour la lancer.
	_texte(
		competence.libelle_des_mots_cles(), Vector2(gauche, y + LINE * 2.0 - 2.0),
		FONT_SIZE, MOT_CLE
	)
	y += FICHE_ENTETE

	for i in lignes.size():
		if _ouvre_un_groupe(lignes, i):
			draw_rect(Rect2(gauche, roundf(y + FICHE_SEPARATION * 0.5), largeur, 1.0), UiPalette.BORDER)
			y += FICHE_SEPARATION
		var ligne := lignes[i]
		var base := y + LINE - 2.0
		_texte(ligne.libelle, Vector2(gauche, base), FONT_SIZE, UiPalette.HINT)
		draw_string(
			_font, Vector2(gauche, base), ligne.valeur,
			HORIZONTAL_ALIGNMENT_RIGHT, largeur, FONT_SIZE, ligne.teinte
		)
		y += LINE


## Tout ce que fait la compétence de la case, une caractéristique par ligne.
##
## **Tous les nombres viennent de `Player.resoudre()`**, le chemin même du lancer.
## Lus sur la compétence, ils ignoreraient l'équipement, et la fiche annoncerait
## un projectile de moins que ce qui part. Une ligne qui ne dit rien ne s'écrit
## pas : pas de « 0 froid », pas d'écart pour un trait droit.
##
## Sans point placé, ce sont les nombres du premier : une case qui annoncerait
## zéro ne dirait pas ce qu'elle vaut.
func _lignes_de_fiche(manuel: Manuel, competence: Competence) -> Array[LigneDeFiche]:
	var places := manuel.points_de(competence.id)
	var geste := _player.resoudre(competence, maxi(places, 1))
	var projectile := competence.porte(MotsCles.PROJECTILE)
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
		out.append(LigneDeFiche.new(
			Groupe.ETAT, Textes.t("nombres du premier point"), "", UiPalette.TEXTE
		))

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
	return out


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


## Le cadre de la fiche, dans le repère du panneau : à droite de la page, à la
## hauteur de la case survolée, et **tenu dans le cadrage** au-dessus des jauges
## du HUD. À gauche quand la droite n'a pas la place : un panneau qu'on
## déplacerait ne doit pas emmener sa fiche hors de l'écran.
func _fiche_rect(case: CaseDeManuel, hauteur: float) -> Rect2:
	var ecran := Vector2(Settings.taille_de_base())
	var x := size.x + FICHE_GAP
	if global_position.x + x + FICHE_W > ecran.x:
		x = -FICHE_GAP - FICHE_W
	var plancher := Hud.haut_des_jauges(ecran.y) - global_position.y
	var y := minf(_case_rect(case.position).position.y, plancher - hauteur)
	return Rect2(x, maxf(y, -global_position.y), FICHE_W, hauteur)


## « 3–7 froid », ou « 23 foudre » quand les deux bornes s'arrondissent au même
## nombre.
static func _en_nature(bas: float, haut: float, nature: int) -> String:
	return "%s %s" % [StatsDeCompetence.fourchette_lisible(bas, haut), DamageType.nom(nature)]


## Un multiplicateur écrit comme le joueur le lit sur un objet, et **par la même
## fonction** que l'objet : 1,4 devient « +40 % ». Écrit à part, le pourcentage de
## la fiche et celui de l'infobulle divergeraient à la première retouche de
## typographie.
static func _accroissement(facteur: float) -> String:
	return StatMod.value_label("", StatMod.Mode.PERCENT, (facteur - 1.0) * 100.0)


func _texte(texte: String, at: Vector2, taille: int, teinte: Color) -> void:
	draw_string(_font, at, texte, HORIZONTAL_ALIGNMENT_LEFT, -1.0, taille, teinte)
