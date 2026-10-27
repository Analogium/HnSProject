shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La colonne du Pilier sacré (`SacredPillarFx`) : un cylindre ouvert, centré (de -0,5 à 0,5 de haut), où tourne
// une colonne de lumière de Qwen-Image (`fx/holy_shaft.png`, le ciel en haut). C'est un volume de lumière : plus clair là où
// l'œil la traverse de part en part, au milieu, et fondu sur ses bords et vers le ciel.

#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_enable;
uniform float boost = 0.9;
instance uniform float opacity = 1.0;
// La part de la colonne déjà tombée, du ciel vers le sol.
instance uniform float fall = 1.0;
// Éteinte, la colonne remonte au ciel : la part déjà levée, du pied ; sous l'Effondrement, elle s'écrase :
// la part déjà tombée, du ciel.
instance uniform float lift = 0.0;
instance uniform float crush = 0.0;
instance uniform float clock = 0.0;
// Le sursaut d'une impulsion, qui retombe.
instance uniform float pulse = 0.0;
varying float height;
varying float turn;

void vertex() {
	height = VERTEX.y + 0.5;
	turn = atan(VERTEX.z, VERTEX.x) / 6.2831853 + 0.5;
}

void fragment() {
	float low = max(1.0 - fall, lift);
	float high = 1.0 - crush;
	if (height < low || height > high) {
		discard;
	}
	// Un bout franc se lisait comme un tuyau : il se fond sur quelques pixels.
	float soft = (low > 0.001 ? smoothstep(low, low + 0.08, height) : 1.0)
			* (crush > 0.001 ? smoothstep(high, high - 0.08, height) : 1.0);
	float through = pow(abs(dot(NORMAL, VIEW)), 1.6);
	vec3 p = texture(photo, vec2(turn * 2.0 + clock * 0.06, 1.0 - height)).rgb;
	float l = max(p.r, max(p.g, p.b));
	// Le front qui tombe ou remonte brille, comme le pied qui touche le sol.
	float front = exp(-pow((height - low - 0.06) * 14.0, 2.0)) * step(0.001, low) * through * 0.6
			+ exp(-pow((height - high) * 14.0, 2.0)) * step(0.001, crush) * through;
	float foot = exp(-(height - lift) * 9.0) * through;
	float sky = 1.0 - smoothstep(0.45, 1.0, height + crush);
	float light = (l * l * 0.9 + 0.15) * through * sky * (1.0 + pulse * 0.8) + foot * 0.5 + front;
	ALBEDO = ramp_of(clamp(light, 0.0, 1.0)) * light * soft * boost * opacity;
}
