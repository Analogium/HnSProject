shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Une photo nécrotique (`RotBlastFx.photo_material()`) de Qwen-Image sur fond noir : volute de gaz, crâne,
// faille, œil, sceau. **Mêlée, pas additionnée** — la nécrose ronge, elle n'éclaire pas : l'alpha vient de la
// clarté. Tournée vers la caméra, ou couchée telle que posée (`lying`, le sceau) ; une case d'atlas par
// particule, rongée en vieillissant au liseré jaune maladif ; `lid` l'ouvre en amande.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
uniform float frames = 1.0;
uniform float spin = 0.0;
// Les couleurs de la photo (l'œil) ou la rampe de la nature, lue dans la clarté.
uniform float native = 0.0;
uniform bool lying = false;
uniform float density = 1.6;
uniform vec3 heart = vec3(0.82, 1.0, 0.3);
uniform vec3 tint = vec3(0.38, 0.82, 0.08);
uniform vec3 deep = vec3(0.1, 0.38, 0.04);
uniform vec3 sick = vec3(0.85, 0.8, 0.2);
instance uniform float opacity = 1.0;
// L'âge d'un quad seul ; une particule prend le sien.
instance uniform float life = -1.0;
// Au-dessus de 1, pas de paupière.
instance uniform float lid = 2.0;
varying float age;
varying float seed;

vec3 ramp_of(float l) {
	if (l < 0.35) {
		return deep * (0.3 + 0.7 * l / 0.35);
	}
	if (l < 0.7) {
		return mix(deep, tint, (l - 0.35) / 0.35);
	}
	return mix(tint, heart, (l - 0.7) / 0.3);
}

void vertex() {
	age = life >= 0.0 ? life : INSTANCE_CUSTOM.y;
	seed = fract(float(INSTANCE_ID) * 0.6180339);
	if (!lying) {
		MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
	}
}

void fragment() {
	float a = seed * 6.28 + TIME * spin * (seed > 0.5 ? 1.0 : -1.0);
	vec2 uv = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * (UV - 0.5) + 0.5;
	uv += (vec2(noise(uv * 4.0 + vec2(seed * 30.0, -TIME * 1.5)), noise(uv * 4.0 + vec2(TIME, seed * 17.0))) - 0.5) * 0.04;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		discard;
	}
	float open = lid * 0.5 * (1.0 - pow(abs(uv.x * 2.0 - 1.0), 2.2));
	if (lid <= 1.0 && abs(uv.y - 0.5) > open) {
		discard;
	}
	vec3 c = texture(atlas, vec2((floor(seed * frames * 0.999) + uv.x) / frames, uv.y)).rgb;
	float raw = max(c.r, max(c.g, c.b));
	float m = raw * 0.6 + noise(uv * 7.0 + seed * 13.0) * 0.4;
	if (m < age) {
		discard;
	}
	float glow = (1.0 - smoothstep(age, age + 0.08, m)) * step(0.01, age);
	ALBEDO = mix(mix(ramp_of(raw), c, native), sick, glow * 0.85);
	ALPHA = clamp(raw * density + glow * 0.6, 0.0, 0.92) * COLOR.a * opacity;
}
