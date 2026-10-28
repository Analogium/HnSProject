// Un cercle runique de la sorcière (`WitchFx`, `GlyphFx`), un tirage de Qwen-Image tracé en lumière sur
// fond noir : couché au sol, ou tourné vers la caméra (`lying` faux, les charges d'Harmonie). La rampe de
// sa nature lue dans la clarté. `dissolve` le ronge au liseré de son cœur — à rebours, il se trace.
// Additionné (`witch_sigil.gdshader`) ; le froid se mêle (`witch_sigil_ice.gdshader`) : additionné à
// l'ocre, son cyan sortait blanc.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
uniform bool lying = true;
uniform vec3 heart;
uniform vec3 tint;
uniform vec3 deep;
instance uniform float opacity = 1.0;
instance uniform float glow = 1.0;
instance uniform float dissolve = 0.0;
instance uniform float clock = 0.0;

void vertex() {
	if (!lying) {
		MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
	}
}

void fragment() {
	float l = texture(atlas, UV).r;
	float n = noise(UV * 9.0 + vec2(clock * 0.3, 0.0)) * 0.6 + noise(UV * 23.0) * 0.4;
	if (n < dissolve) {
		discard;
	}
	float edge = (1.0 - smoothstep(dissolve, dissolve + 0.08, n)) * step(0.01, dissolve);
	vec2 d = UV * 2.0 - 1.0;
	float shimmer = 0.85 + 0.15 * noise(vec2(atan(d.y, d.x) * 6.0, clock * 3.0));
	vec3 c = l < 0.5 ? mix(deep, tint, l / 0.5) : mix(tint, heart, (l - 0.5) / 0.5);
	float lit = l * shimmer * glow + edge * 0.8;
#ifdef MIXED
	ALBEDO = mix(c, heart, edge);
	ALPHA = clamp(lit * 1.4, 0.0, 0.95) * opacity;
#else
	ALBEDO = mix(c, heart, edge) * lit * 0.6;
	ALPHA = opacity;
#endif
}
