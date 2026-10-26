shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Le tourbillon du Désastre hivernal (`IceVortexFx`) : une spirale de lames de glace vue de dessus, peinte
// par Qwen-Image (`fx/frost_vortex.png`), qui tourne — le cœur plus vite que le bord ; son bord rongé par
// un bruit, un liseré de givre. Mêlé au sol, pas additionné, et à peine monté au givre : plus clair, il
// couvrait le sol d'un disque blanc.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D swirl : filter_linear_mipmap, repeat_disable;
uniform vec3 tint;
uniform vec3 deep;
uniform vec3 rime;
instance uniform float opacity = 1.0;
// En part du demi-côté du plan : jusqu'où il couvre.
instance uniform float reach = 1.0;
instance uniform float clock = 0.0;
instance uniform float dissolve = 0.0;

float fbm(vec2 p) {
	return noise(p) * 0.55 + noise(p * 2.1) * 0.3 + noise(p * 4.3) * 0.15;
}

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float r = length(d) / reach;
	if (r > 1.0) {
		discard;
	}
	float a = atan(d.y, d.x);
	float turn = clock * 2.2 + (1.0 - r) * 0.9;
	vec2 q = mat2(vec2(cos(turn), sin(turn)), vec2(-sin(turn), cos(turn))) * (d / reach) * 0.5 + 0.5;
	vec3 p = texture(swirl, q).rgb;
	float l = max(p.r, max(p.g, p.b));
	float m = l * 0.6 + fbm(vec2(a * 6.0, r * 5.0 - clock * 1.5)) * 0.4;
	float cut = max(dissolve, smoothstep(0.78, 1.0, r) * 0.75);
	if (m < cut) {
		discard;
	}
	float glow = (1.0 - smoothstep(cut, cut + 0.07, m)) * step(0.01, cut);
	ALBEDO = mix(mix(deep, tint, l), rime, max(glow * 0.8, l * l * 0.12));
	ALPHA = clamp(l * 0.8 + glow * 0.5, 0.0, 0.75) * opacity;
}
