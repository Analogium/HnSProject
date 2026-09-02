class_name ArtPalette

## Fabrique les rampes de couleurs de tout le jeu à partir d'une seule teinte.
##
## Une rampe = LEVELS teintes ordonnées de la plus sombre à la plus claire.
## Le point important : les ombres ne sont **pas** la couleur de base assombrie,
## et les lumières ne sont pas la couleur de base éclaircie. On tire les ombres
## vers un violet froid et les lumières vers un blanc chaud. C'est le seul
## détail qui sépare un dégradé fade d'une vraie rampe de pixel art — sans lui,
## tous les sprites générés se ressemblent et paraissent en plastique.
##
## Toute la direction artistique passe par ici : changer SHADOW_TINT et
## LIGHT_TINT retend l'ambiance du jeu entier d'un coup.

const LEVELS := 5

## Violet froid : la couleur d'une ombre, ce n'est jamais du noir.
const SHADOW_TINT := Color(0.13, 0.09, 0.24)
## Blanc chaud : la lumière est une torche ou un soleil, pas un néon.
const LIGHT_TINT := Color(1.0, 0.94, 0.76)

## Où la couleur de base se place dans la rampe. En dessous on assombrit, au
## dessus on éclaircit. 0.6 laisse plus de place aux ombres qu'aux lumières,
## ce qui est le bon rapport : un sprite est majoritairement dans son ombre.
const BASE_STOP := 0.6

const SHADOW_STRENGTH := 0.78
const LIGHT_STRENGTH := 0.42


static func ramp(base: Color) -> PackedColorArray:
	var out := PackedColorArray()
	for i in LEVELS:
		var t := float(i) / float(LEVELS - 1)
		if t < BASE_STOP:
			var k := 1.0 - t / BASE_STOP
			out.append(base.lerp(SHADOW_TINT, k * SHADOW_STRENGTH))
		else:
			var k := (t - BASE_STOP) / (1.0 - BASE_STOP)
			out.append(base.lerp(LIGHT_TINT, k * LIGHT_STRENGTH))
	return out


## Le contour est plus sombre que le plus sombre de la rampe, sinon il se noie
## dans les faces à l'ombre et la silhouette disparaît sur un sol foncé.
static func outline_of(r: PackedColorArray) -> Color:
	var c: Color = r[0]
	return Color(c.r * 0.45, c.g * 0.45, c.b * 0.5, 1.0)


## Décale une teinte pour donner à chaque instance sa nuance propre.
## Volontairement discret : au delà, un groupe de grunts vire à l'arc-en-ciel
## et on ne lit plus l'archétype d'un coup d'œil.
static func jitter(base: Color, rng: RandomNumberGenerator, amount := 1.0) -> Color:
	var c := base
	c.h = wrapf(c.h + rng.randf_range(-0.035, 0.035) * amount, 0.0, 1.0)
	c.s = clampf(c.s + rng.randf_range(-0.10, 0.10) * amount, 0.0, 1.0)
	c.v = clampf(c.v + rng.randf_range(-0.08, 0.08) * amount, 0.05, 1.0)
	return c
