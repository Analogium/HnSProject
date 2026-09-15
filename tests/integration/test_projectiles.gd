extends GutTest

## La nature d'un tir appartient à sa scène, pas au geste de le lancer.


func test_each_pellet_carries_its_nature() -> void:
	var player: Projectile = load("res://actors/projectiles/player_bolt.tscn").instantiate()
	var caster: Projectile = load("res://actors/projectiles/enemy_bolt.tscn").instantiate()
	autofree(player)
	autofree(caster)
	assert_eq(player.damage_type, DamageType.Kind.LIGHTNING, "le joueur lance de la foudre")
	assert_eq(caster.damage_type, DamageType.Kind.COLD, "le caster lance du froid")


## Deux tirs de la même couleur seraient indiscernables à l'écran.
func test_the_two_bolts_are_distinguishable() -> void:
	var a: Projectile = load("res://actors/projectiles/player_bolt.tscn").instantiate()
	var b: Projectile = load("res://actors/projectiles/enemy_bolt.tscn").instantiate()
	autofree(a)
	autofree(b)
	assert_ne(a.damage_type, b.damage_type)


## Trop court, le tir naît dans le corps et touche son lanceur.
func test_the_bolt_spawns_in_front_of_its_caster() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var b := Projectile.spawn_of_nature(
		parent, load("res://actors/projectiles/player_bolt.tscn"),
		Vector2.ZERO, Vector2.RIGHT, 7.0, null
	)
	assert_not_null(b)
	assert_almost_eq(b.global_position.x, Projectile.MUZZLE, 0.001)


## La vitesse vient de la compétence quand on la donne, de la scène sinon : les
## tirs ennemis n'ont pas de compétence, et ils doivent garder la leur.
func test_the_given_speed_wins_over_the_scene_one() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var scene: PackedScene = load("res://actors/projectiles/enemy_bolt.tscn")
	var from_scene: Projectile = scene.instantiate()
	autofree(from_scene)

	var without := Projectile.spawn(parent, scene, Vector2.ZERO, Vector2.RIGHT, DamageType.empty_parts(), null)
	var with_it := Projectile.spawn(
		parent, scene, Vector2.ZERO, Vector2.RIGHT, DamageType.empty_parts(), null, 310.0
	)
	assert_eq(without.speed, from_scene.speed, "sans vitesse donnée, celle de la scène")
	assert_eq(with_it.speed, 310.0, "sinon celle qu'on donne")


## Un tir ennemi porte son nombre dans la nature de sa scène, et dans aucune
## autre : elle n'est écrite qu'à un endroit, l'inspecteur de `enemy_bolt.tscn`.
func test_an_enemy_bolt_carries_its_scene_nature() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var b := Projectile.spawn_of_nature(
		parent, load("res://actors/projectiles/enemy_bolt.tscn"),
		Vector2.ZERO, Vector2.RIGHT, 5.0, null
	)
	assert_eq(b._parts[DamageType.Kind.COLD], 5.0)
	assert_eq(DamageInfo.as_parts(b._parts, Vector2.ZERO).amount, 5.0, "et rien d'autre")


## Un tir garde la couleur de sa scène, quoi qu'il porte : un éclair chargé
## surtout de froid par un objet reste un éclair. Ses parts, elles, sont celles du
## lancer.
func test_a_bolt_keeps_its_scene_color_whatever_its_parts() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.LIGHTNING] = 3.0
	parts[DamageType.Kind.COLD] = 9.0
	var b := Projectile.spawn(
		parent, load("res://actors/projectiles/player_bolt.tscn"),
		Vector2.ZERO, Vector2.RIGHT, parts, null
	)
	assert_eq(b.damage_type, DamageType.Kind.LIGHTNING, "un éclair reste un éclair")
	assert_eq(b._parts[DamageType.Kind.COLD], 9.0, "et porte bien son froid")
