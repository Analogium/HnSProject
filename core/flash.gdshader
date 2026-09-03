shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 rim_color = vec3(1.0);
uniform float rim_amount : hint_range(0.0, 1.0) = 0.0;
/// Épaisseur du liseré, en pixels de sprite. 2 pour les élites, qui doivent se
/// repérer de plus loin.
uniform float rim_width : hint_range(1.0, 3.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Seuil sur l'opacité : le sprite porte son ombre au sol, un noir à 30 %.
	float solid = step(0.5, tex.a);
	vec3 c = tex.rgb;
	float a = tex.a;

	// Liseré d'affixe : un pixel vide au contact de la silhouette prend la
	// couleur. Il se pose donc *à l'extérieur* du contour noir que le
	// rastériseur a déjà dessiné, ce qui sépare la couleur du corps et laisse
	// l'archétype garder ses propres teintes — un grunt affixé reste vert.
	if (rim_amount > 0.0 && solid < 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE * rim_width;
		float near =
			step(0.5, texture(TEXTURE, UV + vec2(px.x, 0.0)).a) +
			step(0.5, texture(TEXTURE, UV - vec2(px.x, 0.0)).a) +
			step(0.5, texture(TEXTURE, UV + vec2(0.0, px.y)).a) +
			step(0.5, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
		if (near > 0.0) {
			c = rim_color;
			// max et non remplacement : là où le liseré recouvre l'ombre au
			// sol, il ne doit pas la rendre plus transparente qu'elle ne l'est.
			a = max(a, rim_amount);
		}
	}

	// Le flash par-dessus : un ennemi qui encaisse devient blanc, quel que soit
	// son affixe.
	c = mix(c, vec3(1.0), flash_amount * solid);

	COLOR = vec4(c, a);
}
