shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// La chaleur qui tremble au-dessus du feu : le sol vu au travers, décalé par un bruit qui monte. Sur un
// plan couché : un disque (`front` 0) ou une bande autour de `front`, de demi-largeur `spread`, en part
// du demi-côté. Dessinée avant le feu (`render_priority`) : le feu s'additionne dessus, et elle ne
// tremble que le sol — l'écran qu'elle relit n'a pas les effets.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
instance uniform float opacity = 1.0;
instance uniform float front = 0.0;
instance uniform float spread = 1.0;
// Le décalage, en part de l'écran ; 0 éteint.
instance uniform float strength = 0.0;
// Un couloir : `stretch` fois plus long que large (le plan l'est aussi), pour que le bruit reste rond.
instance uniform float stretch = 1.0;

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float r = length(d);
	float band = front > 0.0 ? exp(-pow((r - front) / spread, 2.0)) : 1.0 - smoothstep(spread * 0.5, spread, r);
	if (stretch > 1.0) {
		band = 1.0 - smoothstep(0.55, 1.0, max(abs(d.x), abs(d.y)));
	}
	vec2 p = UV * vec2(stretch, 1.0) * 9.0;
	vec2 wobble = vec2(noise(p + vec2(0.0, TIME * 2.3)), noise(p * 1.7 + vec2(TIME * 1.1, TIME * 3.1))) - 0.5;
	ALBEDO = textureLod(screen, SCREEN_UV + wobble * band * strength, 0.0).rgb;
	ALPHA = smoothstep(0.02, 0.25, band) * step(0.0001, strength) * opacity;
}
