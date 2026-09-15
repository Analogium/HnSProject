extends GutTest

## Les états dans le jeu (jalon 12) : posés par la hurtbox, appliqués par ceux qui
## les portent — la vie, la cadence, la marche, les coups —, et montrés.

var _recu := -1.0
var _fx: HitFeedback
var _subis_visibles: bool
var _infliges_visibles: bool
var _duree_du_gel: float


func before_each() -> void:
	_subis_visibles = Settings.degats_subis_visibles
	_infliges_visibles = Settings.degats_infliges_visibles
	_duree_du_gel = Game.hit_stop_duration
	Game.hit_stop_duration = 0.0
	_recu = -1.0
	_fx = HitFeedback.new()
	add_child_autofree(_fx)


func after_each() -> void:
	Settings.degats_subis_visibles = _subis_visibles
	Settings.degats_infliges_visibles = _infliges_visibles
	Game.hit_stop_duration = _duree_du_gel
	Engine.time_scale = 1.0


func _zone(etats: Etats) -> Hurtbox:
	var hb := Hurtbox.new()
	hb.stats = CharacterStats.new()
	hb.etats = etats
	add_child_autofree(hb)
	hb.damaged.connect(func(info: DamageInfo) -> void: _recu = info.amount)
	return hb


func _joueur() -> Player:
	var p: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(p)
	await wait_physics_frames(1)
	return p


func _grunt(ou := Vector2.ZERO) -> Enemy:
	var e: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	e.position = ou
	add_child_autofree(e)
	return e


# --------------------------------------------------------------------------
# La hurtbox
# --------------------------------------------------------------------------

func test_l_engourdi_encaisse_dix_pour_cent_de_plus() -> void:
	var etats := Etats.new()
	var hb := _zone(etats)
	hb.take_damage(DamageInfo.new(20.0, Vector2.ZERO))
	assert_almost_eq(_recu, 20.0, 0.001)
	etats.poser(Etats.Sorte.ENGOURDISSEMENT, 1.0)
	hb.take_damage(DamageInfo.new(20.0, Vector2.ZERO))
	assert_almost_eq(_recu, 22.0, 0.001)


func test_un_auteur_beni_frappe_moins_fort() -> void:
	var hb := _zone(Etats.new())
	var auteur := Etats.new()
	auteur.poser(Etats.Sorte.BENEDICTION, 1.0)
	var info := DamageInfo.new(20.0, Vector2.ZERO)
	info.auteur = auteur
	hb.take_damage(info)
	assert_almost_eq(_recu, 16.0, 0.001)


## Le coup béni est un coup plus petit, et l'armure protège mieux des petits coups :
## appliquée après elle, la bénédiction affaiblirait moins qu'annoncé.
func test_la_benediction_passe_avant_l_armure() -> void:
	var hb := _zone(Etats.new())
	hb.stats.armor = 60.0
	var auteur := Etats.new()
	auteur.poser(Etats.Sorte.BENEDICTION, 1.0)
	var info := DamageInfo.new(15.0, Vector2.ZERO)
	info.auteur = auteur
	hb.take_damage(info)
	assert_almost_eq(_recu, 12.0 * (1.0 - hb.stats.armor_reduction(12.0)), 0.001)


func test_un_coup_elementaire_finit_par_poser_son_etat() -> void:
	var etats := Etats.new()
	var hb := _zone(etats)
	Game.rng.seed = 3
	for i in 200:
		if etats.actif(Etats.Sorte.GEL):
			break
		hb.take_damage(DamageInfo.new(10.0, Vector2.ZERO, 0.0, false, DamageType.Kind.COLD))
	assert_true(etats.actif(Etats.Sorte.GEL), "un coup de froid finit par transir")
	assert_false(etats.actif(Etats.Sorte.EMBRASEMENT), "et ne pose que le sien")


