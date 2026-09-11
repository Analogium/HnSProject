extends GutTest

## La nature d'un tir appartient à sa scène, pas au geste de le lancer.


func test_chaque_bille_porte_sa_nature() -> void:
	var joueur: Projectile = load("res://actors/projectiles/player_bolt.tscn").instantiate()
	var caster: Projectile = load("res://actors/projectiles/enemy_bolt.tscn").instantiate()
	autofree(joueur)
	autofree(caster)
	assert_eq(joueur.damage_type, DamageType.Kind.LIGHTNING, "le joueur lance de la foudre")
	assert_eq(caster.damage_type, DamageType.Kind.COLD, "le caster lance du froid")


## Deux tirs de la même couleur seraient indiscernables à l'écran.
func test_les_deux_tirs_se_distinguent() -> void:
	var a: Projectile = load("res://actors/projectiles/player_bolt.tscn").instantiate()
	var b: Projectile = load("res://actors/projectiles/enemy_bolt.tscn").instantiate()
	autofree(a)
	autofree(b)
	assert_ne(a.damage_type, b.damage_type)


## Trop court, le tir naît dans le corps et touche son lanceur.
func test_le_tir_nait_devant_son_lanceur() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var b := Projectile.spawn(
		parent, load("res://actors/projectiles/player_bolt.tscn"),
		Vector2.ZERO, Vector2.RIGHT, 7.0, null
	)
	assert_not_null(b)
	assert_almost_eq(b.global_position.x, Projectile.MUZZLE, 0.001)


## La vitesse vient de la compétence quand on la donne, de la scène sinon : les
## tirs ennemis n'ont pas de compétence, et ils doivent garder la leur.
func test_la_vitesse_donnee_l_emporte_sur_celle_de_la_scene() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var scene: PackedScene = load("res://actors/projectiles/enemy_bolt.tscn")
	var de_la_scene: Projectile = scene.instantiate()
	autofree(de_la_scene)

	var sans := Projectile.spawn(parent, scene, Vector2.ZERO, Vector2.RIGHT, 1.0, null)
	var avec := Projectile.spawn(parent, scene, Vector2.ZERO, Vector2.RIGHT, 1.0, null, 310.0)
	assert_eq(sans.speed, de_la_scene.speed, "sans vitesse donnée, celle de la scène")
	assert_eq(avec.speed, 310.0, "sinon celle qu'on donne")
