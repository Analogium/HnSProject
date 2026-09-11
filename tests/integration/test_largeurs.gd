extends GutTest

## Ce qui est dessiné dans une largeur fixe doit tenir **dans les deux langues**.
##
## Rien n'avertit qu'un texte déborde : il se superpose au voisin, ou sort du
## cadre, et seule une capture le montre — dans une langue à la fois. « moyenne
## par lancer » devient « average per cast », « vitesse d'incantation » devient
## « cast speed » : l'anglais est tantôt plus court, tantôt plus long, et c'est
## celui qu'on ne regarde pas qui déborde.
##
## Les largeurs viennent des panneaux et de la scène de zone, jamais recopiées
## ici : un panneau élargi d'un pixel ne doit pas faire passer un test qui
## validerait sa propre copie.

## L'air minimal entre un intitulé et la valeur calée à sa droite. Deux textes
## qui se touchent se lisent comme un seul mot.
const MARGE := 4.0

var _joueur: Player
var _fiche: ManuelPanel
var _perso: StatsPanel
var _barre: BarrePanel
var _police: Font


func before_each() -> void:
	_police = ThemeDB.fallback_font
	_joueur = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_joueur)

	_fiche = ManuelPanel.new()
	_poser(_fiche, "Manuels")
	_perso = StatsPanel.new()
	_poser(_perso, "Stats")
	_barre = BarrePanel.new()
	_poser(_barre, "Barre")
	await wait_process_frames(1)
	for panneau in [_fiche, _perso, _barre]:
		panneau.bind(_joueur)

	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"))
	livre.manuel.gagner_experience(999999)
	for case in livre.base.manuel.cases:
		for i in case.competence.points_max():
			livre.manuel.investir(livre.base.manuel, case.competence.id)
	_joueur.etudier(livre)
	# Des points à placer : la fiche de personnage réserve alors la place d'un
	# bouton sur chaque ligne d'attribut, et c'est le cas le plus serré.
	_joueur.unspent_points = 3


## Le filet du §9 : un test qui laisse le jeu en anglais fait échouer les suivants
## loin de sa propre cause.
func after_each() -> void:
	if Settings.langue != Settings.FRANCAIS:
		Settings.depuis_dict({"langue": Settings.FRANCAIS})


# --------------------------------------------------------------------------
# Les trois panneaux
# --------------------------------------------------------------------------

## La fiche d'une compétence : intitulé à gauche, valeur calée à droite, dans
## cent soixante-dix pixels. C'est la plus étroite du jeu, et celle qui porte le
## plus de mots.
func test_la_fiche_de_competence_tient_dans_les_deux_langues() -> void:
	var livre: Item = _joueur.ratelier.a(0)
	var largeur := ManuelPanel.FICHE_W - ManuelPanel.FICHE_PAD * 2.0

	for langue in [Settings.FRANCAIS, Settings.ANGLAIS]:
		Settings.depuis_dict({"langue": langue})
		for case in livre.base.manuel.cases:
			var competence: Competence = case.competence
			_tient(
				competence.nom_affiche(), largeur, ManuelPanel.TITLE_SIZE,
				"%s : le nom de « %s »" % [langue, competence.id]
			)
			_tient(
				competence.libelle_des_mots_cles(), largeur, ManuelPanel.FONT_SIZE,
				"%s : les mots-clés de « %s »" % [langue, competence.id]
			)
			for ligne in _fiche._lignes_de_fiche(livre.manuel, competence):
				_tiennent_ensemble(
					ligne.libelle, ligne.valeur, largeur, ManuelPanel.FONT_SIZE,
					"%s : « %s » de « %s »" % [langue, ligne.libelle, competence.id]
				)


