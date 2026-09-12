extends GutTest

## Les passifs et les arbres de talents : ce qu'une case porte, ce qu'un point y
## fait, ce qu'il faut pour l'y mettre, et ce qu'un nœud change au lancer.
##
## Deux moitiés, et elles ne se mélangent pas. **Les règles** sont vérifiées sur
## des archétypes fabriqués ici : le contenu du jeu changera, la règle non. **Le
## contenu** est parcouru depuis le catalogue : c'est la moitié qui refuse le nœud
## ajouté de travers, et aucune partie ne le montrerait avant plusieurs heures.


# --------------------------------------------------------------------------
# De quoi fabriquer un livre
# --------------------------------------------------------------------------

func _fiche() -> CharacterStats:
	var f := CharacterStats.new()
	f.strength = 0.0
	f.dexterity = 0.0
	f.intelligence = 0.0
	return f


func _ligne(stat: String, valeur: float, pourcentage := false, portee := "", haut := 0.0) -> LigneDeTalent:
	var l := LigneDeTalent.new()
	l.stat = stat
	l.valeur_par_point = valeur
	l.valeur_max_par_point = haut
	l.pourcentage = pourcentage
	l.portee = portee
	return l


func _competence(id: String, table: Array[float], nature := DamageType.Kind.LIGHTNING) -> Competence:
	var c := Competence.new()
	c.id = id
	c.nom = id
	c.nature = nature
	c.degats_par_point = table
	return c


func _noeud(id: String, lignes: Array[LigneDeTalent], requis := 1, maximum := 1, parent := "") -> NoeudDeTalent:
	var n := NoeudDeTalent.new()
	n.id = id
	n.nom = id
	n.lignes = lignes
	n.points_requis = requis
	n.points_max = maximum
	n.parent = parent
	return n


func _passif(id: String, lignes: Array[LigneDeTalent], niveau := 1, maximum := 3) -> Passif:
	var p := Passif.new()
	p.id = id
	p.nom = id
	p.lignes = lignes
	p.niveau_de_manuel_requis = niveau
	p.points_max = maximum
	return p


func _case(porte: Resource, talents: Array[NoeudDeTalent] = []) -> CaseDeManuel:
	var c := CaseDeManuel.new()
	if porte is Competence:
		c.competence = porte
	else:
		c.passif = porte
	c.talents = talents
	return c


func _archetype(cases: Array[CaseDeManuel]) -> ManuelArchetype:
	var a := ManuelArchetype.new()
	a.id = "essai"
	a.nom = "Essai"
	a.cases = cases
	return a


## Le livre des règles : une compétence à cinq points avec deux nœuds — l'un
## enfant de l'autre — et un passif.
func _livre_d_essai() -> ManuelArchetype:
	var sort := _competence("sort", [10.0, 20.0, 30.0, 40.0, 50.0] as Array[float])
	var branche := _noeud("sort_branche", [_ligne("degats", 10.0, true)] as Array[LigneDeTalent], 1, 3)
	var feuille := _noeud(
		"sort_feuille", [_ligne("projectiles", 1.0)] as Array[LigneDeTalent], 2, 1, "sort_branche"
	)
	return _archetype([
		_case(sort, [branche, feuille] as Array[NoeudDeTalent]),
		_case(_passif("garde", [_ligne("armor", 10.0)] as Array[LigneDeTalent], 2, 3)),
	] as Array[CaseDeManuel])


## Un manuel au niveau voulu, avec de quoi payer. L'expérience est donnée par
## paquets plutôt que calculée : la courbe changera, le test non.
func _manuel(niveau: int) -> Manuel:
	var m := Manuel.new()
	while m.niveau() < niveau:
		m.gagner_experience(200)
	return m


func _talents(noeuds: Array, points := 1) -> Array:
	var out := []
	for n: NoeudDeTalent in noeuds:
		out.append(TalentInvesti.new(n, points))
	return out


# --------------------------------------------------------------------------
# Ce qu'une case porte
# --------------------------------------------------------------------------

func test_une_case_dit_ce_qu_elle_porte() -> void:
	var arch := _livre_d_essai()
	assert_eq(arch.cases[0].identifiant(), "sort")
	assert_eq(arch.cases[0].points_max(), 5, "la compétence le déduit de sa table")
	assert_eq(arch.cases[1].identifiant(), "garde")
	assert_eq(arch.cases[1].points_max(), 3, "le passif le déclare")
	assert_eq(arch.cases[1].niveau_requis(), 2)


