shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Ce qui bout dans le Chaudron (`CauldronFx`) : la surface d'un breuvage de Qwen-Image, deux fois, qui
// tournent en sens contraires, à la rampe de ce qui bout lue dans la clarté ; `boil` l'éclaire à chaque
// bouillon. Sous le Mélange ou l'Émulsion, deux ou trois rampes (`count`) en volutes qui tournent ensemble.
// Un disque : le plan est coupé à son cercle.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D brew : filter_linear_mipmap, repeat_enable;
uniform int count = 1;
uniform vec3 heart0;
uniform vec3 tint0;
uniform vec3 deep0;
uniform vec3 heart1;
uniform vec3 tint1;
uniform vec3 deep1;
uniform vec3 heart2;
uniform vec3 tint2;
uniform vec3 deep2;
instance uniform float opacity = 1.0;
instance uniform float clock = 0.0;
instance uniform float boil = 0.0;

vec2 turned(vec2 p, float a) {
	return mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * p;
}

vec3 ramp(vec3 heart, vec3 tint, vec3 deep, float l) {
	return l < 0.5 ? mix(deep * 0.6, tint, l / 0.5) : mix(tint, heart, (l - 0.5) / 0.5);
}

vec3 ramp_of(int k, float l) {
	if (k == 1) {
		return ramp(heart1, tint1, deep1, l);
	}
	if (k == 2) {
		return ramp(heart2, tint2, deep2, l);
	}
	return ramp(heart0, tint0, deep0, l);
}

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float r = length(d);
	if (r > 1.0) {
		discard;
	}
	float a = texture(brew, turned(d, clock * 0.5) * 0.45 + 0.5).r;
	float b = texture(brew, turned(d, -clock * 0.35) * 0.6 + vec2(0.3, 0.7)).r;
	float l = clamp(max(a, b) * 0.8 + boil * 0.25 * noise(d * 6.0 + clock * 3.0), 0.0, 1.0);
	// Le bord s'assombrit sous le rebord.
	l *= 1.0 - smoothstep(0.7, 1.0, r) * 0.7;
	// Les volutes : chaque élément a sa part du tour, enroulée et qui tourne, fondue à ses bords.
	float k = fract(atan(d.y, d.x) / 6.2831853 + r * 0.6 - clock * 0.12 + noise(d * 2.5 + clock * 0.4) * 0.25)
			* float(count);
	int i = int(floor(k));
	float w = smoothstep(0.75, 1.0, fract(k));
	ALBEDO = mix(ramp_of(i, l), ramp_of((i + 1) % count, l), w);
	ALPHA = opacity;
}
