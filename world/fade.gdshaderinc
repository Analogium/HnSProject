// Ce qui passe entre la caméra et le joueur s'estompe autour de lui, en pointillé : le relief
// (`terrain.gdshader`) et le décor (`decor.gdshader`). `fade_center` et `fade_depth` sont
// posés par `Player._show_through()` à chaque image.

global uniform vec2 fade_center;
global uniform float fade_depth;
// La part de l'écran, en hauteur, autour du joueur, et ce qu'il en reste d'opaque au centre.
const float FADE_RADIUS = 0.16;
const float FADE_KEEP = 0.25;
// Plus bas, rien ne cache personne : le sol reste plein.
const float FADE_ABOVE = 6.0;

float bayer(vec2 p) {
	int i = int(mod(p.x, 4.0)) + 4 * int(mod(p.y, 4.0));
	const float M[16] = float[](0., 8., 2., 10., 12., 4., 14., 6., 3., 11., 1., 9., 15., 7., 13., 5.);
	return M[i] / 16.0;
}

// Vrai si le fragment s'efface : au-dessus du sol, plus près de la caméra que le joueur, et
// près de lui à l'écran.
bool faded(vec2 screen_uv, vec2 viewport, float view_depth, vec2 fragcoord, float height) {
	if (height <= FADE_ABOVE || view_depth >= fade_depth) {
		return false;
	}
	float off_center = length((screen_uv - fade_center) * vec2(viewport.x / viewport.y, 1.0));
	float hidden = (1.0 - smoothstep(FADE_RADIUS * 0.6, FADE_RADIUS, off_center)) * (1.0 - FADE_KEEP);
	return bayer(fragcoord) < hidden;
}
