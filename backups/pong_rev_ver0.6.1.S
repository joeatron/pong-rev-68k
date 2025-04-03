;----------------------------------------------------------
;		pong revolution ver0.6.1(00:55 04/10/2021) - funny story, there is a bug in this version
;		BY Extra Joe								 with the ball direction code (wants to go left, removed the ball controls because they are not useful anymore and the glich made them impractical)
;----------------------------------------------------------
		INCLUDE	SYSTEM.S		;INCLUDES LOTS OF SYSTEM code TO MAKE ALL THIS POSSIBLE (hopefully replase later) By Jon Burton (GameHut)

;----------------------------------------------------------
;		VRAM MEMORY MAP IN HEXADECIMAL
;----------------------------------------------------------
;		$0000-$0020			BLANK CHARACTER
;		$0020-$8000			CHARACTERS FOR PLAYFIELDS AND SPRITES
;		$C000-$D000			CHARACTER MAP FOR PLAYFIELD 1 (4096 BYTES)
;		$E000-$F000			CHARACTER MAP FOR PLAYFIELD 2 (4096 BYTES)
;		$F800				SPRITE TABLE (960 BYTES)

;----------------------------------------------------------
;		USER VARIABLES
;----------------------------------------------------------
		RSSET	USERRAM
player1X:	RS.W	1				;player1'S X position
player1Y:	RS.W	1				;player1'S Y position
player2X:	RS.W	1				;player2'S X position
player2Y:	RS.W	1				;player2'S Y position
player1S:	RS.W	1				;Player1'S score 
player2S:	RS.W	1				;player2'S score
BallX:		RS.W	1				;Ball'S X position
BallY:		RS.W	1				;Ball'S Y position
BallD:		RS.W	1				;Ball'S direction
BallYM:		RS.W	1				;Ball'S Y movement (Y speed)
BallXM:		RS.W	1				;Ball'S X movement (X speed)
BallYD:		RS.w	1	
TBar:		RS.W	1				;top barrier
BBar:		RS.W	1				;bottom barrier
TEMPSCREEN:	RS.B	4096			;RAM TO BUILD TEMPORARY SCREEN MAP
ENDVARS:	RS.B	0

;----------------------------------------------------------
;		INITIALISE USER STUFF
;		- THIS IS WHERE YOU SET UP STUFF BEFORE YOU BEGIN
;----------------------------------------------------------
USERINIT:	
		DMADUMP	BallGFX,1*32,$1100			;DUMP 1 CHARACTERS (SIZE 32 BYTES EACH) TO VRAM LOCATION $1100 (MAP GRAPHICS)
		DMADUMP	SPRITEGFX,3*32,$1000		;DUMP 3 CHARACTERS (SIZE 32 BYTES EACH) TO VRAM LOCATION $1000 (SPRITE GRAPHICS)
;----------------------------------------------------------
;		Palettes
;----------------------------------------------------------
		LEA.L	PALETTE1,A0					;DOWNLOAD A PALETTE FOR THE MAP TO USE
		BSR	SETPAL1							;OVERRIGHT FIRST PALETTE

		LEA.L	PALETTE2,A0					;DOWNLOAD A PALETTE FOR THE SPRITES TO USE
		BSR	SETPAL2							;OVERRIGHT SECOND PALETTE	

		JSR	DUMPCOLS						;COPY ALL PALETTES TO CRAM (COLOUR RAM)

		move.W	#$80+160-130,player1X		;player1'S X START POSITION
		move.W	#$80+112-13,player1Y		;player1'S Y START POSITION
		move.W	#$80+160+130,player2X		;player2'S X START POSITION
		move.W	#$80+112-13,player2Y		;player2'S Y START POSITION
		move.W	#$80+80+80,BallX			;ball X START POSITION
		move.W	#$80+112-13,BallY			;ball Y START POSITION
		move.W	#$80+13-13,TBar				;ball Y START POSITION
		move.W	#$80+230-13,BBar			;ball Y START POSITION
		move.B 	#1,BallD					;BallD starting value
		move.W	#1,BallXM
		move.B	#1,BallYD
		move.w	#1,ballYM
		RTS

;------------------------------
;	MAIN GAME LOOP
;------------------------------
MAIN:		WAITVBI							;WAITS FOR THE START OF THE NEXT FRAME
;add SPRITES
		LEA.L	SPRITETEMP,A1				;POINT TO TEMPORARY MEMORY TO BUILD SPRITE LIST
		move.W	#1,D7

;-------------player stuff-------------

;player 1
		move.W	player1Y,(A1)+				;Y POSITION ($80 IS TOP OF SCREEN)
		move.W	#S_1X3,D0					;SIZE 1X3 (X-Y )CHARACTERS
		add.W	D7,D0						;add CURRENT SPRITE NUMBER
		move.W	D0,(A1)+					;WRITE TO SPRITE TABLE
		move.W	#S_PAL2+$1000/32,D0			;PALETTE NUMBER+GRAPHIC VRAM LOCATION/32
		move.W	D0,(A1)+					;WRITE TO SPRITE TABLE
		move.W	player1X,(A1)+				;X POSITION ($80 IS LEFT OF SCREEN)

		addq.W	#1,D7

