King of Fighters '98UMFE and 2002UM hitbox viewer
https://github.com/odabugs/kof-combo-hitboxes

To compile with MinGW: make.bat (native), make (Linux + MinGW or Cygwin)
If MinGW's GCC gives a compile error to the effect of "Unknown type name
SOLE_AUTHENTICATION_SERVICE", this is usually fixed by running "make" again.
Compilation with Visual Studio currently not supported.

Usage notes:
- Requires Windows Vista or newer, with Windows Aero and Desktop Window
  Manager (DWM) enabled.
- Start either KOF '98UMFE or KOF 2002UM, then start the viewer .exe.
- Additional instructions and hotkeys are presented upon program startup.
- The config file (default.ini) can be used to change display settings.

TODO:
- Make box layer drawing order configurable (currently hardcoded).
- Make drawing of all box types togglable in the config file (currently only the
  "throw" and "throwable" box types can be disabled wholesale, the rest can be
  "mostly hidden" to show only box borders by giving them a color with an
  opacity of 0).
- Figure out proximity detection for moves like Kyo hcb+K or Clark running grab.
- Better detection of when to suppress hitbox drawing (e.g., char select screen).
- Figure out counterhit vulnerable hitbox states in greater depth.
- Look into API hooking.
  - Does Microsoft Detours play well with MinGW?
  - Possible MinGW-friendly alternative: https://github.com/TsudaKageyu/minhook
    - http://www.codeproject.com/Articles/44326/MinHook-The-Minimalistic-x-x-API-Hooking-Libra
- Maybe integrate the Steam Anti-Anti Debugger?
  - http://www.thehackerwithin.com/blog/11-08-07/Steam_s_anti-debugging_code.aspx
- Support KOF 2002UM's Type A graphics setting (sprites are scaled differently in Type A)

Known issues:
- Pivots/hitboxes don't show up in Steam screenshots (probably solved by API hooking).
- Timing is not yet perfectly synchronized with the game.
  - This makes displaying throw boxes at the right time so unreliable that
    we just display whatever data is in the throwbox slot for now
    (works good enough for wiki data-collecting purposes).
- Stun recovery gauge can appear inaccurate for a brief time if the stunned
  player mashes to recover from dizzy state faster.
