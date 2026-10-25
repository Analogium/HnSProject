shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Le sol fendu de `IceSpikesFx` : les fissures de la Ruée (G de `fx/burnt_cracks.png`), en givre, sur
// un voile froid, au rayon qui frappe. Un voile du bleu profond virait au mauve sur l'ocre : cyan.

uniform sampler2D cracks : filter_linear_mipmap, repeat_enable;
uniform vec3 tint;
uniform vec3 rime;
instance uniform float opacity = 1.0;
// De 0 à 1 : la fente s'ouvre du centre au bord.
instance uniform float spread = 1.0;
instance uniform float fade = 1.0;

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float g = texture(cracks, UV * 1.4).g;
	float edge = 1.0 - smoothstep(spread * 0.6, spread, r);
	float veil = (1.0 - smoothstep(0.0, spread, r)) * 0.22;
	ALBEDO = mix(tint, rime, clamp(g * 1.5, 0.0, 1.0));
	ALPHA = clamp(g * 1.4 + veil, 0.0, 0.9) * edge * fade * opacity;
}