;player 2							
		move.W	player2Y,(A1)+				;Y POSITION ($80 IS TOP OF SCREEN)
		move.W	#S_1X3,D0					;SIZE 1X3 (X-Y) CHARACTERS
		add.W	D7,D0						;add CURRENT SPRITE NUMBER
		move.W	D0,(A1)+					;WRITE TO SPRITE TABLE
		move.W	#S_PAL2+$1000/32,D0			;PALETTE NUMBER+GRAPHIC VRAM LOCATION/32
		move.W	D0,(A1)+					;WRITE TO SPRITE TABLE
		move.W	player2X,(A1)+				;X POSITION ($80 IS LEFT OF SCREEN)

		addq.W	#1,D7						;move ON TO NEXT SPRITE NUMBER

;Ball							
		move.W	BallY,(A1)+					;Y POSITION ($80 IS TOP OF SCREEN)
		move.W	#S_1X1,D0					;SIZE 1X1 (X-Y) CHARACTERS
		add.W	D7,D0						;add CURRENT SPRITE NUMBER
		move.W	D0,(A1)+					;WRITE TO SPRITE TABLE
		move.W	#S_PAL2+$1100/32,D0			;PALETTE NUMBER + VRAM LOCATION/32 in to D0
		move.W	D0,(A1)+					;WRITE TO SPRITE TABLE 
		move.W	BallX,(A1)+					;X POSITION ($80 IS LEFT OF SCREEN)

		addq.W	#1,D7						;move ON TO NEXT SPRITE NUMBER

											;A1=POINTER TO NEXT SPRITE ENTRY
											;D7=NEXT SPRITE NUMBER
;END
		move.L	#$10000,(A1)+				;TERMINATE SPRITE LIST
		move.L	#1,(A1)+					;	"  "
		
;-------------Paddle Hit Detection Start-------------

		move.w	BallX,D3					;put BallX in to D3
		move.w	BallY,D4					;put BallY in to D4
		
		;right paddle
		cmp.b	#1,d5						;if d5 (BallD) is 1 (the direction for right)
		beq	@Paddlehit						;goto right paddle hit decetion code

		;left paddle offset (makes it so it hits the start of the paddle instead of the start of the spite)
		move.w 	player1X,d1					;put player1X in to d1
		add.b	#8,D1						;adds 8 to D1 (player1X)

		cmp.b 	D1,D3						;if d3 = d1
		beq	@setuploop2							;goto Left paddle hit dectection
		jmp	@boarder						;goto the boarder code (top and bottom of screen)
@Paddlehit:									
		move.w 	player2X,d1					;put player2X in to D1
		sub.b	#8,D1						;subs 8 from player2x (d1) - does this so that we hit the front of player 2

		cmp.b 	D1,D3						;If D1(player2X) = D3(BallX)
		beq	@setuploop						;If the ball touches then do the setup loop
		jmp	@boarder						;If not then skip this and go to boarder hit code

@setuploop2:
		move.w	player1Y,d1					;puts player2Y in to D1 (removes Player2X from there)		
		sub.b 	#$06,d1						;adds 6 to the size of the paddle (makes the entire ball hitable)
		move.b 	#$00, d2					;puts zero in to index (d2)
		;move.w	#$d,d0	
		bra		@Hitloop

@setuploop:
		move.w	player2Y,d1					;puts player2Y in to D1 (removes Player2X from there)		
		sub.b 	#$06,d1						;adds 6 to the size of the paddle (makes the entire ball hitable)
		move.b 	#$00, d2					;puts zero in to index (d2)
		;move.w	#$d,d0	


@Hitloop:									;This is set up like a for loop
		cmp.b d2, d1						;compaire index counter (d2) to player Y (d1)
		cmp.b d1,d4							;compaire player Y (d1) to ball y (d4) (if we find a mach then jump to hit code)
		beq @Hit
		cmp.b #$1e,d2						;if we do not find match in paddle lenth then do the top and bottom scans
		beq @miss
		add.b #$01,d2						;add 1 to index counter (d2)
		add.b #$01,d1						;adds 1 to player y so we can compair the entire paddel to the balls point of hit
		;sub.w #$1,d0						;takes 4 off Y momentium (runs in to negatives at some point)
		bra.s @Hitloop						;restarts loop

@miss:
		move.W	#$80+160-130,player1X		;player1'S X START POSITION
		move.W	#$80+112-13,player1Y		;player1'S Y START POSITION
		move.W	#$80+160+130,player2X		;player2'S X START POSITION
		move.W	#$80+112-13,player2Y		;player2'S Y START POSITION
		move.W	#$80+80+80,BallX			;ball X START POSITION
		move.W	#$80+112-13,BallY			;ball Y START POSITION
		move.B 	#1,BallD					;BallD starting value
		move.W	#1,BallXM
		move.B	#1,BallYD
		move.w	#1,ballYM

