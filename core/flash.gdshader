shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Seuil sur l'opacité : le sprite porte son ombre au sol, un noir à 30 %,
	// et sans ce filtre le flash la repeignait en blanc — un halo sous les
	// pieds à chaque coup encaisse. Les sprites de la forge n'ont pas de bord
	// adouci, donc un simple seuil sépare le corps de son ombre.
	float amount = flash_amount * step(0.5, tex.a);
	COLOR = vec4(mix(tex.rgb, vec3(1.0), amount), tex.a);
}
