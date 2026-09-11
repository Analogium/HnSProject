extends GutTest

## La fiche de personnage. Les deux compétences de départ y ont leur ligne, parce
## qu'aucune page de manuel ne les décrit ; ces lignes doivent dire ce que le
## lancer fera, équipement compris.

var _fiche: StatsPanel
var _joueur: Player


func before_each() -> void:
	_joueur = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_joueur)
	_fiche = StatsPanel.new()
	# Le titre est un nœud de la scène de zone, que le panneau cherche à son
	# arrivée dans l'arbre.
	var titre := Label.new()
	titre.name = "Title"
	_fiche.add_child(titre)
	add_child_autofree(_fiche)
	await wait_process_frames(1)
	_fiche.bind(_joueur)


func _par_le_lancer(id: String) -> String:
	var geste := _joueur.resoudre(CompetenceCatalog.by_id(id), _joueur.points_de_competence(id))
	return StatsDeCompetence.fourchette_lisible(geste.total_min(), geste.total_max())


## Chaque ligne vient de la résolution du lancer. Une épée monte l'attaque et
## laisse le trait tel quel : c'est la séparation des attaques et des sorts, à
## l'endroit où le joueur la cherche.
func test_les_competences_de_depart_ont_leurs_degats_resolus() -> void:
	var attaque_nue := _fiche._value_of(CompetenceCatalog.ID_ATTAQUE)
	var trait_nu := _fiche._value_of(CompetenceCatalog.ID_TIR)
	assert_eq(attaque_nue, _par_le_lancer(CompetenceCatalog.ID_ATTAQUE))
	assert_eq(trait_nu, _par_le_lancer(CompetenceCatalog.ID_TIR))

	_joueur.equip(Item.new(ItemCatalog.by_id("epee")))
	assert_ne(_fiche._value_of(CompetenceCatalog.ID_ATTAQUE), attaque_nue, "l'épée monte l'attaque")
	assert_eq(
		_fiche._value_of(CompetenceCatalog.ID_ATTAQUE), _par_le_lancer(CompetenceCatalog.ID_ATTAQUE)
	)
	assert_eq(_fiche._value_of(CompetenceCatalog.ID_TIR), trait_nu, "et ne touche pas au trait")


## `ensorcele` vise `sort` : la baguette qui le porte monte le trait de ce qu'elle
## annonce, et laisse l'attaque telle quelle.
func test_un_pourcentage_de_degats_des_sorts_ne_monte_que_le_trait() -> void:
	var trait_de_depart := CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR)
	var points := _joueur.points_de_competence(CompetenceCatalog.ID_TIR)
	var nu := _joueur.resoudre(trait_de_depart, points)
	var attaque_nue := _par_le_lancer(CompetenceCatalog.ID_ATTAQUE)

	_joueur.equip(Item.new(
		ItemCatalog.by_id("baguette"), [ItemAffixPool.by_id("ensorcele").modificateur(40.0)]
	))
	var ensorcele := _joueur.resoudre(trait_de_depart, points)
	assert_almost_eq(ensorcele.total_max(), nu.total_max() * 1.4, 1e-4, "+40 % au trait")
	assert_almost_eq(ensorcele.total_min(), nu.total_min() * 1.4, 1e-4)
	assert_eq(_par_le_lancer(CompetenceCatalog.ID_ATTAQUE), attaque_nue, "et rien à l'attaque")


## L'intitulé est le nom que le joueur lit sur la barre, pas l'identifiant : la
## compétence de tir s'appelle « Trait » à l'écran.
func test_les_lignes_portent_le_nom_des_competences() -> void:
	assert_eq(
		_fiche._libelle_of(CompetenceCatalog.ID_ATTAQUE),
		CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE).nom.to_lower()
	)
	assert_eq(
		_fiche._libelle_of(CompetenceCatalog.ID_TIR),
		CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR).nom.to_lower()
	)
	assert_eq(_fiche._libelle_of("armor"), StatMod.LABELS["armor"], "une statistique garde le sien")


## Le dessin traverse la fiche entière, les deux lignes de compétence comprises.
func test_le_dessin_ne_plante_pas() -> void:
	_fiche.toggle()
	_fiche.queue_redraw()
	await wait_process_frames(2)
	_fiche.toggle()
	assert_true(true, "aucun plantage au dessin")
