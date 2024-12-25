# Single-Point Thread Milling Subprogram

## Features

*   **Helical Thread Milling:**  Generates a helical toolpath for single-point thread milling.
*   **Multiple Holes:** Can be used to thread multiple holes by specifying X and Y coordinates in the main program.
*   **Tool Wear Offsets:** Uses the tool wear offsets for diameter and length to ensure accurate threading.
*   **Bottom-Up Threading:** Starts threading from the bottom of the hole and works upwards.
*   **Overshoot:**  Overshoots the top of the hole by one thread pitch to ensure complete threads.
*   **Retract Plane:**  Includes a retract plane parameter for safe tool movements.
*   **Feedrate Control:** Uses the F parameter for all feedrates.
*   **Final Radial Pass:** Adds a final radial pass if the depth doesn't divide evenly by the radial depth of cut.
*   **Parameter Checks:**  Performs parameter checks to prevent errors due to missing parameters.
*   **Optional Hole Top Height:** Allows specifying an optional hole top height; uses Z0 if not entered.

## Macro Variables

|Parameter|Variable|Required|Description|
|:---|:---|:---|:---|
|I|#4|Required|TPI (Threads Per Inch)|
|D|#7|Required|Thread major diameter|
|Z|#26|Required|Z coordinate for bottom of thread|
|T|#20|Required|Tool number|
|V|#22|Required|Radial depth per pass (in X-axis)|
|F|#9|Required|Feedrate|
|R|#18|Required|Retract plane Z-coordinate|
|X|#24|Required|X coordinate of hole center|
|Y|#25|Required|Y coordinate of hole center|
|M|#13|Optional|Hole top height (Z-coordinate). Uses Z0 if not entered.|