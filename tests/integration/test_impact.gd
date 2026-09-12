extends GutTest

## Ce qu'un impact déclenche en dehors des dégâts : le gel et la secousse.
##
## Les deux se jugent à l'œil, et aucun test ne peut dire s'ils sont beaux. Ce
## qu'ils peuvent dire, c'est qu'ils ne s'emballent pas — et c'est exactement ce
## qui manquait : à trois cents ennemis et compétence tenue, le jeu passait 12 %
## de son temps figé à 2 % de vitesse, un gel toutes les 400 ms, sans qu'aucun
## compteur d'images par seconde ne bouge.

var _duree_avant: float
var _periode_avant: float


func before_each() -> void:
	_duree_avant = Game.hit_stop_duration
	_periode_avant = Game.hit_stop_periode
	Game.gels = 0
	# L'autoload survit d'un test à l'autre : sans ça, la période ouverte par le
	# gel du test précédent refuserait le premier appel de celui-ci. Chaque test
	# pose ensuite la sienne.
	Game.hit_stop_periode = 0.0


## Le gel touche à `Engine.time_scale`, qui est **global à la campagne** : un test
## qui le laisserait à deux centièmes ralentirait tous les fichiers suivants.
func after_each() -> void:
	Game.hit_stop_duration = _duree_avant
	Game.hit_stop_periode = _periode_avant
	Engine.time_scale = 1.0


## Attend la fin du gel en cours sur l'horloge réelle. `wait_seconds` de GUT suit
## le temps de jeu, qui n'avance justement plus pendant un gel.
func _attendre_reel(secondes: float) -> void:
	var fin := Time.get_ticks_msec() + roundi(secondes * 1000.0)
	while Time.get_ticks_msec() < fin:
		await get_tree().process_frame


func test_un_gel_fige_puis_rend_la_main() -> void:
	Game.hit_stop_duration = 0.05
	Game.hit_stop()
	assert_almost_eq(Engine.time_scale, 0.02, 0.001, "le jeu est figé")
	await _attendre_reel(0.2)
	assert_eq(Engine.time_scale, 1.0, "et repart tout seul")
	assert_eq(Game.gels, 1)


## Le cœur du réglage : deux impacts qui se suivent de près ne font qu'un gel.
func test_deux_impacts_rapproches_ne_figent_qu_une_fois() -> void:
	Game.hit_stop_duration = 0.05
	Game.hit_stop()
	await _attendre_reel(0.2)   # le gel est fini, le jeu a repris sa vitesse
	# Posée après le premier et non avant : la période se lit à chaque impact,
	# donc celle du test précédent refuserait sinon celui-ci.
	Game.hit_stop_periode = 0.45
	Game.hit_stop()
	assert_eq(Game.gels, 1, "le second impact ne refige pas")
	assert_eq(Engine.time_scale, 1.0, "et le jeu garde sa vitesse")


func test_le_gel_revient_une_fois_la_periode_passee() -> void:
	Game.hit_stop_duration = 0.02
	Game.hit_stop_periode = 0.05
	Game.hit_stop()
	await _attendre_reel(0.25)
	Game.hit_stop()
	assert_eq(Game.gels, 2, "passé la période, l'impact suivant fige à nouveau")
	await _attendre_reel(0.2)


## Une période à zéro rend le comportement d'avant : c'est ce que règle [O] dans
## l'arène, et il ne doit pas se refuser à descendre jusque-là.
func test_une_periode_nulle_laisse_chaque_impact_figer() -> void:
	Game.hit_stop_duration = 0.02
	Game.hit_stop_periode = 0.0
	Game.hit_stop()
	await _attendre_reel(0.1)
	Game.hit_stop()
	assert_eq(Game.gels, 2)
	await _attendre_reel(0.1)


# --------------------------------------------------------------------------
# La secousse
# --------------------------------------------------------------------------


func _camera() -> Camera2D:
	var cam := Camera2D.new()
	add_child_autofree(cam)
	return cam


func test_la_secousse_bouge_la_camera_puis_la_repose() -> void:
	var cam := _camera()
	Game.shake_camera(cam, 4.0, 0.1)
	await wait_process_frames(2)
	assert_ne(cam.offset, Vector2.ZERO, "la caméra bouge")
	await wait_seconds(0.2)
	assert_eq(cam.offset, Vector2.ZERO, "et revient exactement à sa place")


