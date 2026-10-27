shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Les rayons de gloire du souffle sacré (`HolyBlastFx`), le parti pris de la 2D : huit traits couchés, longs
// et courts en alternance, écartés des axes — sur un axe, un trait se lit comme une mire. Chacun porte la
// bande de lumière de Qwen-Image (`fx/holy_wave.png`) qui file vers le bord. Le plan fait 2 de côté.

#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_enable;
uniform float tilt = 0.39;
instance uniform float opacity = 1.0;
// En part du rayon : la pointe des longs traits, et leur pied qui la rattrape.
instance uniform float reach = 0.0;
instance uniform float foot = 0.0;
// La demi-largeur d'un trait, en part du rayon.
instance uniform float width = 0.05;
instance uniform float clock = 0.0;

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float r = length(d);
	float a = atan(d.y, d.x) - tilt;
	float step_ = 6.2831853 / 8.0;
	float k = round(a / step_);
	float off = (a - k * step_) * r;
	float tip = reach * (mod(k, 2.0) == 0.0 ? 1.0 : 0.7);
	float w = width * (1.0 - 0.75 * r / max(tip, 1e-3));
	if (r > tip || r < foot || abs(off) > w) {
		discard;
	}
	float across = 1.0 - abs(off) / w;
	vec3 p = texture(photo, vec2(r * 1.5 - clock * 2.0 + k * 0.37, 0.5 + off / w * 0.3)).rgb;
	float l = max(p.r, max(p.g, p.b));
	float along = smoothstep(foot, foot + 0.15, r) * (1.0 - smoothstep(tip - 0.2, tip, r) * 0.6);
	float light = clamp((0.6 + 0.6 * l) * pow(across, 1.2) * along, 0.0, 1.0);
	ALBEDO = ramp_of(light) * (0.4 + light) * 1.3 * opacity;
}
