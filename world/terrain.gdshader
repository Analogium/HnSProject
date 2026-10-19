shader_type spatial;

// Le relief d'une zone (`Terrain`) : sur le plat, la terre du biome, ses plaques brûlées et la
// route de son masque ; sur la pente, la roche ; en haut, le dessus des falaises. Chaque
// matière a sa couleur et son `_nr` : relief en RGB (OpenGL), rugosité en alpha
// (`tools/terrain_textures.py`). Le maillage n'a pas d'UV : tout se projette sur le monde, le
// relief compris (mélange « whiteout »). Ce qui passe devant le joueur s'estompe.
#include "res://world/fade.gdshaderinc"

uniform sampler2D ground_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D road_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D top_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_nr : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_nr : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D road_nr : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_nr : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D top_nr : filter_linear_mipmap_anisotropic, repeat_enable;
// La route : un texel pour TilesetBuilder.MASK_CELL px, lissé ; son bord est déjà rongé.
uniform sampler2D mask : filter_linear;
uniform vec2 map_px;
uniform float threshold = 0.5;
uniform float cliff = 40.0;

// Une tuile pour 48 px du monde (3 m) : un scan couvre deux mètres, un peu grossi comme le décor.
const float GROUND_SCALE = 1.0 / 48.0;
const float ROCK_SCALE = 1.0 / 64.0;

varying vec3 world;
varying vec3 world_normal;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + 1.0), f.x), f.y);
}

float fbm(vec2 p) {
	return value_noise(p) * 0.6 + value_noise(p * 2.1) * 0.3 + value_noise(p * 4.3) * 0.1;
}

// Deux échelles de la même texture, mêlées par un bruit lent : la répétition ne se lit plus.
vec4 unrepeated(sampler2D tex, vec2 p, float scale) {
	float blend = smoothstep(0.35, 0.65, fbm(p * 0.004));
	return mix(texture(tex, p * scale), texture(tex, p * scale * 0.43 + 0.37), blend);
}

// Un relief de texture projeté sur le plan, posé sur la normale `n` du monde.
vec3 flat_relief(vec4 nr, vec3 n) {
	vec3 t = nr.rgb * 2.0 - 1.0;
	return normalize(vec3(t.x + n.x, abs(t.z) * n.y, -t.y + n.z));
}

void fragment() {
	vec2 p = world.xz;
	// Une couche ne se lit que là où elle compte : la plupart des pixels sont du sol nu.
	float grass = smoothstep(0.58, 0.68, fbm(p * 0.012));
	float road = smoothstep(threshold - 0.08, threshold + 0.08, texture(mask, p / map_px).r);
	float high = smoothstep(cliff * 0.15, cliff * 0.4, world.y);
	float steep = smoothstep(0.8, 0.55, world_normal.y);
	vec3 color = unrepeated(ground_tex, p, GROUND_SCALE).rgb;
	vec4 nr = unrepeated(ground_nr, p, GROUND_SCALE);
	if (grass > 0.0) {
		color = mix(color, unrepeated(grass_tex, p, GROUND_SCALE).rgb, grass);
		nr = mix(nr, unrepeated(grass_nr, p, GROUND_SCALE), grass);
	}
	if (road > 0.0) {
		color = mix(color, unrepeated(road_tex, p, GROUND_SCALE).rgb, road);
		nr = mix(nr, unrepeated(road_nr, p, GROUND_SCALE), road);
	}
	if (high > 0.0) {
		color = mix(color, unrepeated(top_tex, p, GROUND_SCALE).rgb, high);
		nr = mix(nr, unrepeated(top_nr, p, GROUND_SCALE), high);
	}
	vec3 normal = flat_relief(nr, world_normal);
	float roughness = nr.a;

	// La roche, sur les trois axes.
	if (steep > 0.0) {
		vec3 w = pow(abs(world_normal), vec3(4.0));
		w /= w.x + w.y + w.z;
		vec4 nx = texture(rock_nr, world.zy * ROCK_SCALE);
		vec4 ny = texture(rock_nr, world.xz * ROCK_SCALE);
		vec4 nz = texture(rock_nr, world.xy * ROCK_SCALE);
		vec3 tx = nx.rgb * 2.0 - 1.0;
		vec3 ty = ny.rgb * 2.0 - 1.0;
		vec3 tz = nz.rgb * 2.0 - 1.0;
		vec3 rock_normal = normalize(
			vec3(abs(tx.z) * world_normal.x, tx.y + world_normal.y, tx.x + world_normal.z) * w.x
			+ vec3(ty.x + world_normal.x, abs(ty.z) * world_normal.y, ty.y + world_normal.z) * w.y
			+ vec3(tz.x + world_normal.x, tz.y + world_normal.y, abs(tz.z) * world_normal.z) * w.z);
		vec3 rock_color = texture(rock_tex, world.zy * ROCK_SCALE).rgb * w.x
			+ texture(rock_tex, world.xz * ROCK_SCALE).rgb * w.y + texture(rock_tex, world.xy * ROCK_SCALE).rgb * w.z;
		color = mix(color, rock_color, steep);
		normal = mix(normal, rock_normal, steep);
		roughness = mix(roughness, nx.a * w.x + ny.a * w.y + nz.a * w.z, steep);
	}
	ALBEDO = color;
	ROUGHNESS = roughness;
	NORMAL = normalize((VIEW_MATRIX * vec4(normal, 0.0)).xyz);
	if (faded(SCREEN_UV, VIEWPORT_SIZE, -VERTEX.z, FRAGCOORD.xy, world.y)) {
		discard;
	}
}
