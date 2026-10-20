shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Une photo de feu de `FlameFx` (« photo » choisie sur planche) : boule, volute ou explosion,
// tirée par Qwen-Image sur fond noir, que l'addition efface. Tournée vers la caméra, une case
// d'atlas par particule, tournoyante et ondulée ; le sombre se ronge d'abord en vieillissant.
// Le feu garde les couleurs de la photo ; une autre nature y lit sa rampe par la clarté.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
uniform float frames = 3.0;
uniform float spin = 1.0;
uniform float boost = 0.7;
uniform float native = 1.0;
uniform vec3 heart = vec3(1.0, 0.72, 0.22);
uniform vec3 tint = vec3(1.0, 0.36, 0.04);
uniform vec3 deep = vec3(0.72, 0.1, 0.02);
instance uniform float opacity = 1.0;
// L'âge d'un quad seul (le cœur de la boule) ; une particule prend le sien.
instance uniform float life = -1.0;
varying float age;
varying float seed;

vec3 ramp_of(float l) {
	if (l < 0.35) {
		return deep * (l / 0.35);
	}
	if (l < 0.7) {
		return mix(deep, tint, (l - 0.35) / 0.35);
	}
	return mix(tint, heart, (l - 0.7) / 0.3);
}

void vertex() {
	age = life >= 0.0 ? life : INSTANCE_CUSTOM.y;
	seed = fract(float(INSTANCE_ID) * 0.6180339);
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	float a = seed * 6.28 + TIME * spin * (seed > 0.5 ? 1.0 : -1.0);
	vec2 uv = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * (UV - 0.5) + 0.5;
	uv += (vec2(noise(uv * 4.0 + vec2(seed * 30.0, -TIME * 3.0)), noise(uv * 4.0 + vec2(TIME * 2.0, seed * 17.0))) - 0.5) * 0.06;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		discard;
	}
	vec3 c = texture(atlas, vec2((floor(seed * frames * 0.999) + uv.x) / frames, uv.y)).rgb;
	float raw = max(c.r, max(c.g, c.b));
	float l = clamp((raw - age * 0.55) / max(1.0 - age * 0.55, 0.05), 0.0, 1.0);
	// La rampe s'éteint déjà vers le noir : multipliée encore par la clarté, la volute d'une autre
	// nature ne gardait que son cœur, et la traînée du Givre sortait en perles.
	ALBEDO = mix(ramp_of(l), c * (l / max(raw, 0.001)), native) * boost * COLOR.a * opacity;
}
