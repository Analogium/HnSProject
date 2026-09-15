extends GutTest

## Les états qu'un coup laisse derrière lui (jalon 12) : quand ils se posent, ce
## qu'ils changent, ce qu'ils brûlent et quand ils s'en vont. Unitaires : `Etats` ne
## connaît ni nœud ni coup, seulement des parts, un auteur et un tirage.

## Des membres et non des locales : une lambda GDScript capture par valeur.
var _changes := 0
var _soins := 0.0


func _parts(nature: DamageType.Kind, montant: float) -> Array[float]:
	var p := DamageType.parts_vides()
	p[nature] = montant
	return p


func test_chaque_nature_pose_un_etat_et_un_seul() -> void:
	assert_eq(Etats.NATURES.size(), Etats.Sorte.size())
	assert_eq(Etats.NOMS.size(), Etats.Sorte.size())
	assert_eq(Etats.DUREES.size(), Etats.Sorte.size())
	for nature in DamageType.Kind.size():
		assert_eq(Etats.NATURES.count(nature), 1, DamageType.NAMES[nature])


## Une pastille qui ressemble à une autre ne dit plus lequel des deux on porte.
func test_chaque_etat_a_sa_couleur() -> void:
	for a in Etats.Sorte.size():
		for b in range(a + 1, Etats.Sorte.size()):
			assert_ne(Etats.couleur(a), Etats.couleur(b), "%s et %s" % [Etats.NOMS[a], Etats.NOMS[b]])
	assert_ne(Etats.couleur(Etats.Sorte.SAIGNEMENT), HealthBar.LOW, "le sang n'est pas une barre basse")


## Tous les états se portent à la fois, et ce qui brûle s'additionne : seuls deux
## états de la même sorte ne se cumulent pas.
func test_tous_les_etats_se_portent_ensemble() -> void:
	var e := Etats.new()
	for sorte in Etats.Sorte.size():
		e.poser(sorte, 40.0)
	for sorte in Etats.Sorte.size():
		assert_true(e.actif(sorte), Etats.NOMS[sorte])
	assert_eq(e.couleurs().size(), Etats.Sorte.size())
	var par_seconde := 40.0 * (
		Etats.EMBRASEMENT_PAR_SECONDE + Etats.POURRITURE_PAR_SECONDE + Etats.SAIGNEMENT_PAR_SECONDE
	) * (1.0 + Etats.ENGOURDISSEMENT)
	assert_almost_eq(e.avancer(0.5), par_seconde * 0.5, 0.0001, "les trois brûlures ensemble, engourdissement compris")


## **Invariant 3.** Un coup tire une fois par nature qu'il porte, physique compris,
## qu'il pose quelque chose ou non. Un coup nul ne tire rien.
func test_un_tirage_par_nature_presente_quel_que_soit_le_resultat() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var avant := rng.state
	Etats.new().subir(DamageType.parts_vides(), null, rng)
	assert_eq(rng.state, avant, "un coup nul ne tire rien")

	var mele := DamageType.parts_vides()
	mele[DamageType.Kind.PHYSICAL] = 10.0
	mele[DamageType.Kind.FIRE] = 10.0
	mele[DamageType.Kind.COLD] = 10.0
	var temoin := RandomNumberGenerator.new()
	temoin.seed = 42
	temoin.state = rng.state
	temoin.randf()
	temoin.randf()
	temoin.randf()
	Etats.new().subir(mele, null, rng)
	assert_eq(rng.state, temoin.state, "trois natures, trois tirages")


## Le froid qu'un anneau met dans un éclair ne gèle pas aussi souvent qu'un sort de
## froid : la chance se partage selon les parts.
func test_la_chance_suit_la_part_de_la_nature() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mele := DamageType.parts_vides()
	mele[DamageType.Kind.FIRE] = 10.0
	mele[DamageType.Kind.PHYSICAL] = 10.0
	var pur := 0
	var moitie := 0
	for i in 4000:
		var a := Etats.new()
		a.subir(_parts(DamageType.Kind.FIRE, 10.0), null, rng)
		pur += int(a.actif(Etats.Sorte.EMBRASEMENT))
		var b := Etats.new()
		b.subir(mele, null, rng)
		moitie += int(b.actif(Etats.Sorte.EMBRASEMENT))
	# Fenêtres larges : on vérifie la règle, pas la qualité du générateur.
	assert_between(pur, 680, 920, "un coup de feu pur embrase une fois sur cinq")
	assert_between(moitie, 320, 480, "à moitié de feu, une fois sur dix")


func test_ce_que_changent_les_trois_etats_qui_ne_brulent_pas() -> void:
	var e := Etats.new()
	assert_eq(e.facteur_de_degats_subis, 1.0)
	assert_eq(e.facteur_de_degats_infliges, 1.0)
	assert_eq(e.facteur_de_vitesse, 1.0)
	e.poser(Etats.Sorte.ENGOURDISSEMENT, 5.0)
	e.poser(Etats.Sorte.BENEDICTION, 5.0)
	e.poser(Etats.Sorte.GEL, 5.0)
	assert_almost_eq(e.facteur_de_degats_subis, 1.10, 0.0001, "engourdi : +10 % de dégâts reçus")
	assert_almost_eq(e.facteur_de_degats_infliges, 0.80, 0.0001, "béni : −20 % de dégâts infligés")
	assert_almost_eq(e.facteur_de_vitesse, 0.75, 0.0001, "transi : −25 % de vitesse d'action")
	assert_eq(e.avancer(1.0), 0.0, "aucun des trois ne brûle")