func test_l_archetype_retrouve_les_trois_sortes() -> void:
	var arch := _livre_d_essai()
	assert_not_null(arch.case_de("sort"), "la case d'une compétence")
	assert_not_null(arch.passif_de("garde"), "un passif")
	assert_not_null(arch.noeud_de("sort_feuille"), "un nœud")
	assert_eq(arch.case_du_noeud("sort_feuille").competence.id, "sort", "et la case qui le porte")

	assert_null(arch.case_de("garde"), "un passif n'est pas une compétence")
	assert_null(arch.passif_de("sort"), "ni l'inverse")
	assert_eq(arch.competences().size(), 1, "une seule compétence")
	assert_eq(arch.passifs().size(), 1, "et un seul passif")


## La question que se pose la relecture d'une sauvegarde : les trois sortes
## partagent le dictionnaire de points, et ce qu'aucune ne reconnaît est jeté.
func test_le_livre_reconnait_ses_trois_sortes_d_identifiants() -> void:
	var arch := _livre_d_essai()
	for id in ["sort", "garde", "sort_branche", "sort_feuille"]:
		assert_true(arch.connait(id), "« %s » est de ce livre" % id)
	assert_false(arch.connait("eclair_vif"), "une compétence d'un autre livre, non")
	assert_false(arch.connait(""), "ni rien du tout")


func test_un_noeud_connait_ses_enfants() -> void:
	var case := _livre_d_essai().cases[0]
	assert_eq(case.enfants_de("sort_branche").size(), 1, "la branche porte la feuille")
	assert_eq(case.enfants_de("sort_branche")[0].id, "sort_feuille")
	assert_eq(case.enfants_de("sort_feuille").size(), 0, "et la feuille ne porte rien")
	assert_eq(case.enfants_de("").size(), 1, "les nœuds sans parent partent de la compétence")


# --------------------------------------------------------------------------
# Ce qu'un point coûte et ce qu'il demande
# --------------------------------------------------------------------------

func test_un_passif_s_investit_comme_une_case() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(1)
	assert_false(m.peut_investir(arch, "garde"), "niveau 1, le passif demande 2")

	m = _manuel(2)
	assert_true(m.investir(arch, "garde"))
	assert_true(m.investir(arch, "garde"))
	assert_eq(m.points_de("garde"), 2)


func test_un_passif_ne_depasse_pas_son_maximum() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(12)
	for i in 3:
		assert_true(m.investir(arch, "garde"), "les trois points du passif")
	assert_false(m.investir(arch, "garde"), "et pas un de plus")
	assert_eq(m.points_de("garde"), 3)


## **Un arbre s'achète après le sort, jamais à sa place.** Sans cette condition,
## un manuel neuf pourrait mettre son premier point dans un nœud d'une compétence
## qu'il ne sait pas encore lancer.
func test_un_noeud_demande_des_points_dans_sa_competence() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(4)
	assert_false(m.peut_investir(arch, "sort_branche"), "aucun point dans le sort")
	assert_true(m.investir(arch, "sort"), "un point dans le sort")
	assert_true(m.investir(arch, "sort_branche"), "et la branche s'ouvre")


func test_un_noeud_demande_son_parent() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(8)
	for i in 2:
		assert_true(m.investir(arch, "sort"))
	assert_false(m.peut_investir(arch, "sort_feuille"), "la branche est vide")
	assert_true(m.investir(arch, "sort_branche"))
	assert_true(m.investir(arch, "sort_feuille"), "la branche portant un point, la feuille s'ouvre")


func test_un_noeud_ne_depasse_pas_son_maximum() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(12)
	assert_true(m.investir(arch, "sort"))
	for i in 3:
		assert_true(m.investir(arch, "sort_branche"), "les trois points de la branche")
	assert_false(m.investir(arch, "sort_branche"), "et pas un de plus")


## Les points sortent du même sac que les cases : c'est ce qui fait du manuel un
## choix plutôt qu'une collection à compléter.
func test_un_noeud_se_paie_avec_les_points_du_manuel() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(2)
	assert_eq(m.points_restants(), 2)
	assert_true(m.investir(arch, "sort"))
	assert_true(m.investir(arch, "sort_branche"))
	assert_eq(m.points_restants(), 0, "les deux points sont dépensés")
	assert_false(m.peut_investir(arch, "sort_branche"), "et plus rien n'entre nulle part")
	assert_false(m.peut_investir(arch, "garde"))


