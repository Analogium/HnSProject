shader_type spatial;
// Par-dessus le corps d'un acteur (`ActorModel`, `material_overlay`) : la teinte de son état,
// le liseré de ses affixes, le flash d'un coup encaissé — dans cet ordre, l'un sur l'autre.
// Des uniformes d'instance : un seul matériau pour tous les corps, sans copie par acteur.
render_mode unshaded, blend_mix, depth_draw_never, shadows_disabled;

instance uniform vec3 tint_color = vec3(1.0);
instance uniform float tint_strength = 0.0;
instance uniform vec3 rim_color = vec3(1.0);
instance uniform float rim_amount = 0.0;
// Plus large, le liseré mord plus loin sur la face : l'exposant de Fresnel s'adoucit.
instance uniform float rim_width = 1.0;
instance uniform float flash_amount = 0.0;

vec4 over(vec3 color, float alpha, vec4 under) {
	float a = alpha + under.a * (1.0 - alpha);
	if (a <= 0.0) {
		return vec4(0.0);
	}
	return vec4((color * alpha + under.rgb * under.a * (1.0 - alpha)) / a, a);
}

void fragment() {
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0 / max(rim_width, 0.01));
	vec4 layer = vec4(tint_color, tint_strength);
	layer = over(rim_color, rim_amount * edge, layer);
	layer = over(vec3(1.0), flash_amount, layer);
	ALBEDO = layer.rgb;
	ALPHA = layer.a;
}
