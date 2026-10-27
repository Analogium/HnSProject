shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La trace d'une lame (`SteelFx`) : la traînée de taille photographiée par Qwen-Image (`fx/steel_slash.png`,
// épaisse à gauche, en pointe à droite) posée sur un ruban — un croissant, une entaille droite — que la lame
// parcourt. UV.x court le long du ruban, la tête en `head`, la traînée derrière elle jusqu'au départ ; elle se
// ronge au liseré au lieu de pâlir. La photo passe par la rampe de la nature, le cœur blanc en haut.

#include "res://fx/flame_common.gdshaderinc"
#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_disable;
instance uniform float opacity = 1.0;
instance uniform float head = 1.0;
instance uniform float dissolve = 0.0;
instance uniform float clock = 0.0;
instance uniform float boost = 0.8;

float fbm(vec2 p) {
	return noise(p) * 0.55 + noise(p * 2.1) * 0.3 + noise(p * 4.3) * 0.15;
}

void fragment() {
	float x = head - UV.x;
	if (x < 0.0 || x > 1.0) {
		discard;
	}
	// La pointe de la photo à la tête.
	vec3 p = texture(photo, vec2(1.0 - x, UV.y)).rgb;
	float l = max(p.r, max(p.g, p.b));
	// Le bruit défile vers la queue : la traînée s'effiloche derrière la lame.
	float m = l * 0.45 + fbm(vec2(UV.x * 22.0 + clock * 6.0, UV.y * 4.0)) * 0.55;
	float eaten = dissolve + x * x * 0.25;
	if (m < eaten) {
		discard;
	}
	float edge = (1.0 - smoothstep(eaten, eaten + 0.07, m)) * step(0.01, eaten);
	// La lame mord à la tête : un éclat bref là où elle passe.
	float bite = exp(-x * 14.0);
	ALBEDO = (ramp_of(l) * l * (1.0 + bite) + tint * edge * 0.5) * boost * opacity;
}
