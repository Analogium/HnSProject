extends GutTest

## L'établi ne fabrique que des objets que le jeu pourrait produire. C'est toute
## sa valeur : un outil qui fabriquerait l'impossible ferait chasser des bugs qui
## n'existent pas.

var _atelier: AtelierPanel


func before_each() -> void:
	_atelier = AtelierPanel.new()
	_atelier.size = Vector2(384.0, 318.0)
	add_child_autofree(_atelier)
	await wait_process_frames(1)


## L'indice d'une base par son identifiant, pour que les tests nomment ce qu'ils
## choisissent au lieu de compter des lignes dans le catalogue.
func _index_de(id: String) -> int:
	var toutes := _atelier.bases()
	for i in toutes.size():
		if toutes[i].id == id:
			return i
	return -1


func test_toutes_les_bases_du_jeu_sont_proposees() -> void:
	assert_eq(_atelier.bases().size(), ItemCatalog.ALL.size())
	assert_not_null(_atelier.base_courante(), "et il y en a une de choisie d'emblée")


## Les affixes proposés sont ceux que la base accepte, et personne d'autre. Un
## manuel ne s'équipe nulle part, donc il ne reçoit rien.
func test_les_affixes_proposes_sont_ceux_de_la_base() -> void:
	_atelier.choisir_base(_index_de("epee"))
	var proposes := _atelier.compatibles()
	assert_gt(proposes.size(), 0, "une épée accepte quelque chose")
	for affixe: ItemAffix in proposes:
		assert_true(
			affixe.fits(_atelier.base_courante()),
			"« %s » ne va pas sur une épée" % affixe.id
		)

	_atelier.choisir_base(_index_de("manuel_foudre"))
	assert_eq(_atelier.compatibles().size(), 0, "un manuel ne reçoit aucun affixe")


## Le clic fait tourner l'affixe : absent, ses paliers du meilleur au pire, puis
## absent de nouveau. Un seul geste pour les trois questions.
func test_le_clic_fait_tourner_les_paliers() -> void:
	_atelier.choisir_base(_index_de("epee"))
	_atelier.changer_niveau(99)
	var affixe: ItemAffix = _atelier.compatibles()[0]
	var ouverts := affixe.ouverts(_atelier._niveau)
	assert_gt(ouverts.size(), 1, "plusieurs paliers ouverts à haut niveau")

	for attendu in ouverts:
		_atelier.basculer_affixe(affixe.id)
		assert_eq(_atelier._choisis.get(affixe.id), attendu, "palier %d" % attendu)
	_atelier.basculer_affixe(affixe.id)
	assert_false(_atelier._choisis.has(affixe.id), "un tour complet le retire")


## Le compte est borné par la table des poids, pas par un nombre écrit dans le
## panneau : un objet à sept affixes n'existe pas dans le jeu.
func test_le_nombre_d_affixes_est_borne() -> void:
	_atelier.choisir_base(_index_de("epee"))
	_atelier.changer_niveau(99)
	for affixe: ItemAffix in _atelier.compatibles():
		if not _atelier._choisis.has(affixe.id):
			_atelier.basculer_affixe(affixe.id)
	assert_eq(
		_atelier._choisis.size(), AtelierPanel.maximum_d_affixes(),
		"on ne dépasse pas le maximum du tirage"
	)


## Descendre le niveau d'objet doit **retirer** les paliers devenus
## inatteignables. Sans cet élagage, l'établi sortirait un objet de niveau 1
## portant un palier réservé au niveau 60.
func test_baisser_le_niveau_elague_les_paliers_trop_hauts() -> void:
	_atelier.choisir_base(_index_de("epee"))
	_atelier.changer_niveau(99)
	for affixe: ItemAffix in _atelier.compatibles():
		_atelier.basculer_affixe(affixe.id)
		break
	assert_eq(_atelier._choisis.size(), 1, "un affixe posé à haut niveau")

	_atelier.changer_niveau(-98)
	for id in _atelier._choisis:
		var affixe := ItemAffixPool.by_id(id)
		assert_true(
			affixe.ouverts(_atelier._niveau).has(_atelier._choisis[id]),
			"« %s » garde un palier que le niveau 1 n'ouvre pas" % id
		)


## L'objet fabriqué porte exactement ce qui est réglé, provenance comprise.
func test_l_objet_fabrique_porte_ce_qui_est_regle() -> void:
	_atelier.choisir_base(_index_de("epee"))
	_atelier.changer_niveau(39)
	var affixe: ItemAffix = _atelier.compatibles()[0]
	_atelier.basculer_affixe(affixe.id)

	var objet := _atelier.fabriquer()
	assert_eq(objet.base.id, "epee")
	assert_eq(objet.item_level, 40, "le niveau réglé")
	assert_eq(objet.explicits.size(), 1)
	var pose: RolledAffix = objet.explicits[0]
	assert_eq(pose.affix_id, affixe.id)
	assert_true(pose.connu(), "avec sa provenance, comme un objet tombé")
	assert_eq(pose.mod.stat, affixe.stat)