## La fiche de personnage : un quart de la largeur du cadrage, pour une vingtaine
## de lignes et six titres de groupe.
func test_la_fiche_de_personnage_tient_dans_les_deux_langues() -> void:
	for langue in [Settings.FRANCAIS, Settings.ANGLAIS]:
		Settings.depuis_dict({"langue": langue})
		var largeur := _perso.size.x - StatsPanel.PAD * 2.0

		_tient(
			Textes.t("C pour fermer"), largeur, StatsPanel.FONT_SIZE, "%s : l'aide" % langue
		)
		for groupe in StatsPanel.GROUPS:
			# Le titre du groupe et le compte des points à placer se partagent la
			# ligne, l'un à gauche et l'autre à droite.
			_tiennent_ensemble(
				Textes.t(groupe[0]), Textes.t("%d à placer") % _joueur.unspent_points,
				largeur, StatsPanel.FONT_SIZE, "%s : le titre « %s »" % [langue, groupe[0]]
			)
			for champ in groupe[1]:
				# Les lignes d'attribut laissent la place du bouton « + ».
				var place := largeur
				if champ in CharacterStats.ATTRIBUTES:
					place -= StatsPanel.BUTTON_W + 3.0
				_tiennent_ensemble(
					_perso._libelle_of(champ), _perso._value_of(champ), place,
					StatsPanel.FONT_SIZE, "%s : la ligne « %s »" % [langue, champ]
				)


## Le menu de la barre : une icône, puis le nom de la compétence. C'est le seul
## endroit où un nom de sort s'écrit en entier à côté d'une image.
func test_le_menu_de_la_barre_tient_dans_les_deux_langues() -> void:
	for langue in [Settings.FRANCAIS, Settings.ANGLAIS]:
		Settings.depuis_dict({"langue": langue})
		var cadre := _barre._menu_cadre(_barre._entrees().size())
		# Le nom commence après l'icône, et l'entrée garde son air à droite.
		var largeur := cadre.size.x - float(IconeDeCompetence.COTE) - 10.0

		_tient(
			Textes.t("— vider la case —"), cadre.size.x - 6.0, BarrePanel.FONT_SIZE,
			"%s : l'entrée qui vide" % langue
		)
		for competence in _joueur.competences_disponibles():
			_tient(
				competence.nom_affiche(), largeur, BarrePanel.FONT_SIZE,
				"%s : « %s » dans le menu" % [langue, competence.id]
			)


# --------------------------------------------------------------------------
# Les outils
# --------------------------------------------------------------------------

## Le panneau prend la place qu'il occupe **dans la scène de zone** : ancres et
## décalages, comme Godot les résout. Une taille inventée ici validerait un
## panneau qui n'est pas celui du jeu.
func _poser(panneau: Control, nom: String) -> void:
	var base := Vector2(Settings.taille_de_base())
	var etat := (load("res://world/zone.tscn") as PackedScene).get_state()
	for i in etat.get_node_count():
		if etat.get_node_name(i) != nom:
			continue
		var p := {}
		for j in etat.get_node_property_count(i):
			p[etat.get_node_property_name(i, j)] = etat.get_node_property_value(i, j)
		panneau.size = Vector2(
			float(p.get("anchor_right", 0.0) - p.get("anchor_left", 0.0)) * base.x
				+ float(p.get("offset_right", 0.0) - p.get("offset_left", 0.0)),
			float(p.get("anchor_bottom", 0.0) - p.get("anchor_top", 0.0)) * base.y
				+ float(p.get("offset_bottom", 0.0) - p.get("offset_top", 0.0))
		)
		break
	assert_gt(panneau.size.x, 0.0, "le cadre de « %s » vient bien de la scène" % nom)
	add_child_autofree(panneau)


func _largeur(texte: String, taille: int) -> float:
	return _police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1.0, taille).x


func _tient(texte: String, largeur: float, taille: int, quoi: String) -> void:
	assert_lte(
		_largeur(texte, taille), largeur,
		"%s — « %s » déborde de %.0f px" % [quoi, texte, _largeur(texte, taille) - largeur]
	)


## Un intitulé à gauche et sa valeur calée à droite : ce qui compte est qu'ils ne
## se touchent pas.
func _tiennent_ensemble(
	gauche: String, droite: String, largeur: float, taille: int, quoi: String
) -> void:
	var occupe := _largeur(gauche, taille) + _largeur(droite, taille) + MARGE
	assert_lte(
		occupe, largeur,
		"%s — « %s » et « %s » se chevauchent de %.0f px" % [
			quoi, gauche, droite, occupe - largeur
		]
	)