## Le coup d'un grunt ou d'une épée. Une hurtbox sans états, elle, ne tire toujours
## rien — voir `test_hurtbox.gd`.
func test_un_coup_physique_finit_par_faire_saigner() -> void:
	var etats := Etats.new()
	var hb := _zone(etats)
	Game.rng.seed = 5
	for i in 200:
		if etats.actif(Etats.Sorte.SAIGNEMENT):
			break
		hb.take_damage(DamageInfo.new(10.0, Vector2.ZERO))
	assert_true(etats.actif(Etats.Sorte.SAIGNEMENT))
	assert_gt(etats.avancer(1.0), 0.0, "et il saigne")


## Un sort de foudre qui porte un ajout de chaque nature : converti à moitié, les six
## états finissent par tomber ; converti en entier, seul celui de la nature d'arrivée.
func test_un_coup_converti_ne_pose_que_ce_qu_il_porte() -> void:
	Settings.degats_infliges_visibles = false
	for part in [0.5, 1.0]:
		var geste := StatsDeCompetence.new()
		geste.poser_la_base(DamageType.Kind.LIGHTNING, 100.0)
		for nature in DamageType.Kind.size():
			geste.ajouter(nature, 10.0, 10.0)
		geste.convertir(DamageType.Kind.COLD, part)
		var etats := Etats.new()
		var hb := _zone(etats)
		Game.rng.seed = 7
		for i in 3000:
			hb.take_damage(DamageInfo.en_parts(geste.tirer(Game.rng), Vector2.ZERO))
		for sorte in Etats.Sorte.size():
			var attendu: bool = part < 1.0 or sorte == Etats.Sorte.GEL
			assert_eq(etats.actif(sorte), attendu, "%s, converti à %d %%" % [Etats.NOMS[sorte], roundi(part * 100.0)])


# --------------------------------------------------------------------------
# Les ennemis
# --------------------------------------------------------------------------

func test_un_ennemi_meurt_de_sa_brulure_et_rapporte() -> void:
	var joueur := await _joueur()
	var m := EnemyManager.new()
	m.target = joueur
	add_child_autofree(m)
	var e := m.spawn(load("res://actors/enemies/grunt.tscn"), Vector2(300, 0))
	await wait_physics_frames(1)
	e._set_health(5.0)
	e.etats.poser(Etats.Sorte.EMBRASEMENT, 40.0)
	var xp := joueur.xp
	await wait_seconds(1.0)
	assert_false(is_instance_valid(e), "la brûlure l'a tué, par le pilote des ennemis")
	assert_gt(joueur.xp, xp, "et sa mort a rapporté")


func test_un_ennemi_transi_marche_et_recharge_plus_lentement() -> void:
	var e := _grunt()
	var vitesse := e.vitesse_de_deplacement()
	e._attack_cd = 1.0
	e.etats.poser(Etats.Sorte.GEL, 1.0)
	assert_almost_eq(e.vitesse_de_deplacement(), vitesse * 0.75, 0.001)
	e._cool_down(0.4)
	assert_almost_eq(e._attack_cd, 0.7, 0.001, "la recharge en cours ralentit aussi")
	assert_almost_eq(e.sprite.speed_scale, 0.75, 0.001, "et son animation avec")


func test_la_pourriture_d_un_joueur_le_soigne() -> void:
	var joueur := await _joueur()
	joueur._set_health(50.0)
	var e := _grunt(Vector2(300, 0))
	e.etats.poser(Etats.Sorte.POURRITURE, 100.0, joueur.etats)
	e.subir_les_etats(1.0)
	assert_almost_eq(
		joueur.health, 50.0 + 100.0 * Etats.POURRITURE_PAR_SECONDE * Etats.SOIN_DE_POURRITURE, 0.01
	)


func test_la_brulure_d_un_ennemi_s_affiche_en_blanc_derriere_sa_case() -> void:
	var e := _grunt()
	e.etats.poser(Etats.Sorte.EMBRASEMENT, 40.0)
	e.subir_les_etats(0.3)
	assert_eq(_fx._numbers.size(), 0, "pas de chiffre par image")
	e.subir_les_etats(0.3)
	assert_eq(_fx._numbers.size(), 1)
	assert_eq(_fx._numbers[0].tint, HitFeedback.NOMBRE)
	Settings.degats_infliges_visibles = false
	e.subir_les_etats(0.6)
	assert_eq(_fx._numbers.size(), 1, "la case des dégâts infligés la coupe")


