shader_type spatial;
render_mode cull_disabled;

// Le corbeau du Familier (`CrowFx`), un modèle de TRELLIS.2 sans squelette : ses ailes battent par
// le shader, chaque sommet au-delà de l'épaule tourné autour de l'axe du corps, d'autant plus qu'il
// est loin. Sa texture, celle du modèle.

uniform sampler2D albedo : source_color, filter_linear_mipmap;
// En unités du modèle : la demi-largeur du corps, d'où partent les ailes.
uniform float shoulder = 0.12;
instance uniform float flap = 0.0;

void vertex() {
	float side = sign(VERTEX.x);
	float beyond = abs(VERTEX.x) - shoulder;
	if (beyond > 0.0) {
		float a = flap * smoothstep(0.0, 0.25, beyond);
		vec2 p = vec2(beyond, VERTEX.y);
		vec2 q = vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
		VERTEX.x = side * (shoulder + q.x);
		VERTEX.y = q.y;
	}
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
	ROUGHNESS = 0.6;
	SPECULAR = 0.4;
}
