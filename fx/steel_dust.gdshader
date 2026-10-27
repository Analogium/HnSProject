shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// L'onde de poussière d'un coup qui frappe le sol (`SteelFx`) : l'onde de choc de la Nova, en matière —
// une bande de poussière de Qwen-Image (`fx/steel_dust.png`) qui fait le tour en défilant, rongée par un
// bruit. La poussière n'est pas de la lumière : elle se mêle au sol, l'alpha tiré de sa clarté, à ses
// propres couleurs assombries par `shade`.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D dust : filter_linear_mipmap, repeat_enable;
uniform vec3 shade = vec3(0.5, 0.37, 0.25);
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
	vec3 c = texture(dust, vec2(a * 3.0 - clock * 0.3, 0.1 + v * 0.8)).rgb;
	float l = max(c.r, max(c.g, c.b));
	float m = l * 0.5 + fbm(vec2(a * 36.0, v * 3.0 - clock * 2.0)) * 0.5;
	if (m < dissolve) {
		discard;
	}
	float profile = smoothstep(0.0, 0.6, v) * (1.0 - smoothstep(0.6, 1.0, v));
	ALBEDO = c / max(l, 0.05) * mix(0.35, 1.0, l) * shade;
	ALPHA = clamp(l * 0.75, 0.0, 0.42) * profile * smoothstep(dissolve, dissolve + 0.1, m) * opacity;
}
