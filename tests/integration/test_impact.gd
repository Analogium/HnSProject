extends GutTest

## Ce qu'un impact déclenche en dehors des dégâts : le gel et la secousse.
##
## Les deux se jugent à l'œil, et aucun test ne peut dire s'ils sont beaux. Ce
## qu'ils peuvent dire, c'est qu'ils ne s'emballent pas — et c'est exactement ce
## qui manquait : à trois cents ennemis et compétence tenue, le jeu passait 12 %
## de son temps figé à 2 % de vitesse, un gel toutes les 400 ms, sans qu'aucun
## compteur d'images par seconde ne bouge.

var _duration_before: float
var _period_before: float


func before_each() -> void:
	_duration_before = Game.hit_stop_duration
	_period_before = Game.hit_stop_period
	Game.freezes = 0
	# L'autoload survit d'un test à l'autre : sans ça, la période ouverte par le
	# gel du test précédent refuserait le premier appel de celui-ci. Chaque test
	# pose ensuite la sienne.
	Game.hit_stop_period = 0.0


## Le gel touche à `Engine.time_scale`, qui est **global à la campagne** : un test
## qui le laisserait à deux centièmes ralentirait tous les fichiers suivants.
func after_each() -> void:
	Game.hit_stop_duration = _duration_before
	Game.hit_stop_period = _period_before
	Engine.time_scale = 1.0


