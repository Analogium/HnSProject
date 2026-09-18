extends GutTest

## Le bandeau : ce qu'il montre des gestes entretenus, et où il le pose.
##
## La taille est celle du cadrage logique (invariant 6) : le bandeau calcule ses
## positions à la main, et une taille inventée validerait une mise en page qui n'est
## pas celle du jeu.

const VIEWPORT := Vector2(640.0, 360.0)

var _p: Player
var _hud: Hud


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	_hud = Hud.new()
	_hud.size = VIEWPORT
	add_child_autofree(_hud)
	await wait_process_frames(1)
	_hud.bind(_p)


func _lit(ids: Array) -> void:
	var skills: Array[Skill] = []
	for id: String in ids:
		skills.append(SkillCatalog.by_id(id))
	_hud._lit = skills


## À gauche des jauges, dans le cadrage, et jamais l'un sur l'autre : trois icônes
## côte à côte sont le pire cas du jeu — une aura et deux buffs.
func test_the_lit_row_stays_left_of_the_gauges() -> void:
	_lit(["immolation", "ignition", "static_electricity"])
	var previous := Rect2()
	for i in 3:
		var r := _hud._buff_rect(i)
		assert_lt(r.end.x, _hud._gauges_x(), "le geste %d reste à gauche des jauges" % i)
		assert_gt(r.position.x, 0.0, "et dans le cadrage")
		assert_lt(r.end.y, VIEWPORT.y, "sans déborder par le bas")
		if i > 0:
			assert_lte(r.end.x, previous.position.x, "sans couvrir le précédent")
		previous = r


## Le cadre ne descend jamais sous le bloc des deux jauges : il se lit avec elles.
func test_the_row_sits_on_the_gauges_block() -> void:
	_lit(["immolation"])
	var r := _hud._buff_rect(0)
	assert_lte(
		r.end.y, VIEWPORT.y - Hud.MANA_TOP + Hud.BAR_H + Hud.BUFF_SIDE * 0.5,
		"il reste sur la bande des jauges"
	)


## Le bandeau suit le joueur sans qu'on l'appelle : allumer une case remplit la ligne,
## l'éteindre la vide.
func test_lighting_a_gesture_fills_the_row() -> void:
	assert_eq(_hud._lit.size(), 0, "rien d'allumé au départ")
	var book := Item.new(ItemCatalog.by_id("manual_fire"))
	book.manual.gain_experience(999999)
	_p.study(book, 0)
	assert_true(_p.invest(0, "ignition"))
	_p.bar.put(2, "ignition")
	_p.equip(Item.new(ItemCatalog.by_id("wand")), EquipmentSlots.WEAPON)

	assert_true(_p.cast_slot(2))
	assert_eq(_hud._lit.size(), 1, "la ligne montre le geste allumé")
	assert_eq(_hud._lit[0].id, "ignition")

	_p._recharges[2] = 0.0
	assert_true(_p.cast_slot(2))
	assert_eq(_hud._lit.size(), 0, "et se vide quand il s'éteint")