func test_un_etat_se_rafraichit_puis_s_en_va() -> void:
	var e := Etats.new()
	_changes = 0
	e.change.connect(func() -> void: _changes += 1)
	e.poser(Etats.Sorte.GEL, 1.0)
	assert_eq(_changes, 1, "il apparaît")
	e.avancer(1.5)
	e.poser(Etats.Sorte.GEL, 1.0)
	assert_almost_eq(e.restant(Etats.Sorte.GEL), Etats.DUREES[Etats.Sorte.GEL], 0.0001, "un nouveau coup rend la durée")
	assert_eq(_changes, 1, "rafraîchir ne redessine rien")
	e.avancer(Etats.DUREES[Etats.Sorte.GEL] + 0.01)
	assert_false(e.actif(Etats.Sorte.GEL))
	assert_eq(_changes, 2, "et sa fin se voit")


func test_l_embrasement_rejoue_le_feu_recu_sur_sa_duree() -> void:
	var e := Etats.new()
	e.poser(Etats.Sorte.EMBRASEMENT, 20.0)
	var total := 0.0
	for i in 100:
		total += e.avancer(0.05)
	assert_almost_eq(total, 20.0, 0.001, "le coup se rejoue en entier, et pas une braise de plus")
	assert_false(e.actif(Etats.Sorte.EMBRASEMENT))


func test_un_embrasement_plus_faible_ne_remplace_pas_le_plus_fort() -> void:
	var e := Etats.new()
	e.poser(Etats.Sorte.EMBRASEMENT, 40.0)
	e.avancer(2.0)
	e.poser(Etats.Sorte.EMBRASEMENT, 4.0)
	assert_almost_eq(e.restant(Etats.Sorte.EMBRASEMENT), 2.0, 0.0001, "la petite braise n'éteint pas la grosse")
	e.poser(Etats.Sorte.EMBRASEMENT, 80.0)
	assert_almost_eq(e.restant(Etats.Sorte.EMBRASEMENT), 4.0, 0.0001, "la plus forte la remplace")
	assert_almost_eq(e.avancer(1.0), 80.0 * Etats.EMBRASEMENT_PAR_SECONDE, 0.0001)


func test_l_engourdissement_amplifie_ce_qui_brule() -> void:
	var e := Etats.new()
	e.poser(Etats.Sorte.EMBRASEMENT, 40.0)
	var sans := e.avancer(0.5)
	e.poser(Etats.Sorte.ENGOURDISSEMENT, 1.0)
	assert_almost_eq(e.avancer(0.5), sans * 1.10, 0.0001)


func test_la_pourriture_soigne_celui_qui_l_a_posee() -> void:
	var auteur := Etats.new()
	_soins = 0.0
	auteur.soin.connect(func(montant: float) -> void: _soins += montant)
	var victime := Etats.new()
	victime.poser(Etats.Sorte.POURRITURE, 50.0, auteur)
	var perdu := 0.0
	for i in 10:
		perdu += victime.avancer(0.1)
	assert_almost_eq(perdu, 50.0 * Etats.POURRITURE_PAR_SECONDE, 0.0001, "une petite brûlure")
	assert_almost_eq(_soins, perdu * Etats.SOIN_DE_POURRITURE, 0.0001, "dont la moitié revient à son auteur")


func test_un_auteur_disparu_ne_soigne_personne() -> void:
	var victime := Etats.new()
	var auteur := Etats.new()
	victime.poser(Etats.Sorte.POURRITURE, 50.0, auteur)
	auteur = null
	assert_gt(victime.avancer(0.5), 0.0, "la pourriture lui survit, sans erreur")


## La raison de la référence faible : deux RefCounted qui se tiennent ne sont jamais
## libérés, et un joueur et un ennemi qui se pourrissent l'un l'autre fuiraient.
func test_deux_pourritures_croisees_ne_se_tiennent_pas_en_vie() -> void:
	var a := Etats.new()
	var b := Etats.new()
	a.poser(Etats.Sorte.POURRITURE, 1.0, b)
	b.poser(Etats.Sorte.POURRITURE, 1.0, a)
	var temoin: WeakRef = weakref(a)
	a = null
	b = null
	assert_null(temoin.get_ref())


func test_le_chiffre_d_une_brulure_s_envole_par_demi_seconde() -> void:
	var e := Etats.new()
	e.poser(Etats.Sorte.EMBRASEMENT, 40.0)   # dix par seconde
	e.avancer(0.3)
	assert_eq(e.chiffre(), 0.0, "pas de chiffre par image")
	e.avancer(0.3)
	assert_almost_eq(e.chiffre(), 6.0, 0.0001, "ce qu'ont brûlé les deux pas")
	assert_eq(e.chiffre(), 0.0, "et il ne se lit qu'une fois")
	var montre := 0.0
	for i in 40:
		e.avancer(0.1)
		montre += e.chiffre()
	assert_almost_eq(montre, 34.0, 0.001, "la dernière demi-seconde ne disparaît pas de l'écran")


func test_vider_efface_tout_et_le_dit() -> void:
	var e := Etats.new()
	e.poser(Etats.Sorte.EMBRASEMENT, 40.0)
	e.poser(Etats.Sorte.GEL, 1.0)
	_changes = 0
	e.change.connect(func() -> void: _changes += 1)
	e.vider()
	assert_true(e.aucun)
	assert_eq(_changes, 1)
	assert_eq(e.avancer(1.0), 0.0)
