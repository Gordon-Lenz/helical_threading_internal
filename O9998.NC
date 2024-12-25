(------------------------------------------------------------------)
( Program Name: SINGLE_POINT_THREAD_MILL                      )
( Author: Gemini Advanced                                       )
( Date: 2024-12-25                                              )
( Version: v0.01                                                )
( Description: This subprogram single-point thread mills multiple)
(              holes helically. It uses the tool wear offsets   )
(              for diameter and length. Helical entry starts    )
(              from the center of the hole and works upwards.   )
(              Tool cuts to the thread major diameter at the   )
(              finished depth. Radial depth per pass controls  )
(              the infeed in the X-axis. Overshoots the top of  )
(              the hole by one thread pitch to ensure complete  )
(              threads. Includes a retract plane parameter.     )
(              Performs parameter checks to prevent errors.     )
(              Uses the F parameter for all feedrates.          )
(              Adds a final radial pass if depth doesn't divide )
(              evenly.                                         )
(------------------------------------------------------------------)
( Macro Variables:                                                )
( #4  - I: TPI (Threads Per Inch)                                )
( #7  - D: Thread major diameter                                 )
( #26 - Z: Z coordinate where the thread ends                     )
( #20 - T: Tool number                                             )
( #22 - V: Radial depth per pass (in X-axis)                       )
( #9  - F: Feedrate                                               )
( #18 - R: Retract plane Z-coordinate                             )
( #24 - X: X coordinate of hole center                             )
( #25 - Y: Y coordinate of hole center                             )
( #13 - M: Optional hole top height (Z-coordinate)                )
(------------------------------------------------------------------)

O9998  
    (Check for missing parameters)
    IF [#4 EQ 0] THEN #3000 = 1 (Alarm if TPI is missing)
    IF [#7 EQ 0] THEN #3000 = 2 (Alarm if major diameter is missing)
    IF [#26 EQ 0] THEN #3000 = 3 (Alarm if thread end Z is missing)
    IF [#20 EQ 0] THEN #3000 = 4 (Alarm if tool number is missing)
    IF [#22 EQ 0] THEN #3000 = 5 (Alarm if radial depth is missing)
    IF [#9 EQ 0] THEN #3000 = 6 (Alarm if feedrate is missing)
    IF [#18 EQ 0] THEN #3000 = 7 (Alarm if retract plane is missing)
    IF [#24 EQ 0] THEN #3000 = 8 (Alarm if X coordinate is missing)
    IF [#25 EQ 0] THEN #3000 = 9 (Alarm if Y coordinate is missing)
    IF [#3000 NE 0] GOTO 9999 (Jump to alarm section if any parameter is missing)

    (Set hole top height)
    IF [#13 EQ 0] THEN #13 = #5043 (Use Z0 if M is not provided)

    G00 G90 Z[#18 + .1]    (Rapid to retract plane + .1)
    G43 Z.1 H#20           (Apply tool length offset from tool number)
    G01 Z#18 F#9           (Feed to retract plane)
    
    #100 = [#7 / 2] / #22  (Calculate number of passes based on radial depth)
    #101 = 1              (Initialize pass counter)
    
    WHILE [#101 LE #100] DO1  (Loop for each pass)
        #102 = #22 * #101   (Calculate current radial depth)
        IF [#102 GT [#7 / 2]] THEN #102 = [#7 / 2] (Limit to thread radius)
        
        G01 X#24 Y#25 F#9  (Feed to hole center)
        G01 Z#26 F#9       (Feed down to final thread depth)
        G41 X[#102] D#20    (Compensate with tool diameter offset)
        G03 X[#102 + .1] I[-#102] F#9 (Helical entry move) 

        (Calculate Z movement for this pass, overshooting by one pitch)
        #103 = ABS(#26 - #13) + [1 / #4]  (Total distance + one pitch)
        #104 = #103 - (#101 - 1) * #22 * [1 / #4] (Remaining distance)
        IF [#104 GT [#22 * #4]] THEN #104 = #22 * #4 (Limit to one pass)

        G91 G03 I[-#102] Z[1 / #4] L[#104 - 1] F#9 (Helical threading upwards)

        G90 G03 X[#102 + .1] I[-#102] F#9 (Helical exit move)
        G01 X#24 Y#25 F#9  (Return to center)

        #101 = #101 + 1    (Increment pass counter)
    END1

    (Check if a final radial pass is needed)
    #105 = [#7 / 2] MOD #22 (Calculate remainder of radius divided by radial depth)
    IF [#105 GT 0] THEN
        G01 X#24 Y#25 F#9  (Feed to hole center)
        G01 Z#26 F#9       (Feed down to final thread depth)
        G41 X[#7 / 2] D#20  (Compensate and move to major diameter)
        G03 X[[#7 / 2] + .1] I[-[#7 / 2]] F#9 (Helical entry move)

        (Calculate Z movement for the final pass, overshooting by one pitch)
        #103 = ABS(#26 - #13) + [1 / #4]  (Total distance + one pitch)
        #104 = #103 - #100 * #22 * [1 / #4] (Remaining distance)
        IF [#104 GT [#22 * #4]] THEN #104 = #22 * #4 (Limit to one pass)

        G91 G03 I[-[#7 / 2]] Z[1 / #4] L[#104 - 1] F#9 (Helical threading upwards)

        G90 G03 X[[#7 / 2] + .1] I[-[#7 / 2]] F#9 (Helical exit move)
        G01 X#24 Y#25 F#9  (Return to center)
    ENDIF

    G01 Z#18 F#9           (Feed to retract plane)
    G00 Z[#18 + .1]       (Rapid retract to retract plane + .1)
    G28 G91 Z0             (Return to Z home)
    M99                    (End of subprogram)

(Alarm section)
N9999 
    #3000 = #3000 (Force the alarm)
    M99