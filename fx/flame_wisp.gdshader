shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// En lumière : les couches s'ajoutent, jaune presque blanc où elles s'empilent, près de la
// boule, orange puis rouge en s'effilochant (« en lumière », choisie sur planche).
#define RAGGED 2.1
#define SOFT 0.45
#define BOOST 0.5
#define RIM(edge) 1.0

#include "res://fx/flame_wisp.gdshaderinc"
