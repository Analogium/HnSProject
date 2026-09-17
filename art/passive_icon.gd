class_name PassiveIcon

## L'icône et la couleur d'un nœud de l'arbre de passifs, lues sur **sa première
## ligne** : un notable se reconnaît à son effet principal. Masques 7×7 peints par
## `StatusIcon.paint()`, cernés de noir comme les états.

const MASKS := {
	"gem": [
		"...#...",
		"..###..",
		".##o##.",
		"##ooo##",
		".##o##.",
		"..###..",
		"...#...",
	],
	"heart": [
		".##.##.",
		"#######",
		"##o####",
		"#######",
		".#####.",
		"..###..",
		"...#...",
	],
	"shield": [
		"#######",
		"##ooo##",
		"##ooo##",
		"###o###",
		".#####.",
		"..###..",
		"...#...",
	],
	"boot": [
		"..###..",
		"..###..",
		"..###..",
		"..###..",
		"..####.",
		".######",
		".######",
	],
	"hourglass": [
		"#######",
		".#ooo#.",
		"..#o#..",
		"...#...",
		"..#o#..",
		".#ooo#.",
		"#######",
	],
	"star": [
		"...#...",
		"...#...",
		"#######",
		".##o##.",
		"..###..",
		".##.##.",
		"##...##",
	],
	"sword": [
		"......#",
		".....#.",
		"....#..",
		"#..#...",
		".##....",
		".##....",
		"#..#...",
	],
	"arrow": [
		"....###",
		".....##",
		"....#.#",
		"...#...",
		"..#....",
		"##.....",
		"##.....",
	],
	"orb": [
		"..###..",
		".#ooo#.",
		"#oo#oo#",
		"#o###o#",
		"#oo#oo#",
		".#ooo#.",
		"..###..",
	],
	"burst": [
		"#..#..#",
		".#.#.#.",
		"..###..",
		"###o###",
		"..###..",
		".#.#.#.",
		"#..#..#",
	],
	"hammer": [
		"#####..",
		"#ooo#..",
		"#####..",
		"..#....",
		"..#....",
		"..#....",
		"..#....",
	],
	"flame": StatusIcon.MASKS[StatusEffects.Kind.IGNITE],
	"bolt": StatusIcon.MASKS[StatusEffects.Kind.NUMB],
	"drop": StatusIcon.MASKS[StatusEffects.Kind.BLEED],
}

## Ce qu'une statistique de fiche montre : un masque et sa couleur.
const SHEET := {
	"strength": ["gem", Color(0.90, 0.38, 0.32)],
	"dexterity": ["gem", Color(0.50, 0.85, 0.42)],
	"intelligence": ["gem", Color(0.45, 0.62, 1.00)],
	"max_health": ["heart", Color(0.92, 0.30, 0.38)],
	"health_regen": ["heart", Color(0.92, 0.30, 0.38)],
	"max_mana": ["drop", Color(0.40, 0.62, 1.00)],
	"mana_regen": ["drop", Color(0.40, 0.62, 1.00)],
	"armor": ["shield", Color(0.72, 0.74, 0.80)],
	"evasion": ["boot", Color(0.55, 0.88, 0.70)],
	"move_speed": ["boot", Color(0.55, 0.88, 0.70)],
	"attack_speed": ["hourglass", Color(0.96, 0.86, 0.42)],
	"cast_speed": ["hourglass", Color(0.96, 0.86, 0.42)],
	"crit_chance": ["star", Color(1.00, 0.70, 0.25)],
	"crit_multiplier": ["star", Color(1.00, 0.70, 0.25)],
}

## Des dégâts portés, par mot-clé : la nature dans sa couleur de `DamageType`.
const SCOPED := {
	Keywords.ATTACK: ["sword", Color(0.90, 0.55, 0.35)],
	Keywords.PROJECTILE: ["arrow", Color(0.55, 0.85, 0.45)],
	Keywords.SPELL: ["orb", Color(0.62, 0.62, 1.00)],
	Keywords.MELEE: ["hammer", Color(0.95, 0.42, 0.30)],
	Keywords.AREA: ["burst", Color(0.85, 0.70, 0.95)],
	Keywords.FIRE: ["flame", DamageType.COLORS[DamageType.Kind.FIRE]],
	Keywords.LIGHTNING: ["bolt", DamageType.COLORS[DamageType.Kind.LIGHTNING]],
}

static var _cache := {}


## Le masque et la couleur de la première ligne, ou [] quand rien ne la décrit.
static func look_of(n: PassiveNode) -> Array:
	if n.lines.is_empty():
		return []
	var line := n.lines[0]
	if not line.scope.is_empty():
		return SCOPED.get(line.scope, [])
	var resisted := DamageType.RESIST_FIELDS.find(line.stat)
	if resisted > 0:
		return ["shield", DamageType.COLORS[resisted]]
	return SHEET.get(line.stat, [])


static func texture(n: PassiveNode) -> Texture2D:
	var look := look_of(n)
	if look.is_empty():
		return null
	var key := "%s %s" % look
	if not _cache.has(key):
		_cache[key] = StatusIcon.paint(MASKS[look[0]], look[1])
	return _cache[key]
