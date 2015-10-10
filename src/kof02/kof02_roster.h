#ifndef NO_KOF_02
#include "../gamedefs.h"
// this number includes the invalid character ID 0x3F
#define KOF_02_ROSTER_SIZE 0x45
static character_def_t kof02_roster[KOF_02_ROSTER_SIZE] = {
	{
		.charID = 0x00,
		.charName = "Kyo"
	},
	{
		.charID = 0x01,
		.charName = "Benimaru"
	},
	{
		.charID = 0x02,
		.charName = "Daimon"
	},
	{
		.charID = 0x03,
		.charName = "Terry"
	},
	{
		.charID = 0x04,
		.charName = "Andy"
	},
	{
		.charID = 0x05,
		.charName = "Joe"
	},
	{
		.charID = 0x06,
		.charName = "Kim"
	},
	{
		.charID = 0x07,
		.charName = "Chang"
	},
	{
		.charID = 0x08,
		.charName = "Choi"
	},
	{
		.charID = 0x09,
		.charName = "Athena"
	},
	{
		.charID = 0x0A,
		.charName = "Kensou"
	},
	{
		.charID = 0x0B,
		.charName = "Chin"
	},
	{
		.charID = 0x0C,
		.charName = "Leona"
	},
	{
		.charID = 0x0D,
		.charName = "Ralf"
	},
	{
		.charID = 0x0E,
		.charName = "Clark"
	},
	{
		.charID = 0x0F,
		.charName = "Ryo"
	},
	{
		.charID = 0x10,
		.charName = "Robert"
	},
	{
		.charID = 0x11,
		.charName = "Takuma"
	},
	{
		.charID = 0x12,
		.charName = "Mai"
	},
	{
		.charID = 0x13,
		.charName = "Yuri"
	},
	{
		.charID = 0x14,
		.charName = "May Lee"
	},
	{
		.charID = 0x15,
		.charName = "Iori"
	},
	{
		.charID = 0x16,
		.charName = "Mature"
	},
	{
		.charID = 0x17,
		.charName = "Vice"
	},
	{
		.charID = 0x18,
		.charName = "Yamazaki"
	},
	{
		.charID = 0x19,
		.charName = "Mary"
	},
	{
		.charID = 0x1A,
		.charName = "Billy"
	},
	{
		.charID = 0x1B,
		.charName = "Yashiro"
	},
	{
		.charID = 0x1C,
		.charName = "Shermie"
	},
	{
		.charID = 0x1D,
		.charName = "Chris"
	},
	{
		.charID = 0x1E,
		.charName = "K'"
	},
	{
		.charID = 0x1F,
		.charName = "Maxima"
	},
	{
		.charID = 0x20,
		.charName = "Whip"
	},
	{
		.charID = 0x21,
		.charName = "Vanessa"
	},
	{
		.charID = 0x22,
		.charName = "Seth"
	},
	{
		.charID = 0x23,
		.charName = "Ramon"
	},
	{
		.charID = 0x24,
		.charName = "Kula"
	},
	{
		.charID = 0x25,
		.charName = "Nameless"
	},
	{
		.charID = 0x26,
		.charName = "Angel"
	},
	{
		.charID = 0x27,
		.charName = "Omega Rugal"
	},
	{
		.charID = 0x28,
		.charName = "Kusanagi"
	},
	{
		.charID = 0x29,
		.charName = "Shingo"
	},
	{
		.charID = 0x2A,
		.charName = "King"
	},
	{
		.charID = 0x2B,
		.charName = "Xiangfei"
	},
	{
		.charID = 0x2C,
		.charName = "Hinako"
	},
	{
		.charID = 0x2D,
		.charName = "Heidern"
	},
	{
		.charID = 0x2E,
		.charName = "Lin"
	},
	{
		.charID = 0x2F,
		.charName = "EX Takuma"
	},
	{
		.charID = 0x30,
		.charName = "Bao"
	},
	{
		.charID = 0x31,
		.charName = "Jhun"
	},
	{
		.charID = 0x32,
		.charName = "Kyo-1"
	},
	{
		.charID = 0x33,
		.charName = "Foxy"
	},
	{
		.charID = 0x34,
		.charName = "Kasumi"
	},
	{
		.charID = 0x35,
		.charName = "Geese"
	},
	{
		.charID = 0x36,
		.charName = "EX Geese"
	},
	{
		.charID = 0x37,
		.charName = "EX Robert"
	},
	{
		.charID = 0x38,
		.charName = "EX Kensou"
	},
	{
		.charID = 0x39,
		.charName = "Kyo-2"
	},
	{
		.charID = 0x3A,
		.charName = "Goenitz"
	},
	{
		.charID = 0x3B,
		.charName = "Krizalid"
	},
	{
		.charID = 0x3C,
		.charName = "C-Zero"
	},
	{
		.charID = 0x3D,
		.charName = "Zero"
	},
	{
		.charID = 0x3E,
		.charName = "Igniz"
	},
	{
		.charID = 0x3F,
		.charName = "INVALID"
	},
	{
		.charID = 0x40,
		.charName = "Yashiro (Orochi)"
	},
	{
		.charID = 0x41,
		.charName = "Shermie (Orochi)"
	},
	{
		.charID = 0x42,
		.charName = "Chris (Orochi)"
	},
	{
		.charID = 0x43,
		.charName = "Edit random"
	},
	{
		.charID = 0x44,
		.charName = "Team random"
	}
};
#endif /* NO_KOF_02 */