func test_un_identifiant_inconnu_n_accepte_rien() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(6)
	assert_false(m.investir(arch, "sort_qui_n_existe_pas"))
	assert_false(m.investir(null, "sort"))
	assert_eq(m.points_places(), 0)


# --------------------------------------------------------------------------
# Reprendre
# --------------------------------------------------------------------------

func test_reprendre_rend_le_point_au_livre() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(4)
	assert_true(m.investir(arch, "sort"))
	assert_true(m.investir(arch, "sort_branche"))
	var restants := m.points_restants()

	assert_true(m.reprendre(arch, "sort_branche"))
	assert_eq(m.points_de("sort_branche"), 0)
	assert_eq(m.points_restants(), restants + 1, "le point revient")
	assert_false(m.points.has("sort_branche"), "et l'entrée vide disparaît")
	assert_true(m.investir(arch, "garde"), "il se replace ailleurs dans le même livre")


func test_on_ne_reprend_ni_une_case_ni_un_passif() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(6)
	assert_true(m.investir(arch, "sort"))
	assert_true(m.investir(arch, "garde"))
	assert_false(m.peut_reprendre(arch, "sort"), "ce qu'on sait est définitif")
	assert_false(m.reprendre(arch, "garde"), "un passif aussi")
	assert_eq(m.points_de("sort"), 1)
	assert_eq(m.points_de("garde"), 1)


## Reprendre sous un enfant qui porte des points laisserait la branche accrochée
## à un nœud éteint, et le lien dessiné ne voudrait plus rien dire.
func test_on_ne_reprend_pas_sous_un_enfant_investi() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(10)
	for id in ["sort", "sort", "sort_branche", "sort_feuille"]:
		assert_true(m.investir(arch, id), "« %s »" % id)

	assert_false(m.peut_reprendre(arch, "sort_branche"), "la feuille en dépend")
	assert_true(m.reprendre(arch, "sort_feuille"), "la feuille, elle, se reprend")
	assert_true(m.reprendre(arch, "sort_branche"), "et la branche ensuite")


func test_on_ne_reprend_pas_ce_qui_n_a_pas_de_point() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(4)
	assert_false(m.reprendre(arch, "sort_branche"), "rien n'y est placé")
	assert_false(m.reprendre(arch, "inconnu"))
	assert_false(m.reprendre(null, "sort_branche"))


# --------------------------------------------------------------------------
# Ce que le manuel rend au lancer
# --------------------------------------------------------------------------

func test_seuls_les_noeuds_investis_comptent() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(10)
	assert_eq(m.talents_investis(arch, "sort").size(), 0, "un livre neuf n'a aucun talent")

	for id in ["sort", "sort", "sort_branche", "sort_branche"]:
		m.investir(arch, id)
	var talents := m.talents_investis(arch, "sort")
	assert_eq(talents.size(), 1, "le seul nœud investi")
	assert_eq(talents[0].noeud.id, "sort_branche")
	assert_eq(talents[0].points, 2, "avec ses deux points")
	assert_eq(m.talents_investis(arch, "garde").size(), 0, "un passif n'a pas d'arbre")


func test_les_lignes_d_un_passif_suivent_ses_points() -> void:
	var arch := _livre_d_essai()
	var m := _manuel(8)
	assert_eq(m.mods_de_passifs(arch).size(), 0, "zéro point, aucune ligne")

	m.investir(arch, "garde")
	m.investir(arch, "garde")
	var mods := m.mods_de_passifs(arch)
	assert_eq(mods.size(), 1)
	assert_eq(mods[0].stat, "armor")
	assert_eq(mods[0].value, 20.0, "deux points à dix")


func test_une_ligne_de_talent_se_lit_comme_une_ligne_d_objet() -> void:
	assert_null(_ligne("armor", 10.0).modificateur(0), "zéro point ne donne aucune ligne")
	assert_eq(_ligne("armor", 10.0).modificateur(2).label(), "+20 armure")
	assert_eq(_ligne("degats", 12.0, true).modificateur(2).label(), "+24 % dégâts")
	assert_eq(
		_ligne("degats_feu", 4.0, false, "", 9.0).modificateur(2).label(),
		"ajoute 8 à 18 dégâts de feu",
		"une fourchette monte par ses deux bornes, et sans portée elle ne nomme personne"
	)
	assert_eq(
		_ligne("degats_feu", 4.0, false, MotsCles.SORT, 9.0).modificateur(1).label(),
		"ajoute 4 à 9 dégâts de feu aux sorts", "celle d'un passif dit sa famille"
	)


