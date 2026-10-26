shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// La distorsion sur le front de la Nova (`IceNovaFx`) : le sol vu au travers, repoussé vers le dehors
// sur une bande autour de `front` ; une `strength` négative l'aspire vers le dedans (l'Aspiration du
// Désastre, `IceVortexFx`), sur une bande plus large (`spread`).

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
instance uniform float opacity = 1.0;
instance uniform float front = 0.0;
instance uniform float strength = 0.0;
instance uniform float spread = 0.07;

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float r = length(d);
	float band = exp(-pow((r - front) / spread, 2.0));
	vec2 dir = d / max(r, 1e-3);
	ALBEDO = textureLod(screen, SCREEN_UV - vec2(dir.x, -dir.y) * band * strength, 0.0).rgb;
	ALPHA = smoothstep(0.02, 0.3, band) * opacity;
}
