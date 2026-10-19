shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// La zone de danger d'une attaque ennemie (jalon 27), choisie sur planche au jalon 54 : un
// contour net, et le plein qui monte du départ, léger, plus dense vers son front. Le nœud
// est tourné vers son cap, x local le long de `facing`. `DangerZone.contains()` en est le miroir.

uniform int shape = 0;           // DangerZone.Shape : disque, couloir, cône
uniform float reach = 30.0;      // rayon, longueur ou portée
uniform float spread = 0.0;      // demi-largeur du couloir, demi-angle du cône
uniform float progress = 0.0;    // le plein, du départ (0) au bord (1)
uniform float gone = 0.0;        // l'effacement, après la frappe
instance uniform float opacity = 1.0;  // le réglage des attaques ennemies (`Settings.veil`)

const vec3 DARK = vec3(0.6, 0.05, 0.04);
const vec3 HOT = vec3(1.0, 0.22, 0.12);

varying vec2 local;

void vertex() {
	local = VERTEX.xz;
}

// La profondeur, du départ (0) au bord (1), négative hors de la forme ; puis la distance au
// bord, en pixels du monde.
vec2 measure(vec2 p) {
	if (shape == 0) {
		float d = length(p);
		return d <= reach ? vec2(d / reach, reach - d) : vec2(-1.0);
	}
	if (shape == 1) {
		bool inside = p.x >= 0.0 && p.x <= reach && abs(p.y) <= spread;
		return inside ? vec2(p.x / reach, min(min(p.x, reach - p.x), spread - abs(p.y))) : vec2(-1.0);
	}
	float d = length(p);
	float a = abs(atan(p.y, p.x));
	bool inside = p.x > 0.0 && d <= reach && a <= spread;
	return inside ? vec2(d / reach, min(reach - d, d * sin(min(spread - a, PI * 0.5)))) : vec2(-1.0);
}

void fragment() {
	vec2 m = measure(local);
	if (m.x < 0.0) {
		discard;
	}
	float rim = 1.0 - smoothstep(1.0, 2.5, m.y);
	float front = 1.0 - smoothstep(0.0, 2.5, abs(m.x - progress) * reach);
	float filled = 1.0 - smoothstep(progress - 0.005, progress, m.x);
	float body = filled * mix(0.12, 0.45, m.x / max(progress, 0.001));
	ALBEDO = mix(DARK, HOT, max(rim, front));
	ALPHA = max(max(rim, front * 0.9), body) * (1.0 - gone) * opacity;
}