# --------------------------------------------------------------------------
# Ce qu'un nœud change au lancer
# --------------------------------------------------------------------------

func _sort(base: float) -> Competence:
	var c := _competence("sort", [base] as Array[float])
	c.mots_cles_declares = PackedStringArray([MotsCles.PROJECTILE])
	c.vitesse_de_projectile = 200.0
	return c


func test_un_noeud_ajoute_des_degats_et_des_projectiles() -> void:
	var c := _sort(100.0)
	var n := _noeud("n", [
		_ligne("degats", 25.0, true), _ligne("projectiles", 1.0)
	] as Array[LigneDeTalent])
	var r := c.resoudre(1, _fiche(), [], _talents([n]))
	assert_almost_eq(r.total_min(), 125.0, 1e-4)
	assert_eq(r.nombre_de_projectiles(), 2)
	assert_almost_eq(r.accroissement, 1.25, 1e-6, "et la fiche sait le dire")


## **Un nœud ne vise que sa compétence** : ses lignes n'ont pas de portée, et
## c'est tout ce qui les distingue de celles d'un objet. Un coup d'arc qui ne
## porte ni `projectile` ni `foudre` reçoit quand même les siennes.
func test_un_noeud_agit_sans_mot_cle() -> void:
	var epee := _competence("epee", [10.0] as Array[float], DamageType.Kind.PHYSICAL)
	epee.cadence = Competence.Cadence.ARME
	var n := _noeud("n", [_ligne("degats", 50.0, true)] as Array[LigneDeTalent])
	assert_almost_eq(epee.resoudre(1, _fiche(), [], _talents([n])).total_min(), 15.0, 1e-4)


func test_un_noeud_ajoute_une_fourchette_dans_sa_nature() -> void:
	var c := _sort(100.0)
	var n := _noeud("n", [_ligne("degats_feu", 4.0, false, "", 9.0)] as Array[LigneDeTalent])
	var r := c.resoudre(1, _fiche(), [], _talents([n], 2))
	assert_eq(r.ajoutes_min[DamageType.Kind.FIRE], 8.0, "deux points de 4 à 9")
	assert_eq(r.ajoutes_max[DamageType.Kind.FIRE], 18.0)
	assert_eq(r.total_max(), 118.0)


func test_un_noeud_peut_couter_des_degats() -> void:
	var c := _sort(100.0)
	var n := _noeud("n", [
		_ligne("degats", -25.0, true), _ligne("projectiles", 2.0)
	] as Array[LigneDeTalent])
	var r := c.resoudre(1, _fiche(), [], _talents([n]))
	assert_almost_eq(r.total_min(), 75.0, 1e-4, "l'échange est le seul point qui fait baisser")
	assert_eq(r.nombre_de_projectiles(), 3)
	assert_eq(
		r.dispersion_en_degres, StatsDeCompetence.ECART_MINIMAL * 2.0,
		"et trois traits ne partent pas l'un sur l'autre"
	)


# --------------------------------------------------------------------------
# La conversion
# --------------------------------------------------------------------------

func _conversion(id: String, vers: DamageType.Kind, part: float, lignes: Array[LigneDeTalent] = []) -> NoeudDeTalent:
	var n := _noeud(id, lignes)
	n.convertit_vers = vers
	n.part_convertie_par_point = part
	return n


func test_un_noeud_convertit_une_part_des_degats() -> void:
	var r := _sort(100.0).resoudre(
		1, _fiche(), [], _talents([_conversion("n", DamageType.Kind.COLD, 0.5)])
	)
	assert_almost_eq(r.degats_min[DamageType.Kind.LIGHTNING], 50.0, 1e-4, "la moitié reste")
	assert_almost_eq(r.degats_min[DamageType.Kind.COLD], 50.0, 1e-4, "l'autre part")
	assert_almost_eq(r.total_min(), 100.0, 1e-4, "et rien ne se perd en route")
	assert_almost_eq(r.convertis[DamageType.Kind.COLD], 0.5, 1e-4, "la fiche sait le dire")


