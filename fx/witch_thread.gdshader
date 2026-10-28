shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Un fil de l'Entrelacs ou un bord du triangle des Glyphes (`GlyphFx`) : la bande d'un fil de lumière de
// Qwen-Image, couchée d'un glyphe à l'autre, qui défile et se ronge ; la rampe d'un bout passe à celle de
// l'autre le long du fil. Le triangle (`fill`) : un voile qui scintille, à la couleur des coins — en grille,
// il sortait en maillage de synthèse.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D band : filter_linear_mipmap, repeat_enable;
uniform bool fill = false;
instance uniform float opacity = 1.0;
instance uniform float life = 0.0;
instance uniform float clock = 0.0;
// La rampe de chaque bout : cœur et milieu.
instance uniform vec3 from_heart = vec3(1.0);
instance uniform vec3 from_tint = vec3(1.0);
instance uniform vec3 to_heart = vec3(1.0);
instance uniform vec3 to_tint = vec3(1.0);
// Le long du fil, en pixels : la photo s'y répète au lieu de s'étirer.
instance uniform float span = 64.0;

void fragment() {
	float n = noise(UV * vec2(span * 0.15, 3.0) + vec2(clock, 0.0)) * 0.6 + noise(UV * 31.0) * 0.4;
	if (n < life) {
		discard;
	}
	float edge = 1.0 - smoothstep(life, life + 0.1, n);
	float l;
	vec3 heart;
	vec3 tint;
	if (fill) {
		// Les coins portent leur couleur en sommet.
		float glint = noise(UV * span * 0.6 + vec2(clock * 2.0, 0.0));
		l = 0.1 + smoothstep(0.82, 0.95, glint) * 0.7;
		heart = COLOR.rgb;
		tint = COLOR.rgb * 0.6;
	} else {
		l = texture(band, vec2(UV.x * span / 40.0 - clock * 0.8, UV.y)).r;
		l *= smoothstep(0.0, 0.08, UV.x) * smoothstep(1.0, 0.92, UV.x);
		heart = mix(from_heart, to_heart, UV.x);
		tint = mix(from_tint, to_tint, UV.x);
	}
	ALBEDO = (mix(tint, heart, l) * l + heart * edge * 0.6) * 0.6;
	ALPHA = opacity;
}
