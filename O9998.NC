(----------------------------------------------------------------------)
( Helical Thread Milling Macro - Internal Threads - with Improvements )
( Gordon Lenz )
( Pre-NGC Haas Controller Compatible )
(----------------------------------------------------------------------)

(--------------------------)
( Variable Table           )
(--------------------------)
( #1  ->  A  RADIAL STEP OVER FOR EACH RADIAL PASS                )
( #3  ->  C  CLIMB (1) OR CONVENTIONAL (0) MILLING                 )
( #7  ->  D  MAJOR DIAMETER OF THREAD                              )
( #9  ->  I  THREADS PER INCH (TPI)                               )
( #13 ->  M  TOOL NUMBER (WILL GRAB DIAMETER FROM #4101-4120)      )
( #17 ->  Q  FEED RATE (INCHES PER MINUTE)                        )
( #18 ->  R  SAFE HEIGHT ABOVE PART FOR RAPID MOVES                )
( #19 ->  S  FEED RATE ADJUSTED FOR CHIP THINNING (INCHES PER MIN) )
( #20 ->  T  TOOL DIAMETER                                         )
( #24 ->  X  CENTER OF HOLE X-AXIS                                )
( #25 ->  Y  CENTER OF HOLE Y-AXIS                                )
( #26 ->  Z  DEPTH OF THREAD                                      )
( #115 ->     INTERNAL VARIABLE - PITCH (#1 / TPI)                  )
( #116 ->     INTERNAL VARIABLE - RADIUS OF THE TOOL PATH          )
( #117 ->     INTERNAL VARIABLE - NUMBER OF RADIAL PASSES          )
( #118 ->     INTERNAL VARIABLE - STARTING RADIUS                  )
( #119 ->     INTERNAL VARIABLE - RADIUS INCREMENT                 )
( #120 ->     INTERNAL VARIABLE - CURRENT Z LEVEL                    )
( #121 ->     INTERNAL VARIABLE - NUMBER OF Z PASSES                 )
( #122 ->     INTERNAL VARIABLE - Z PASS COUNTER                    )
( #123 ->     INTERNAL VARIABLE - RADIAL PASS COUNTER                )
( #124 ->     INTERNAL VARIABLE - CURRENT RADIUS                     )

(----------------------------------------------------------------------)

O1000 (HELICAL THREAD MILLING MACRO)

(--------------------------)
( Parameter Input Checks   )
(--------------------------)

IF[#17 LE 0] THEN #3000 = 1 (FEED RATE MUST BE POSITIVE)
IF[#9 LE 0] THEN #3000 = 2 (THREADS PER INCH MUST BE POSITIVE)
IF[#26 GE 0] THEN #3000 = 3 (THREAD DEPTH MUST BE NEGATIVE)
IF[#7 LE 0] THEN #3000 = 4 (THREAD MAJOR DIAMETER MUST BE POSITIVE)
IF[#1 LE 0] THEN #3000 = 5 (RADIAL STEP OVER MUST BE POSITIVE)
IF[#13 LE 0] THEN #3000 = 6 (INVALID TOOL NUMBER)

(--------------------------)
( Tool Diameter Lookup      )
(--------------------------)

#20 = #[4000 + #13] (GET TOOL DIAMETER FROM MACRO VAR, TOOL OFFSET #s START AT #4001)

IF[#20 GE #7] THEN #3000 = 8 (TOOL DIAMETER LARGER THAN THREAD MAJOR DIAMETER)

(---------------------------------------)
( Calculations                          )
(---------------------------------------)

#115 = 1 / #9 (CALCULATE PITCH FROM TPI)
#116 = [#7 / 2] - [#20 / 2] (MAXIMUM RADIUS OF THE TOOL PATH)
#118 = [#20 / 10] (STARTING RADIUS -  SMALL VALUE TO ENSURE IT DOESN'T START OUTSIDE THE BORE)
#117 = FIX[[#116 - #118] / #1] (NUMBER OF RADIAL PASSES - INITIAL CALCULATION)
IF[[#116 - #118] / #1 GT #117] THEN #117 = #117 + 1 (IF THERE'S A REMAINDER, ADD 1)
#119 = [[#116 - #118] / #117] (RADIUS INCREMENT FOR EACH PASS)
IF[#119 LT .0005] THEN #119 = .0005 (LIMIT THE SIZE OF THE INCREMENT TO AVOID EXCESSIVE PASSES)

(--------------------------)
( Initialization           )
(--------------------------)

G90 G54 G00 X#24 Y#25 (RAPID TO HOLE CENTER)
#120 = 0 (CURRENT Z LEVEL)
#121 = ABS[#26] / #115 (NUMBER OF Z PASSES, BASED ON PITCH)
#122 = 1 (Z PASS COUNTER)
#123 = 1 (RADIAL PASS COUNTER)
#124 = #118 (INITIALIZE CURRENT RADIUS)

(--------------------------)
( Tool Compensation        )
(--------------------------)

G41 D#13 (APPLY TOOL DIAMETER COMP)
G43 H#13 (APPLY TOOL LENGTH COMP)

(--------------------------)
( Approach                )
(--------------------------)

G00 Z#18 (RAPID TO SAFE HEIGHT)

(--------------------------------------------------)
( M0 Message with Pass Information                 )
(--------------------------------------------------)

#3006 = 1 (STOP FOR OPERATOR, MESSAGE IN BRACKETS)
M00 ([#117] RADIAL PASSES, D [#7], [#9] TPI, PITCH [#115])

(-------------------------------)
( Main Loop - Radial Passes    )
(-------------------------------)

WHILE[#123 LE #117] DO1 (LOOP FOR EACH RADIAL PASS)
  #120 = 0 (RESET Z LEVEL FOR EACH RADIAL PASS)
  #122 = 1 (RESET Z PASS COUNTER)
  (--------------------------)
  ( Chip Thinning           )
  (--------------------------)

  #19 = #17 / SIN(ACOS((#20 - 2.0 * #124) / #20)) (FEED RATE ADJUST, MORE ACCURATE, ADJUST BASED ON CURRENT RADIUS)
  IF[#19 LT #17] THEN #19 = #17 (ENSURE FEED DOES NOT GO BELOW MIN)

  G01 Z#120 F#17 (FEED TO STARTING Z)

  (------------------------------)
  ( Inner Loop - Z-Level Passes )
  (------------------------------)

  WHILE[#122 LE #121] DO2 (LOOP FOR EACH Z-LEVEL PASS)

    IF[#3 EQ 1] GOTO10 (CLIMB MILL)
    IF[#3 EQ 0] GOTO20 (CONVENTIONAL MILL)

    N10 (CLIMB MILLING)
    G01 X[#24 + #124] Y#25 F#19 (FEED TO CURRENT RADIUS - CLIMB)
    G03 X[#24 + #124] Y#25 I-#124 Z[#120 - #115] F#19 (HELICAL INTERPOLATION - CLIMB)
    GOTO30

    N20 (CONVENTIONAL MILLING)
    G01 X[#24 + #124] Y#25 F#19 (FEED TO CURRENT RADIUS - CONVENTIONAL)
    G02 X[#24 + #124] Y#25 I-#124 Z[#120 - #115] F#19 (HELICAL INTERPOLATION - CONVENTIONAL)
    GOTO30

    N30 (END OF CUTTING FOR Z-LEVEL PASS)

    #120 = #120 - #115 (DECREMENT Z LEVEL)
    #122 = #122 + 1 (INCREMENT Z PASS COUNTER)

  END2

  #124 = #124 + #119 (INCREMENT RADIUS FOR NEXT RADIAL PASS)
  #123 = #123 + 1 (INCREMENT RADIAL PASS COUNTER)
  G00 Z#18 (RAPID TO SAFE HEIGHT AT END OF EACH RADIAL PASS)

END1

(--------------------------)
( Spring Pass              )
(--------------------------)

  #120 = 0 (RESET Z FOR SPRING PASS)
  #122 = 1 (RESET Z PASS COUNTER)
  G01 Z#120 F#17 (FEED TO STARTING Z)

  WHILE[#122 LE #121] DO3 (LOOP FOR EACH Z-LEVEL PASS FOR SPRING PASS)
    IF[#3 EQ 1] GOTO40 (CLIMB MILL)
    IF[#3 EQ 0] GOTO50 (CONVENTIONAL MILL)

    N40 (CLIMB MILLING SPRING PASS)
    G01 X[#24 + #116] Y#25 F#17 (FEED TO FINAL RADIUS - CLIMB)
    G03 X[#24 + #116] Y#25 I-#116 Z[#120 - #115] F#17 (HELICAL INTERPOLATION - CLIMB, FINISHING FEED)
    GOTO60

    N50 (CONVENTIONAL MILLING SPRING PASS)
    G01 X[#24 + #116] Y#25 F#17 (FEED TO FINAL RADIUS - CONVENTIONAL)
    G02 X[#24 + #116] Y#25 I-#116 Z[#120 - #115] F#17 (HELICAL INTERPOLATION - CONVENTIONAL, FINISHING FEED)
    GOTO60

    N60 (END OF SPRING PASS Z-LEVEL)
     #120 = #120 - #115 (DECREMENT Z LEVEL)
     #122 = #122 + 1 (INCREMENT Z PASS COUNTER)

  END3

(--------------------------)
( Retraction               )
(--------------------------)

G01 X#24 Y#25 F[#17 * 2] (FEED TO CENTER, AT A HIGHER FEED FOR RETRACTION)
G00 Z#18 (RAPID TO SAFE HEIGHT)
G40 (CANCEL TOOL COMP)

M99 (RETURN FROM SUBPROGRAM)

(-----------------------------------------------------------------------)
( Example M98 Call with Alphabetic Shortcuts - INTERNAL THREAD )
(-----------------------------------------------------------------------)
( G54 X0 Y0 -  HOLE CENTER )
( Z0 - TOP OF THE PART )
( T1 M06 - SELECT TOOL, #4001 WILL HAVE CORRECT TOOL DIAMETER )
( #4001=0.25 - SET TOOL DIAMETER FOR T1)

( ... REST OF YOUR PROGRAM ...)

( M98 P1000 X0 Y0 Z-0.5 D0.75 I20. A0.01 Q6. M1 R0.1 C1 )
(   |  |   |  |  |     |     |    |      |   |    |  | |
(   |  |   |  |  |     |     |    |      |   |    |  | +-- C - MILLING TYPE: 1=CLIMB, 0=CONVENTIONAL (DEFAULT=1)
(   |  |   |  |  |     |     |    |      |   |    |  +----- R - SAFE Z HEIGHT ABOVE PART (DEFAULT=0.1)
(   |  |   |  |  |     |     |    |      |   |    +-------- M - TOOL NUMBER (REQUIRED)
(   |  |   |  |  |     |     |    |      |   +------------- Q - FEED RATE (INCHES PER MINUTE) (REQUIRED)
(   |  |   |  |  |     |     |    |      +----------------- A - RADIAL STEP OVER FOR EACH RADIAL PASS (REQUIRED)
(   |  |   |  |  |     |     |    +------------------------ I - THREADS PER INCH (TPI) (REQUIRED)
(   |  |   |  |  |     |     +----------------------------- D - THREAD MAJOR DIAMETER (REQUIRED)
(   |  |   |  |  |     +------------------------------------ Z - THREAD DEPTH (NEGATIVE VALUE) (REQUIRED)
(   |  |   |  |  +------------------------------------------- Y - Y COORDINATE OF HOLE CENTER (REQUIRED)
(   |  |   |  +------------------------------------------------ X - X COORDINATE OF HOLE CENTER (REQUIRED)
(   |  |   +------------------------------------------------------ P - SUBPROGRAM NUMBER (1000 IN THIS CASE)
(   |  +--------------------------------------------------------- M98 - SUBPROGRAM CALL
(   +------------------------------------------------------------ (COMMENT START)

( ... REST OF YOUR PROGRAM ...)

M30 (END OF PROGRAM)