## Convertie **après** les ajouts : la foudre qu'un anneau ajoute à un sort de
## foudre part avec le reste. Convertie avant, le même objet donnerait deux
## résultats selon l'ordre dans lequel ses lignes arrivent.
func test_la_conversion_emporte_ce_qu_un_objet_ajoute() -> void:
	var ajout := StatMod.fourchette(
		StatsDeCompetence.stat_ajoutee(DamageType.Kind.LIGHTNING), 20.0, 20.0, MotsCles.SORT
	)
	var r := _sort(100.0).resoudre(
		1, _fiche(), [ajout], _talents([_conversion("n", DamageType.Kind.FIRE, 1.0)])
	)
	assert_almost_eq(r.degats_min[DamageType.Kind.LIGHTNING], 0.0, 1e-4, "plus rien de foudre")
	assert_almost_eq(r.degats_min[DamageType.Kind.FIRE], 120.0, 1e-4, "les cent vingt sont du feu")


func test_deux_conversions_prennent_leur_part_de_ce_qui_reste() -> void:
	var noeuds := [
		_conversion("a", DamageType.Kind.FIRE, 0.5), _conversion("b", DamageType.Kind.FIRE, 0.5)
	]
	var r := _sort(100.0).resoudre(1, _fiche(), [], _talents(noeuds))
	assert_almost_eq(r.degats_min[DamageType.Kind.FIRE], 75.0, 1e-4, "deux fois la moitié")
	assert_almost_eq(r.degats_min[DamageType.Kind.LIGHTNING], 25.0, 1e-4)
	assert_almost_eq(
		r.convertis[DamageType.Kind.FIRE], 0.75, 1e-4, "et la fiche annonce 75 %, pas 100 %"
	)


func test_une_conversion_ne_depasse_jamais_le_tout() -> void:
	var r := _sort(100.0).resoudre(
		1, _fiche(), [], _talents([_conversion("n", DamageType.Kind.FIRE, 0.8)], 3)
	)
	assert_almost_eq(r.degats_min[DamageType.Kind.FIRE], 100.0, 1e-4, "trois points à 80 %")
	assert_almost_eq(r.total_min(), 100.0, 1e-4)


## Le multiplicateur passe sur les deux natures : converti avant ou après, le
## total est le même — et c'est ce qui laisse l'ordre libre.
func test_la_conversion_et_les_multiplicateurs_commutent() -> void:
	var c := _sort(100.0)
	c.attribut = "intelligence"
	c.pourcentage_par_attribut = 5.0
	var f := _fiche()
	f.intelligence = 10.0
	var r := c.resoudre(
		1, f, [StatMod.new("degats", StatMod.Mode.PERCENT, 20.0, MotsCles.SORT)],
		_talents([_conversion("n", DamageType.Kind.FIRE, 0.5)])
	)
	assert_almost_eq(r.total_min(), 180.0, 1e-4, "100 × 1,5 × 1,2")
	assert_almost_eq(r.degats_min[DamageType.Kind.FIRE], 90.0, 1e-4, "moitié-moitié")
	assert_almost_eq(r.degats_min[DamageType.Kind.LIGHTNING], 90.0, 1e-4)


# --------------------------------------------------------------------------
# Les mots-clés qu'un nœud donne
# --------------------------------------------------------------------------

## Le nœud le plus cher de son arbre : il ne convertit pas seulement les dégâts,
## il fait mordre l'équipement de la nature d'arrivée.
func test_un_noeud_peut_donner_le_mot_cle_de_sa_nature_d_arrivee() -> void:
	var ardent := StatMod.new("degats", StatMod.Mode.PERCENT, 50.0, MotsCles.FEU)
	var c := _sort(100.0)
	assert_almost_eq(
		c.resoudre(1, _fiche(), [ardent]).total_min(), 100.0, 1e-4,
		"sans le nœud, un affixe de feu ne mord pas sur un sort de foudre"
	)

	var n := _conversion("n", DamageType.Kind.FIRE, 1.0)
	n.mots_cles_ajoutes = PackedStringArray([MotsCles.FEU])
	var r := c.resoudre(1, _fiche(), [ardent], _talents([n]))
	assert_almost_eq(r.total_min(), 150.0, 1e-4, "avec lui, oui")
	assert_true(r.mots_cles.has(MotsCles.FEU), "et la fiche l'affiche")
	assert_true(r.mots_cles.has(MotsCles.FOUDRE), "sans perdre celui de la compétence")