@hit
		cmp.B	#1,BallD
		beq		@Rhit	
		move.b	#1,BallD     				;put 1 in BallD (Makes Ball go Right)
		jmp	@boarder						;goto Ball_code (Ball movement code)
@Rhit:	
		move.b	#0,BallD     				;put 0 in BallD (Makes Ball go left)

@boarder:
		move.w	ballYM,d0
		move.W	Tbar, d1
		cmp.b 	d1,d4
		beq		@BHit
		move.W	Bbar,d1
		cmp.B	d1,d4
		beq		@BHit
		bra		@Ball_code

@BHit:	
		neg.w	d0							;fip Y momentium

;Ball movement code
@Ball_code:	
		add.w 	d0,BallY
		move.w	d0,ballym
		move.b	BallD,d5					;put BallD in to D5	
		cmp.w	#0,d5						;check if the direction of ball is left? (d5)
		beq	@skip							;goto skip (so that it goes left)
		;add.w	D0,BallX					;add 2 to BallX - this is important as it will hit @skip so this is needed to get a +1 movment going right
		add.w	#4,BallX
@skip:
		sub.w	#2,BallX					;sub 1 to BallX - makes it go left
		;Ball movement code

;move player1
		btst	#J_DOWN,JOYPAD0
		bne.S	@move1
		add.W	#2,player1Y	
@move1:
		btst	#J_UP,JOYPAD0
		bne.S	@move2
		SUB.W	#2,player1Y	
;move player2
@move2:
		btst	#J_BUT_A,JOYPAD0
;		btst	#J_DOWN,JOYPAD1
		bne.S	@move3
		SUB.W	#2,player2Y	
		
@move3:
		btst	#J_BUT_B,JOYPAD0
;		btst	#J_UP,JOYPAD1
		bne.S	@NORING
		add.W	#2,player2Y		
@NORING:

		BRA	MAIN							;LOOP BACK TO WAIT FOR NEXT FRAME
		
;----------------------------------------------------------
;		USER VBI ROUTINES
;		- PUT TIME CRITICAL code THAT MUST CALLED DURING THE VERTICAL BLANK HERE
;----------------------------------------------------------
USERVBI:	LEA.L	VDP_DATA,A1
			LEA.L	VDP_CONTROL,A2
;SET HORIZONTAL OFFSETS
;		move.L	#$7C000003,(A2)
;		move.L	PLAYX,(A1)					;THIS TELLS THE VDP (VISUAL DISPLAY PROCESSOR) WHAT X POSITION THE PLAYFIELDS SHOULD BE AT

;SET VERTICAL OFFSETS
;		move.L	#$40000010,(A2)				;THIS TELLS THE VDP WHAT Y POSITION THE PLAYFIELDS SHOULD BE AT
;		move.L	PLAYY,(A1)

;COPY SPRITE TABLE TO VRAM
		JSR	SPRITEDUMP
;READ JOYPAD
		BSR	READJOY							;READ THE JOYPAD

		RTS

;----------------------------------------------------------
;		SPRITE GRAPHICS
;		2 X 4 CHARACTERS ARRANGED AS FOLLOWS -
;
;		1 3
;		2 4
;		
;		
;----------------------------------------------------------
SPRITEGFX:									;paddle (both paddles are the same gfx)
		DC.B	$04,$44,$44,$40				;1
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
				
		DC.B	$44,$44,$44,$44				;2
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		
		DC.B	$44,$44,$44,$44				;3
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$44,$44,$44,$44
		DC.B	$04,$44,$44,$40
;----------------------------------------------------------
BallGFX:									;Ball
		DC.B	$04,$44,$44,$00				;2
		DC.B	$44,$44,$44,$40
		DC.B	$44,$44,$44,$40
		DC.B	$44,$44,$44,$40
		DC.B	$44,$44,$44,$40
		DC.B	$44,$44,$44,$40
		DC.B	$04,$44,$44,$00
		DC.B	$00,$00,$00,$00
;----------------------------------------------------------
;		USER PALETTES
;----------------------------------------------------------
PALETTE1:									;was used for the background, is unused currently 
		DC.W	$0000,$0044,$0066,$0088
		DC.W	$00AA,$00EE,$0888,$FF00
		DC.W	$0EEE,$0CCC,$0AAA,$0888
		DC.W	$0666,$0444,$0222,$0000

PALETTE2:									;all sprites use this one
		DC.W	$0000,$0000,$0F80,$08CE	
		DC.W	$0EEE,$00E0,$000E,$00EE
		DC.W	$0088,$0044,$0066,$0AAA
		DC.W	$0666,$0444,$0222,$0888

