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
	var b := Projectile.spawn_d_une_nature(
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

	var sans := Projectile.spawn(parent, scene, Vector2.ZERO, Vector2.RIGHT, DamageType.parts_vides(), null)
	var avec := Projectile.spawn(
		parent, scene, Vector2.ZERO, Vector2.RIGHT, DamageType.parts_vides(), null, 310.0
	)
	assert_eq(sans.speed, de_la_scene.speed, "sans vitesse donnée, celle de la scène")
	assert_eq(avec.speed, 310.0, "sinon celle qu'on donne")


## Un tir ennemi porte son nombre dans la nature de sa scène, et dans aucune
## autre : elle n'est écrite qu'à un endroit, l'inspecteur de `enemy_bolt.tscn`.
func test_un_tir_ennemi_porte_la_nature_de_sa_scene() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var b := Projectile.spawn_d_une_nature(
		parent, load("res://actors/projectiles/enemy_bolt.tscn"),
		Vector2.ZERO, Vector2.RIGHT, 5.0, null
	)
	assert_eq(b._parts[DamageType.Kind.COLD], 5.0)
	assert_eq(DamageInfo.en_parts(b._parts, Vector2.ZERO).amount, 5.0, "et rien d'autre")


## Un tir garde la couleur de sa scène, quoi qu'il porte : un éclair chargé
## surtout de froid par un objet reste un éclair. Ses parts, elles, sont celles du
## lancer.
func test_un_tir_garde_la_couleur_de_sa_scene_quelles_que_soient_ses_parts() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var parts := DamageType.parts_vides()
	parts[DamageType.Kind.LIGHTNING] = 3.0
	parts[DamageType.Kind.COLD] = 9.0
	var b := Projectile.spawn(
		parent, load("res://actors/projectiles/player_bolt.tscn"),
		Vector2.ZERO, Vector2.RIGHT, parts, null
	)
	assert_eq(b.damage_type, DamageType.Kind.LIGHTNING, "un éclair reste un éclair")
	assert_eq(b._parts[DamageType.Kind.COLD], 9.0, "et porte bien son froid")
