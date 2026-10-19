shader_type spatial;
render_mode world_vertex_coords, cull_back;

// Le corps du Serpent infernal (`SerpentBody`, « braise » choisie sur planche, l'avant dressé) :
// écailles calcinées et bombées dont les joints rougeoient au passage d'une onde de chaleur,
// reflets, liseré chaud, ventre qui couve, yeux qui brûlent. Le maillage est une grille droite (UV.x le long, du museau à la queue ;
// UV.y le tour, 0,25 le dos) que le vertex courbe le long de `spine`.

#include "res://fx/flame_common.gdshaderinc"

// Le museau et les vingt anneaux de `HellSnake` (RINGS + 1) : `SerpentBody.SPINE`.
uniform vec3 spine[21];
uniform float girth = 2.1;
uniform float wave = 3.0;
// Combien d'écailles du museau à la queue.
uniform float scales = 26.0;
uniform vec3 heart = vec3(1.0, 0.72, 0.22);
uniform vec3 tint = vec3(1.0, 0.36, 0.04);
uniform vec3 deep = vec3(0.72, 0.1, 0.02);
uniform vec3 rim = vec3(0.22, 0.03, 0.01);
// Le voile des sorts et la fin du serpent : il se dissout en pointillé, sans transparence.
instance uniform float opacity = 1.0;
instance uniform float fade = 0.0;
// L'avant du corps dressé, tête relevée : en pixels du monde, à la tête.
uniform float rear = 9.0;

varying float along;

// Le rayon, du museau (0) à la queue (1), en part de `girth` : mâchoire, cou pincé, corps
// le plus épais au tiers, puis la queue qui s'effile.
float profile(float u) {
	if (u < 0.08) {
		return mix(0.5, 1.25, smoothstep(0.0, 0.08, u));
	}
	if (u < 0.14) {
		return mix(1.25, 0.7, smoothstep(0.08, 0.14, u));
	}
	if (u < 0.35) {
		return mix(0.7, 1.0, smoothstep(0.14, 0.35, u));
	}
	return mix(1.0, 0.06, pow(smoothstep(0.35, 1.0, u), 0.8));
}

vec3 catmull(vec3 p0, vec3 p1, vec3 p2, vec3 p3, float t) {
	return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t);
}

void vertex() {
	along = UV.x;
	float x = along * 20.0;
	int i = clamp(int(floor(x)), 0, 19);
	float t = x - float(i);
	vec3 p0 = spine[max(i - 1, 0)];
	vec3 p1 = spine[i];
	vec3 p2 = spine[i + 1];
	vec3 p3 = spine[min(i + 2, 20)];
	vec3 center = catmull(p0, p1, p2, p3, t);
	vec3 d = p1 - p2;
	vec3 tangent = normalize(vec3(d.x, 0.0, d.z) + vec3(1e-5, 0.0, 0.0));
	vec3 side = vec3(-tangent.z, 0.0, tangent.x);
	// L'ondulation, en dessin seulement : la morsure garde les anneaux du jeu.
	center += side * sin(along * 15.0 - TIME * 9.0) * wave * along;
	center.y += rear * pow(1.0 - smoothstep(0.0, 0.32, along), 1.6);
	float f = profile(along) * girth;
	float w = f * 1.1;
	float h = f * (along < 0.12 ? 0.62 : 1.05);
	float a = UV.y * TAU;
	VERTEX = center + vec3(0.0, h, 0.0) + side * cos(a) * w + vec3(0.0, sin(a) * h, 0.0);
	NORMAL = normalize(side * cos(a) / max(w, 0.01) + vec3(0.0, sin(a) / max(h, 0.01), 0.0));
	TANGENT = -tangent;
	BINORMAL = normalize(-side * sin(a) * w + vec3(0.0, cos(a) * h, 0.0));
}

void fragment() {
	if (hash(floor(FRAGCOORD.xy)) > opacity * (1.0 - fade)) {
		discard;
	}
	vec2 g = vec2(along * scales, UV.y * 16.0);
	vec2 q = vec2(g.x + g.y, g.x - g.y) * 0.5;
	float edge = max(abs(fract(q.x) - 0.5), abs(fract(q.y) - 0.5));
	float seam = smoothstep(0.42, 0.5, edge);
	float own = hash(floor(q));
	float flow = noise(vec2(along * scales * 0.9 - TIME * 2.2, UV.y * 5.0));
	float pulse = smoothstep(0.62, 0.9, flow);
	float belly = smoothstep(0.55, 0.7, UV.y) * (1.0 - smoothstep(0.85, 0.95, UV.y));
	// Deux yeux, sur le haut de la tête, de part et d'autre du dos.
	float eye = 1.0 - smoothstep(0.35, 0.6, length(vec2((along - 0.06) * scales * 2.2, (abs(UV.y - 0.25) - 0.09) * 14.0)));
	// Chaque écaille bombe : sa pente vers le bord, le long du corps et autour.
	vec2 c = vec2(fract(q.x) - 0.5, fract(q.y) - 0.5);
	NORMAL_MAP = vec3(0.5 + vec2(c.x + c.y, c.x - c.y) * 0.9, 1.0);
	ALBEDO = mix(vec3(0.16, 0.06, 0.04), rim, own * 0.6) + belly * deep * 0.1;
	ROUGHNESS = 0.22;
	SPECULAR = 0.85;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = (mix(deep, tint, pulse) * (0.5 + 0.9 * pulse) + heart * pow(pulse, 4.0) * 0.6) * seam
		+ deep * belly * 0.35 + heart * eye * 2.0 + tint * fres * 0.6;
}