## Attend la fin du gel en cours sur l'horloge réelle. `wait_seconds` de GUT suit
## le temps de jeu, qui n'avance justement plus pendant un gel.
func _wait_real(seconds: float) -> void:
	var end := Time.get_ticks_msec() + roundi(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		await get_tree().process_frame


func test_a_freeze_freezes_then_releases() -> void:
	Game.hit_stop_duration = 0.05
	Game.hit_stop()
	assert_almost_eq(Engine.time_scale, 0.02, 0.001, "le jeu est figé")
	await _wait_real(0.2)
	assert_eq(Engine.time_scale, 1.0, "et repart tout seul")
	assert_eq(Game.freezes, 1)


## Le cœur du réglage : deux impacts qui se suivent de près ne font qu'un gel.
func test_two_close_impacts_freeze_only_once() -> void:
	Game.hit_stop_duration = 0.05
	Game.hit_stop()
	await _wait_real(0.2)   # le gel est fini, le jeu a repris sa vitesse
	# Posée après le premier et non avant : la période se lit à chaque impact,
	# donc celle du test précédent refuserait sinon celui-ci.
	Game.hit_stop_period = 0.45
	Game.hit_stop()
	assert_eq(Game.freezes, 1, "le second impact ne refige pas")
	assert_eq(Engine.time_scale, 1.0, "et le jeu garde sa vitesse")


func test_the_freeze_returns_once_the_period_passes() -> void:
	Game.hit_stop_duration = 0.02
	Game.hit_stop_period = 0.05
	Game.hit_stop()
	await _wait_real(0.25)
	Game.hit_stop()
	assert_eq(Game.freezes, 2, "passé la période, l'impact suivant fige à nouveau")
	await _wait_real(0.2)


## Une période à zéro rend le comportement d'avant : c'est ce que règle [O] dans
## l'arène, et il ne doit pas se refuser à descendre jusque-là.
func test_a_zero_period_lets_each_impact_freeze() -> void:
	Game.hit_stop_duration = 0.02
	Game.hit_stop_period = 0.0
	Game.hit_stop()
	await _wait_real(0.1)
	Game.hit_stop()
	assert_eq(Game.freezes, 2)
	await _wait_real(0.1)


# --------------------------------------------------------------------------
# La secousse
# --------------------------------------------------------------------------


func _camera() -> Camera2D:
	var cam := Camera2D.new()
	add_child_autofree(cam)
	return cam


func test_the_shake_moves_the_camera_then_settles_it() -> void:
	var cam := _camera()
	Game.shake_camera(cam, 4.0, 0.1)
	await wait_process_frames(2)
	assert_ne(cam.offset, Vector2.ZERO, "la caméra bouge")
	await wait_seconds(0.2)
	assert_eq(cam.offset, Vector2.ZERO, "et revient exactement à sa place")


## Cinq ennemis touchés par le même balayage lançaient cinq secousses, qui se
## disputaient le même `offset` : la première finie le remettait à zéro sous les
## autres, et la caméra s'arrêtait net au milieu du geste.
func test_five_shakes_in_a_row_make_only_one() -> void:
	var cam := _camera()
	for i in 5:
		Game.shake_camera(cam, 3.0, 0.1)
	await wait_seconds(0.2)
	assert_eq(cam.offset, Vector2.ZERO, "une seule secousse, et elle se termine")


## Relancée plus fort, la secousse prend la plus forte des deux amplitudes plutôt
## que d'en empiler une seconde : un coup dans un paquet secoue comme un coup.
func test_a_restarted_shake_keeps_the_strongest() -> void:
	var cam := _camera()
	Game.shake_camera(cam, 1.0, 0.4)
	Game.shake_camera(cam, 12.0, 0.1)
	# Le plus grand décalage sur quelques images, et non celui d'une seule : chaque
	# image tire son décalage au hasard, et une seule peut tomber près de zéro.
	var biggest := 0.0
	for i in 6:
		await wait_process_frames(1)
		biggest = maxf(biggest, cam.offset.length())
	assert_gt(biggest, 1.5, "l'amplitude forte l'emporte")
	await wait_seconds(0.5)
	assert_eq(cam.offset, Vector2.ZERO)


## **Invariant 3.** La secousse est décorative : ses deux nombres par image
## puisaient dans `Game.rng`, le fil des tirages de la partie, et décalaient donc
## toutes les graines de zone tirées ensuite.
func test_the_shake_does_not_draw_from_the_game_randomness() -> void:
	var cam := _camera()
	var before := Game.rng.state
	Game.shake_camera(cam, 4.0, 0.1)
	await wait_seconds(0.2)
	assert_eq(Game.rng.state, before, "le fil des tirages de la partie n'a pas bougé")


## La caméra part avec le joueur quand la zone se recharge. L'ancienne boucle
## tenait sa référence jusqu'au bout ; celle-ci doit s'arrêter d'elle-même.
func test_a_freed_camera_does_not_block_what_follows() -> void:
	var dead := Camera2D.new()
	add_child(dead)
	Game.shake_camera(dead, 4.0, 0.3)
	dead.free()
	await wait_process_frames(2)

	var alive := _camera()
	Game.shake_camera(alive, 4.0, 0.1)
	await wait_process_frames(2)
	assert_ne(alive.offset, Vector2.ZERO, "la secousse suivante part quand même")
	await wait_seconds(0.2)
	assert_eq(alive.offset, Vector2.ZERO)


# --------------------------------------------------------------------------
# Le geste entier
# --------------------------------------------------------------------------


## **Le cas qui a motivé tout le reste.** Un balayage qui traverse un paquet
## touche plusieurs ennemis dans la même image : il figeait et secouait une fois
## par cible, alors que c'est un seul coup.
##
## Par `_on_hitbox_area_entered` et non par un vrai contact, comme
## `test_a_sword_swing_hits_the_whole_arc_for_the_same_value` : la fenêtre de la
## hitbox tient à un timer réel, et le nombre de cibles qu'elle attrape varie
## d'un lancement à l'autre.
func test_a_sweep_hitting_three_targets_freezes_only_once() -> void:
	Game.hit_stop_duration = 0.05
	Game.hit_stop_period = 0.45

	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	await wait_physics_frames(1)
	assert_true(player.cast_slot(0), "le balayage part")

	# Un tableau et non un entier : une lambda GDScript capture les locales par
	# valeur, et un compteur incrémenté dedans ne remonterait jamais ici.
	var received_all: Array[float] = []
	for i in 3:
		var target := Hurtbox.new()
		add_child_autofree(target)
		target.damaged.connect(func(info: DamageInfo) -> void: received_all.append(info.amount))
		player._on_hitbox_area_entered(target)

	assert_eq(received_all.size(), 3, "les trois cibles encaissent")
	assert_eq(Game.freezes, 1, "et le geste ne fige qu’une fois")

	await _wait_real(0.3)
