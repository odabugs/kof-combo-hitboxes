#ifndef COLORS_H
#define COLORS_H

#include <GL/gl.h>
#include "boxtypes.h"

#define BOX_EDGE_ALPHA 255
#define BOX_FILL_ALPHA 128
#define PIVOT_ALPHA 255

// glColor3ubv will ignore the "alpha" element, while glColor4ubv will read it
extern GLubyte colorset[7][4];
extern GLubyte playerPivotColor[4];

#endif /* COLORS_H */
