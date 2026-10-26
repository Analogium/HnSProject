shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// L'onde de feu couchée (`FireBlastFx`, le liseré de `FireRing`) : l'onde de choc de la Nova en lumière —
// une bande de flammes de Qwen-Image (`fx/fire_wind.png`) qui fait le tour en défilant, rongée par un bruit
// au liseré brûlant. La photo passe par la rampe de la nature : en ses couleurs, son cœur sortait blanc.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D wind : filter_linear_mipmap, repeat_enable;
uniform vec3 heart = vec3(1.0, 0.72, 0.22);
uniform vec3 tint = vec3(1.0, 0.36, 0.04);
uniform vec3 deep = vec3(0.72, 0.1, 0.02);
instance uniform float opacity = 1.0;
// En part du demi-côté du plan : le bord extérieur de l'anneau, et sa largeur vers le dedans.
instance uniform float front = 0.0;
instance uniform float width = 0.25;
instance uniform float dissolve = 0.0;
instance uniform float clock = 0.0;
// L'explosion plus bas que le liseré de l'Immolation : sur ses photos, la somme montait au blanc.
instance uniform float boost = 0.75;

float fbm(vec2 p) {
	return noise(p) * 0.55 + noise(p * 2.1) * 0.3 + noise(p * 4.3) * 0.15;
}

vec3 ramp_of(float l) {
	if (l < 0.35) {
		return deep * (l / 0.35);
	}
	if (l < 0.7) {
		return mix(deep, tint, (l - 0.35) / 0.35);
	}
	return mix(tint, heart, (l - 0.7) / 0.3);
}

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float r = length(d);
	float v = (r - (front - width)) / width;
	if (v < 0.0 || v > 1.0) {
		discard;
	}
	float a = atan(d.y, d.x) / 6.2831853 + 0.5;
	vec3 c = texture(wind, vec2(a * 3.0 - clock * 0.5, 0.1 + v * 0.8)).rgb;
	float l = max(c.r, max(c.g, c.b));
	float m = l * 0.5 + fbm(vec2(a * 40.0, v * 3.0 - clock * 3.0)) * 0.5;
	if (m < dissolve) {
		discard;
	}
	// Le liseré qui brûle là où le bruit vient de ronger : la flamme se consume, elle ne pâlit pas.
	float edge = (1.0 - smoothstep(dissolve, dissolve + 0.08, m)) * step(0.01, dissolve);
	float profile = smoothstep(0.0, 0.6, v) * (1.0 - smoothstep(0.85, 1.0, v));
	ALBEDO = (ramp_of(l) * profile + heart * edge * 0.8) * boost * opacity;
}
