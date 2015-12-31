King of Fighters '98UMFE and 2002UM hitbox viewer

To compile with MinGW: make.bat
Compilation with Visual Studio currently not yet tested.

TODO:
- Support loading settings (e.g., box colors) from a config file.
- Make box layer drawing order configurable (currently hardcoded).
- Figure out proximity detection for moves like Kyo hcb+K or Clark run grab.
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
