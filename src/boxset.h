#ifndef BOXSET_H
#define BOXSET_H

#include <stdlib.h>
#include "gamedefs.h"
#include "boxtypes.h"
#include "playerstruct.h"

// slight overkill to ensure enough room for all projectiles (e.g., Chin flames)
#define LAYER_BOXES 20

extern void clearStoredBoxes();
extern bool storeBox(int player, boxtype_t type, hitbox_t *hitbox);
extern boxtype_t boxTypeForLayer(int layer);
extern hitbox_t *playerBoxesInLayer(int player, int layer);
extern int playerBoxCountInLayer(int player, int layer);

#endif /* BOXSET_H */