## Cinq ennemis touchés par le même balayage lançaient cinq secousses, qui se
## disputaient le même `offset` : la première finie le remettait à zéro sous les
## autres, et la caméra s'arrêtait net au milieu du geste.
func test_cinq_secousses_a_la_suite_n_en_font_qu_une() -> void:
	var cam := _camera()
	for i in 5:
		Game.shake_camera(cam, 3.0, 0.1)
	await wait_seconds(0.2)
	assert_eq(cam.offset, Vector2.ZERO, "une seule secousse, et elle se termine")


## Relancée plus fort, la secousse prend la plus forte des deux amplitudes plutôt
## que d'en empiler une seconde : un coup dans un paquet secoue comme un coup.
func test_une_secousse_relancee_garde_la_plus_forte() -> void:
	var cam := _camera()
	Game.shake_camera(cam, 1.0, 0.4)
	Game.shake_camera(cam, 12.0, 0.1)
	await wait_process_frames(2)
	assert_gt(cam.offset.length(), 1.5, "l'amplitude forte l'emporte")
	await wait_seconds(0.5)
	assert_eq(cam.offset, Vector2.ZERO)


## **Invariant 3.** La secousse est décorative : ses deux nombres par image
## puisaient dans `Game.rng`, le fil des tirages de la partie, et décalaient donc
## toutes les graines de zone tirées ensuite.
func test_la_secousse_ne_puise_pas_dans_le_hasard_de_la_partie() -> void:
	var cam := _camera()
	var avant := Game.rng.state
	Game.shake_camera(cam, 4.0, 0.1)
	await wait_seconds(0.2)
	assert_eq(Game.rng.state, avant, "le fil des tirages de la partie n'a pas bougé")


## La caméra part avec le joueur quand la zone se recharge. L'ancienne boucle
## tenait sa référence jusqu'au bout ; celle-ci doit s'arrêter d'elle-même.
func test_une_camera_liberee_n_empeche_pas_la_suite() -> void:
	var morte := Camera2D.new()
	add_child(morte)
	Game.shake_camera(morte, 4.0, 0.3)
	morte.free()
	await wait_process_frames(2)

	var vivante := _camera()
	Game.shake_camera(vivante, 4.0, 0.1)
	await wait_process_frames(2)
	assert_ne(vivante.offset, Vector2.ZERO, "la secousse suivante part quand même")
	await wait_seconds(0.2)
	assert_eq(vivante.offset, Vector2.ZERO)


# --------------------------------------------------------------------------
# Le geste entier
# --------------------------------------------------------------------------


## **Le cas qui a motivé tout le reste.** Un balayage qui traverse un paquet
## touche plusieurs ennemis dans la même image : il figeait et secouait une fois
## par cible, alors que c'est un seul coup.
##
## Par `_on_hitbox_area_entered` et non par un vrai contact, comme
## `test_un_coup_d_epee_frappe_tout_l_arc_de_la_meme_valeur` : la fenêtre de la
## hitbox tient à un timer réel, et le nombre de cibles qu'elle attrape varie
## d'un lancement à l'autre.
func test_un_balayage_qui_touche_trois_cibles_ne_fige_qu_une_fois() -> void:
	Game.hit_stop_duration = 0.05
	Game.hit_stop_periode = 0.45

	var joueur: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(joueur)
	await wait_physics_frames(1)
	assert_true(joueur.lancer(0), "le balayage part")

	# Un tableau et non un entier : une lambda GDScript capture les locales par
	# valeur, et un compteur incrémenté dedans ne remonterait jamais ici.
	var recus: Array[float] = []
	for i in 3:
		var cible := Hurtbox.new()
		add_child_autofree(cible)
		cible.damaged.connect(func(info: DamageInfo) -> void: recus.append(info.amount))
		joueur._on_hitbox_area_entered(cible)

	assert_eq(recus.size(), 3, "les trois cibles encaissent")
	assert_eq(Game.gels, 1, "et le geste ne fige qu’une fois")

	await _attendre_reel(0.3)
