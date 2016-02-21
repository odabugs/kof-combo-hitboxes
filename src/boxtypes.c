#include "boxtypes.h"

// box type names used in the config file
// must be in the same order as the boxtype_t enum (see boxtypes.h)
char *boxTypeNames[] = {
	"collisionBox",
	"vulnerableBox",
	"counterVulnerableBox",
	"anywhereJuggleVulnerableBox",
	"otgVulnerableBox",
	"guardBox",
	"attackBox",
	"projectileVulnerableBox",
	"projectileAttackBox",
	"throwableBox",
	"throwBox",
	(char*)NULL
};