## Un affixe porté sort de l'établi avec sa portée, comme il sortirait du tirage :
## sans elle, le « +1 projectile » qu'on vient de poser deviendrait une ligne de
## fiche, et l'essai porterait sur un objet que le jeu ne produit pas.
func test_un_affixe_porte_sort_avec_sa_portee() -> void:
	_atelier.choisir_base(_index_de("baguette"))
	_atelier.basculer_affixe("fourchu")
	var pose: RolledAffix = _atelier.fabriquer().explicits[0]
	assert_eq(pose.mod.portee, MotsCles.PROJECTILE)


## La taille que la zone donne à l'établi, lue dans sa scène et non recopiée : une
## taille écrite ici validerait un panneau qui n'est pas celui du jeu.
func _taille_dans_la_zone() -> Vector2:
	var etat := (load("res://world/zone.tscn") as PackedScene).get_state()
	for i in etat.get_node_count():
		if etat.get_node_name(i) != "Atelier":
			continue
		var bords := {}
		for j in etat.get_node_property_count(i):
			bords[etat.get_node_property_name(i, j)] = etat.get_node_property_value(i, j)
		return Vector2(
			bords["offset_right"] - bords["offset_left"],
			bords["offset_bottom"] - bords["offset_top"]
		)
	return Vector2.ZERO


## Chaque affixe qu'une base accepte a sa ligne. La liste s'arrête au bas du
## panneau **sans rien dire** : un affixe tombé dessous ne pourrait jamais être
## posé, et on le croirait absent de la réserve.
func test_chaque_affixe_accepte_a_sa_ligne() -> void:
	_atelier.size = _taille_dans_la_zone()
	assert_gt(_atelier.size.y, 0.0, "la zone donne une taille à l'établi")
	for i in _atelier.bases().size():
		_atelier.choisir_base(i)
		_atelier._disposer()
		var lignes := 0
		for ligne in _atelier._lignes:
			if String(ligne["action"]).begins_with("affixe:"):
				lignes += 1
		assert_eq(
			lignes, _atelier.compatibles().size(),
			"« %s » : des affixes sous le bas du panneau" % _atelier.base_courante().display_name
		)


## Aucun tirage : deux fabrications du même réglage donnent la même valeur, et
## surtout `Game.rng` n'avance pas — il est le fil des graines de zone.
func test_l_etabli_ne_tire_rien_au_hasard() -> void:
	_atelier.choisir_base(_index_de("epee"))
	_atelier.changer_niveau(39)
	_atelier.basculer_affixe((_atelier.compatibles()[0] as ItemAffix).id)

	var avant := Game.rng.state
	var a := _atelier.fabriquer()
	var b := _atelier.fabriquer()
	assert_eq(Game.rng.state, avant, "l'établi n'a pas consommé de tirage")
	assert_eq(a.explicits[0].mod.value, b.explicits[0].mod.value, "et il est reproductible")


## Changer de base jette les affixes de l'ancienne : « allonge » n'a rien à faire
## sur une paire de bottes, et c'est exactement ce que l'établi refuse.
func test_changer_de_base_vide_les_affixes() -> void:
	_atelier.choisir_base(_index_de("epee"))
	_atelier.changer_niveau(99)
	_atelier.basculer_affixe((_atelier.compatibles()[0] as ItemAffix).id)
	assert_gt(_atelier._choisis.size(), 0)

	_atelier.choisir_base(_index_de("bottes"))
	assert_eq(_atelier._choisis.size(), 0)


func test_reinitialiser_remet_tout_a_zero() -> void:
	_atelier.choisir_base(_index_de("bottes"))
	_atelier.changer_niveau(50)
	_atelier.basculer_affixe((_atelier.compatibles()[0] as ItemAffix).id)

	_atelier.reinitialiser()
	assert_eq(_atelier._niveau, 1)
	assert_eq(_atelier._choisis.size(), 0)
	assert_eq(_atelier.base_courante(), ItemCatalog.ALL[0])


## Le bouton pose l'objet par le signal, jamais lui-même : c'est la zone qui sait
## faire tomber quelque chose, et il n'y a qu'un chemin pour ça.
func test_le_bouton_demande_la_chute() -> void:
	_atelier.choisir_base(_index_de("epee"))
	watch_signals(_atelier)
	_atelier._appliquer("lacher")
	assert_signal_emitted(_atelier, "drop_requested")
	var recu: Item = get_signal_parameters(_atelier, "drop_requested", 0)[0]
	assert_eq(recu.base.id, "epee")


## Le dessin traverse ses états sans se plaindre : une base sans affixe, une base
## chargée, et un manuel qui n'en accepte aucun.
func test_le_dessin_ne_plante_pas() -> void:
	for id in ["epee", "manuel_foudre", "bottes"]:
		_atelier.choisir_base(_index_de(id))
		_atelier.changer_niveau(40)
		for affixe: ItemAffix in _atelier.compatibles():
			_atelier.basculer_affixe(affixe.id)
		_atelier.visible = true
		_atelier.queue_redraw()
		await wait_process_frames(2)
	assert_true(true, "aucun plantage au dessin")
