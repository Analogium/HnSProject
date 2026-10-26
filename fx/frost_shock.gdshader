shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// L'onde de choc de la Nova (`IceNovaFx`) : un anneau couché, le vent de givre de Qwen-Image
// (`fx/frost_wind.png`) qui fait le tour en défilant, puis rongé par un bruit, un liseré de givre sur le
// bord qui s'en va. Monté au givre sur toute sa largeur, il sortait blanc : le froid s'ombre.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D wind : filter_linear_mipmap, repeat_enable;
uniform vec3 tint;
uniform vec3 deep;
uniform vec3 rime;
instance uniform float opacity = 1.0;
// En part du demi-côté du plan : le bord extérieur de l'anneau, et sa largeur vers le dedans.
instance uniform float front = 0.0;
instance uniform float width = 0.25;
instance uniform float dissolve = 0.0;
instance uniform float clock = 0.0;

float fbm(vec2 p) {
	return noise(p) * 0.55 + noise(p * 2.1) * 0.3 + noise(p * 4.3) * 0.15;
}

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float r = length(d);
	float v = (r - (front - width)) / width;
	if (v < 0.0 || v > 1.0) {
		discard;
	}
	float a = atan(d.y, d.x) / 6.2831853 + 0.5;
	vec3 w3 = texture(wind, vec2(a * 3.0 - clock * 0.6, 0.15 + v * 0.7)).rgb;
	float w = max(w3.r, max(w3.g, w3.b));
	float m = w * 0.55 + fbm(vec2(a * 48.0, v * 3.0 + clock * 2.0)) * 0.45;
	if (m < dissolve) {
		discard;
	}
	float glow = (1.0 - smoothstep(dissolve, dissolve + 0.07, m)) * step(0.01, dissolve);
	float profile = smoothstep(0.0, 0.75, v) * (1.0 - smoothstep(0.88, 1.0, v));
	ALBEDO = mix(mix(deep, tint, w), rime, max(glow, w * w * 0.25));
	ALPHA = clamp(w * profile + glow * 0.8, 0.0, 0.95) * opacity;
}
