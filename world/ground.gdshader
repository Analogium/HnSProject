shader_type spatial;

// Le sol du biome, au pixel du monde : la terre, et par-dessus la route claire que
// dessine le masque de la zone. Hors de la carte, la couleur des murs.

uniform sampler2D base_tex : source_color, filter_nearest, repeat_enable;
uniform sampler2D patch_tex : source_color, filter_nearest, repeat_enable;
// Un texel pour TilesetBuilder.MASK_CELL px, lissé : c'est la découpe en blocs
// ci-dessous qui donne le bord en escalier, pas la taille du texel.
uniform sampler2D mask : filter_linear;
uniform vec2 map_px;
uniform float threshold = 0.5;
uniform vec3 beyond : source_color;

const float BLOCK = 4.0;
const float SOFT = 0.06;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float bayer(vec2 p) {
	int i = int(mod(p.x, 4.0)) + 4 * int(mod(p.y, 4.0));
	const float M[16] = float[](0., 8., 2., 10., 12., 4., 14., 6., 3., 11., 1., 9., 15., 7., 13., 5.);
	return M[i] / 16.0;
}

void fragment() {
	vec2 p = floor(world);
	if (p.x < 0.0 || p.y < 0.0 || p.x >= map_px.x || p.y >= map_px.y) {
		ALBEDO = beyond;
	} else {
		vec2 cell = (floor(p / BLOCK) + 0.5) * BLOCK;
		float edge = clamp((texture(mask, cell / map_px).r - threshold) / SOFT, 0.0, 1.0);
		// La trame au bord de la route, comme la planche : un escalier franc.
		bool inside = edge + (bayer(p) - 0.5) * 0.6 > 0.5;
		vec2 uv = (p + 0.5) / vec2(textureSize(base_tex, 0));
		ALBEDO = inside ? texture(patch_tex, uv).rgb : texture(base_tex, uv).rgb;
	}
}