## L'ordre est celui de la liste fermée, pas celui de la source : deux compétences
## voisines doivent se lire colonne contre colonne.
func test_les_mots_cles_resolus_gardent_l_ordre_de_lecture() -> void:
	var n := _conversion("n", DamageType.Kind.FIRE, 1.0)
	n.mots_cles_ajoutes = PackedStringArray([MotsCles.FEU])
	var r := _sort(100.0).resoudre(1, _fiche(), [], _talents([n]))
	assert_eq(
		Array(r.mots_cles), [MotsCles.PROJECTILE, MotsCles.FOUDRE, MotsCles.FEU, MotsCles.SORT]
	)
	assert_eq(r.libelle_des_mots_cles(), "Projectile · Foudre · Feu · Sort")


## Sans talent, la liste est exactement celle de la compétence. C'est le pendant
## de `test_sans_modificateur_la_resolution_rend_la_fiche` : ce jalon ne doit rien
## changer à ce qui se jouait avant lui.
func test_sans_talent_les_mots_cles_sont_ceux_de_la_competence() -> void:
	for c: Competence in CompetenceCatalog.ALL:
		var r := c.resoudre(c.points_max(), CharacterStats.new())
		assert_eq(Array(r.mots_cles), Array(c.mots_cles()), "« %s »" % c.nom)
		assert_eq(r.libelle_des_mots_cles(), c.libelle_des_mots_cles())
		for part in r.convertis:
			assert_eq(part, 0.0, "« %s » : rien n'est converti" % c.nom)


# --------------------------------------------------------------------------
# Le contenu du jeu
# --------------------------------------------------------------------------

## Les archétypes du catalogue, avec leur base pour que l'échec nomme le livre.
func _livres() -> Array[ItemBase]:
	var out: Array[ItemBase] = []
	for base: ItemBase in ItemCatalog.ALL:
		if base.manuel != null:
			out.append(base)
	return out


## Une case qui porte les deux aurait deux compteurs pour un seul identifiant ;
## une case qui ne porte rien est un trou sur la page, et seulement là.
func test_chaque_case_porte_une_chose_et_une_seule() -> void:
	for base in _livres():
		for c in base.manuel.cases:
			var porte := int(c.competence != null) + int(c.passif != null)
			assert_eq(
				porte, 1,
				"« %s » : une case porte %d chose(s)" % [base.manuel.nom, porte]
			)
			if c.passif != null:
				assert_eq(
					c.talents.size(), 0,
					"« %s » : un passif n'a pas d'arbre à orienter" % c.passif.nom
				)


## **Le piège qui ne se voit pas** : cases, passifs et nœuds partagent le
## dictionnaire de points du manuel. Deux identifiants égaux, et le point placé
## dans l'un s'affiche sur l'autre.
func test_les_identifiants_d_un_livre_sont_uniques() -> void:
	for base in _livres():
		var vus := {}
		for c in base.manuel.cases:
			for id in [c.identifiant()] + c.talents.map(func(n: NoeudDeTalent) -> String: return n.id):
				assert_false(
					vus.has(id), "« %s » : « %s » est écrit deux fois" % [base.manuel.nom, id]
				)
				assert_false(String(id).is_empty(), "« %s » : un identifiant vide" % base.manuel.nom)
				vus[id] = true


func test_chaque_noeud_a_un_nom_et_des_effets() -> void:
	for base in _livres():
		for c in base.manuel.cases:
			for n in c.talents:
				assert_false(n.nom.is_empty(), "« %s » n'a pas de nom lisible" % n.id)
				assert_true(
					n.lignes.size() > 0 or n.convertit(),
					"« %s » ne fait rien du tout" % n.id
				)
				assert_gte(n.points_max, 1, "« %s » n'accepte aucun point" % n.id)


## Un nœud dont le parent n'est pas dans le même arbre ne s'ouvrirait jamais, et
## rien à l'écran ne dirait pourquoi.
func test_chaque_parent_existe_dans_le_meme_arbre() -> void:
	for base in _livres():
		for c in base.manuel.cases:
			for n in c.talents:
				if n.parent.is_empty():
					continue
				assert_ne(n.parent, n.id, "« %s » est son propre parent" % n.id)
				assert_not_null(
					c.noeud_de(n.parent),
					"« %s » dépend de « %s », qui n'est pas dans son arbre" % [n.id, n.parent]
				)


