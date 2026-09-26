shader_type canvas_item;

// La zone de danger d'une attaque ennemie (jalon 27), au pixel du monde : le nœud ne
// tourne pas, c'est la forme qui se calcule dans le sens de `facing` — la grille reste
// droite. `DangerZone.contains()` en est le miroir côté jeu.

uniform int shape = 0;           // DangerZone.Shape : disque, couloir, cône
uniform float reach = 30.0;      // rayon, longueur ou portée
uniform float spread = 0.0;      // demi-largeur du couloir, demi-angle du cône
uniform vec2 facing = vec2(1.0, 0.0);
uniform float progress = 0.0;    // le plein, du départ (0) au bord (1)
uniform float gone = 0.0;        // la dissolution, après la frappe
uniform vec4 dark : source_color;
uniform vec4 mid : source_color;

varying vec2 local;

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
                                3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void vertex() {
	local = VERTEX;
}

// La distance au départ, de 0 à 1 ; négative hors de la forme.
float depth(vec2 p) {
	if (shape == 0) {
		float d = length(p) / reach;
		return d <= 1.0 ? d : -1.0;
	}
	vec2 q = vec2(dot(p, facing), dot(p, vec2(-facing.y, facing.x)));
	if (shape == 1) {
		return (q.x >= 0.0 && q.x <= reach && abs(q.y) <= spread) ? q.x / reach : -1.0;
	}
	float d = length(q);
	return (q.x > 0.0 && d <= reach && abs(atan(q.y, q.x)) <= spread) ? d / reach : -1.0;
}

void fragment() {
	vec2 px = floor(local) + 0.5;
	float s = depth(px);
	ivec2 cell = ivec2(mod(floor(local), 4.0));
	float b = (BAYER[cell.y * 4 + cell.x] + 0.5) / 16.0;
	if (s < 0.0 || b < gone) {
		discard;
	}
	bool edge = depth(px + vec2(1.0, 0.0)) < 0.0 || depth(px - vec2(1.0, 0.0)) < 0.0
		|| depth(px + vec2(0.0, 1.0)) < 0.0 || depth(px - vec2(0.0, 1.0)) < 0.0;
	// Le front fait deux pixels quelle que soit la taille de la zone.
	float band = 2.0 / reach;
	vec4 c = vec4(0.0);
	if (edge || (s <= progress && s > progress - band)) {
		c = mid;
	} else if (s <= progress) {
		c = b < 0.5 ? dark : vec4(0.0);
	} else if (b < 0.12) {
		c = dark;
	}
	if (c.a <= 0.0) {
		discard;
	}
	COLOR = c;
}