func test_un_etat_se_voit_sur_le_corps_et_au_dessus() -> void:
	var e := _grunt()
	assert_false(e.health_bar.visible, "pleine vie : rien au-dessus")
	e.etats.poser(Etats.Sorte.EMBRASEMENT, 1.0)
	assert_true(e.health_bar.visible, "une icône, même à pleine vie")
	assert_eq(e.health_bar._sortes, [Etats.Sorte.EMBRASEMENT] as Array[int])
	assert_almost_eq(float(e.sprite.material.get_shader_parameter("teinte_force")), ActorSprite.TEINTE_D_ETAT, 0.001)
	e.etats.avancer(10.0)
	assert_false(e.health_bar.visible, "l'état fini, la barre se recache")
	assert_eq(float(e.sprite.material.get_shader_parameter("teinte_force")), 0.0)


# --------------------------------------------------------------------------
# Le joueur
# --------------------------------------------------------------------------

func test_un_joueur_transi_recharge_plus_lentement() -> void:
	var joueur := await _joueur()
	joueur.etats.poser(Etats.Sorte.GEL, 1.0)
	# Un pas appelé à la main et non des images attendues : l'attente en compte une
	# de plus ou de moins selon la machine.
	joueur._recharges[0] = 1.0
	joueur._physics_process(0.4)
	assert_almost_eq(joueur._recharges[0], 1.0 - 0.4 * 0.75, 0.001)


func test_un_etat_neuf_s_annonce_au_dessus_du_joueur() -> void:
	var joueur := await _joueur()
	joueur.etats.poser(Etats.Sorte.GEL, 1.0)
	assert_eq(_fx._numbers.size(), 1)
	assert_eq(_fx._numbers[0].text, "transi")
	assert_eq(_fx._numbers[0].tint, Etats.couleur(Etats.Sorte.GEL))
	joueur.etats.poser(Etats.Sorte.GEL, 1.0)
	assert_eq(_fx._numbers.size(), 1, "rafraîchi, il ne se réannonce pas")


## La brûlure d'Immolation est « reçue » comme le reste.
func test_l_engourdissement_amplifie_la_brulure_d_immolation() -> void:
	var joueur := await _joueur()
	joueur.stats.max_health = 100.0
	var feu := DamageType.parts_vides()
	feu[DamageType.Kind.FIRE] = 1.0
	joueur.stats.res_fire = 0.0
	joueur._set_health(100.0)
	joueur.bruler(0.1, feu, 1.0)
	var sans := 100.0 - joueur.health
	joueur._set_health(100.0)
	joueur.etats.poser(Etats.Sorte.ENGOURDISSEMENT, 1.0)
	joueur.bruler(0.1, feu, 1.0)
	assert_almost_eq(100.0 - joueur.health, sans * 1.10, 0.001)


func test_le_tir_d_un_joueur_beni_frappe_moins_fort() -> void:
	var joueur := await _joueur()
	joueur.etats.poser(Etats.Sorte.BENEDICTION, 1.0)
	var cible := Hurtbox.new()
	cible.collision_layer = Cibles.ENNEMIS
	var forme := CollisionShape2D.new()
	var cercle := CircleShape2D.new()
	cercle.radius = 8.0
	forme.shape = cercle
	cible.add_child(forme)
	add_child_autofree(cible)
	cible.global_position = Vector2(60, 0)
	cible.damaged.connect(func(info: DamageInfo) -> void: _recu = info.amount)
	var parts := DamageType.parts_vides()
	parts[DamageType.Kind.LIGHTNING] = 10.0
	Projectile.spawn(self, joueur.bolt_scene, Vector2.ZERO, Vector2.RIGHT, parts, joueur, 300.0)
	await wait_seconds(0.5)
	assert_almost_eq(_recu, 8.0, 0.001, "l'auteur voyage avec le tir")


func test_la_mort_vide_les_etats_du_joueur() -> void:
	var joueur := await _joueur()
	joueur.etats.poser(Etats.Sorte.EMBRASEMENT, 10.0)
	joueur._die()
	assert_true(joueur.etats.aucun)