## Un arbre dont tous les nœuds ont un parent est un arbre fermé : rien n'y
## accroche le premier point.
func test_chaque_arbre_a_une_racine_et_reste_atteignable() -> void:
	for base in _livres():
		for c in base.manuel.cases:
			if c.talents.is_empty():
				continue
			var racines := 0
			for n in c.talents:
				if n.parent.is_empty():
					racines += 1
				assert_between(
					n.points_requis, 1, c.points_max(),
					"« %s » demande %d points dans une case qui en accepte %d"
						% [n.id, n.points_requis, c.points_max()]
				)
			assert_gt(racines, 0, "« %s » : aucun nœud ne part de la compétence" % c.identifiant())


## La faute de frappe silencieuse, celle des affixes : une ligne qui vise un
## champ inexistant ne casse rien, le point placé ne fait simplement rien.
func test_chaque_ligne_de_noeud_vise_un_nombre_de_lancer() -> void:
	for base in _livres():
		for c in base.manuel.cases:
			for n in c.talents:
				for l in n.lignes:
					assert_true(
						l.portee.is_empty(),
						"« %s » : un nœud ne vise que sa compétence" % n.id
					)
					assert_true(
						StatsDeCompetence.modifiable(l.stat),
						"« %s » vise « %s », qui n'est pas un nombre de lancer" % [n.id, l.stat]
					)


func test_chaque_ligne_de_passif_vise_la_fiche_ou_un_mot_cle() -> void:
	var fiche := CharacterStats.new()
	for base in _livres():
		for passif in base.manuel.passifs():
			assert_false(passif.nom.is_empty(), "« %s » n'a pas de nom lisible" % passif.id)
			assert_gt(passif.lignes.size(), 0, "« %s » ne donne rien" % passif.id)
			assert_gte(passif.points_max, 1, "« %s » n'accepte aucun point" % passif.id)
			for l in passif.lignes:
				if l.portee.is_empty():
					assert_true(
						fiche.get(l.stat) != null and StatMod.LABELS.has(l.stat),
						"« %s » vise « %s », qui n'est pas sur la fiche" % [passif.id, l.stat]
					)
					continue
				assert_true(
					MotsCles.existe(l.portee),
					"« %s » vise le mot-clé « %s », hors de la liste" % [passif.id, l.portee]
				)
				assert_true(
					StatsDeCompetence.modifiable(l.stat),
					"« %s » vise « %s » sur un mot-clé" % [passif.id, l.stat]
				)


## `projectile`, `attaque` et `sort` décident du chemin que prend le lancer : un
## nœud qui les donnerait ferait partir un tir d'une compétence dont la fiche
## annonce un coup d'arc.
func test_un_noeud_ne_donne_qu_un_mot_cle_de_nature() -> void:
	var natures := Competence.MOT_CLE_DE_NATURE.values()
	for base in _livres():
		for c in base.manuel.cases:
			for n in c.talents:
				for id in n.mots_cles_ajoutes:
					assert_true(
						natures.has(id),
						"« %s » donne « %s », qui n'est pas un mot-clé de nature" % [n.id, id]
					)


func test_chaque_conversion_vise_une_autre_nature() -> void:
	for base in _livres():
		for c in base.manuel.cases:
			for n in c.talents:
				if not n.convertit():
					continue
				assert_between(
					n.part_convertie_par_point, 0.01, 1.0,
					"« %s » convertit une part hors des bornes" % n.id
				)
				assert_ne(
					int(n.convertit_vers), int(c.competence.nature),
					"« %s » convertit vers la nature qu'elle a déjà" % n.id
				)


## **Un manuel ne se remplit plus** (jalon 10) : c'est ce qui fait du livre un
## choix et non une collection à compléter, et c'est la décision qu'un contenu
## ajouté sans y penser déferait.
func test_aucun_manuel_ne_se_remplit_entierement() -> void:
	for base in _livres():
		var destinations := 0
		for c in base.manuel.cases:
			destinations += c.points_max()
			for n in c.talents:
				destinations += n.points_max
		assert_gt(
			destinations, Manuel.NIVEAU_MAX,
			"« %s » offre %d points de destination pour %d gagnés"
				% [base.manuel.nom, destinations, Manuel.NIVEAU_MAX]
		)
