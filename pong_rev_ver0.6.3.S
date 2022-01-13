;----------------------------------------------------------
;		pong revolution ver0.6.3(00:55 04/10/2021) 
;		BY Joe-a-tron	-Re did branding, desided that I should just use my main instead of extra
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
PLAYX:		RS.L	0
PLAY1X:		RS.W	1			;X POSITION OF PLAYFIELD 1
PLAY2X:		RS.W	1			;X POSITION OF PLAYFIELD 2
PLAYY:		RS.L	0
PLAY1Y:		RS.W	1			;Y POSITION OF PLAYFIELD 1
PLAY2Y:		RS.W	1			;Y POSITION OF PLAYFIELD 2

player1X:	RS.W	1				;player1'S X position
player1Y:	RS.W	1				;player1'S Y position
player2X:	RS.W	1				;player2'S X position
player2Y:	RS.W	1				;player2'S Y position
player1S:	RS.W	1				;Player1'S score 
player2S:	RS.W	1				;player2'S score

BallX:		RS.W	1				;Ball'S X position
BallY:		RS.W	1				;Ball'S Y position
BallD:		RS.W	1				;Ball'S direction (unused for now, may get re-implemented later)
BallYM:		RS.W	1				;Ball'S Y movement (Y speed)
BallXM:		RS.W	1				;Ball'S X movement (X speed)

BallYD:		RS.w	1	
TBar:		RS.W	1				;top barrier
BBar:		RS.W	1				;bottom barrier
LBar:		RS.W	1
RBar:		RS.W	1


TEMPSCREEN:	RS.B	4096			;RAM TO BUILD TEMPORARY SCREEN MAP
ENDVARS:	RS.B	0

;----------------------------------------------------------
;		INITIALISE USER STUFF
;		- THIS IS WHERE YOU SET UP STUFF BEFORE YOU BEGIN
;----------------------------------------------------------
USERINIT:	
		DMADUMP	BallGFX,1*32,$1100			;DUMP 1 CHARACTERS (SIZE 32 BYTES EACH) TO VRAM LOCATION $1100 (MAP GRAPHICS)
		DMADUMP	SPRITEGFX,3*32,$1000		;DUMP 3 CHARACTERS (SIZE 32 BYTES EACH) TO VRAM LOCATION $1000 (SPRITE GRAPHICS)
		DMADUMP	tileset1,1*32,$20			;DUMP 4 CHARACTERS (SIZE 32 BYTES EACH) TO VRAM LOCATION $20 (HEXADECIMAL)


		move.w	#4,play1X					;shift screen by 4 to center tilemap
		move.w	#0,play1Y		

		LEA.L	TEMPSCREEN,A0				;POINT A0 TO TEMPORARY BUFFER IN RAM TO BUILD MAP BEFORE WE COPY TO VRAM

		move.W	#9,d1						;counter for dbra
@grabtile:					
		lea.l	tilemap1,A1					;tile 1 out of 2 per bar
		add.l	#38,a0						;center of screen (nearly)
		move.l	(a1)+,(a0)+					;place tilemap (1 tile in there)
		add.L	#86,a0						;rest of line

		lea.l	tilemap1,A1					;tile 2 out of 2 per bar
		add.l	#38,a0						;center of screen (nearly)
		move.l	(a1)+,(a0)+					;place tilemap (1 tile in there)
		add.L	#86,a0						;rest of line

		add.l	#128,a0						;goes down a line (128 is a full line)
		dbra 	d1,@grabtile				;for I in D1 goto @grabtile

		DMADUMP	TEMPSCREEN,4096,$C000		;dump the screen in video ram
;----------------------------------------------------------
;		Palettes
;----------------------------------------------------------
		LEA.L	PALETTE2,A0					;DOWNLOAD A PALETTE FOR THE SPRITES TO USE
		BSR	SETPAL2							;OVERRIGHT SECOND PALETTE	

		JSR	DUMPCOLS						;COPY ALL PALETTES TO CRAM (COLOUR RAM)

		move.W	#$80+160-130,player1X		;player1'S X START POSITION
		move.W	#$80+112-13,player1Y		;player1'S Y START POSITION
		move.W	#$80+160+130,player2X		;player2'S X START POSITION
		move.W	#$80+112-13,player2Y		;player2'S Y START POSITION
		move.W	#$80+80+80,BallX			;ball X START POSITION
		move.W	#$80+112-13,BallY			;ball Y START POSITION
		move.W	#$80+14-13,TBar				;ball Y START POSITION
		move.W	#$80+230-13,BBar			;ball Y START POSITION	
		move.W	#$80+160-140,LBar			;player1'S X START POSITION
		move.W	#$80+160+140,RBar			;player1'S X START POSITION
		move.B 	#1,BallD					;BallD starting value
		move.W	#2,BallXM
		move.B	#1,BallYD
		move.w	#2,ballYM
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
		move.w 	BallXM,d5
		move.w 	ballym,d0	
	
		;right paddle
		cmp.b	#$2,D5
		beq.s	@rightpaddle				;goto right paddle hit decetion code
		
		;left paddle offset (makes it so it hits the start of the paddle instead of the start of the spite)

		move.w 	player1X,d1					;put player1X in to d1
		add.b	#8,D1						;adds 8 to D1 (player1X)

		cmp.b 	D1,D3						;if d3 = d1
		beq		@leftloop					;If the ball touches then do the setup left loop
		jmp		@boarder					;goto the boarder code (top and bottom of screen)


@rightpaddle:									
		move.w 	player2X,d1					;put player2X in to D1
		sub.b	#8,D1						;subs 8 from player2x (d1) - does this so that we hit the front of player 2

		cmp.b 	D1,D3						;If D1(player2X) = D3(BallX)
		beq		@rightloop					;If the ball touches then do the setup loop
		jmp		@boarder					;If not then skip this and go to boarder hit code	

@leftloop:
		move.w	player1Y,d1					;puts player2Y in to D1 (removes Player2X from there)		
		bra.s	@setuploop

@rightloop:	
		move.w	player2Y,d1					;puts player2Y in to D1 (removes Player2X from there)	

@setuploop:	
		sub.b 	#$06,d1						;adds 6 to the size of the paddle (makes the entire ball hitable)
		move.w 	#$1d-1, d2					;puts zero in to index (d2)

;@Hitloop:									;This is set up like a for loop
;		cmp.b d2, d1						;compaire index counter (d2) to player Y (d1)
;		cmp.b d1,d4							;compaire player Y (d1) to ball y (d4) (if we find a mach then jump to hit code)
;		beq @Hit
;		cmp.b #$1e,d2						;if we do not find match in paddle lenth then do the top and bottom scans
;		beq @miss
;		add.b #$01,d2						;add 1 to index counter (d2)
;		add.b #$01,d1						;adds 1 to player y so we can compair the entire paddel to the balls point of hit
;		;sub.w #$1,d0						;takes 4 off Y momentium (runs in to negatives at some point)
;		bra.s @Hitloop						;restarts loop

@Hitloop:									;This is set up like a for loop
		cmp.b 	d1,d4							;compaire player Y (d1) to ball y (d4) (if we find a mach then jump to hit code)
		beq 	@Hit
											;removes 1 from what will be our y
		add.b 	#$01,d1						;adds 1 to player y so we can compair the entire paddel to the balls point of hit
		dbra 	d2,@Hitloop					;restarts loop

@boarder:									;top and bottom boarder tbar = top boarder, bbar = bottom boarder
		move.W	Tbar, d1
		cmp.w	d1,d4						;if ball X is hitting top boarder
		beq.s	@BHit
		move.W	Bbar,d1
		cmp.w	d1,d4						;if ball X is hitting bottom boarder
		beq.s	@BHit
		bra.s	@sideboarder
@BHit:	
		neg.w	d0							;flip Y momentium (stored in D0)

@sideboarder:
		move.w  LBar,d1						
		cmp.w	d1,D3						;if ball X is hitting left boarder
		beq.s	@miss						;reset game and increase score
		move.w  RBar,d1						
		cmp.w	d1,D3						;if ball X is hitting right boarder
		beq.W	@miss						;reset game and increase score
		bra.s	@Ball_code
@miss:										;reset positions to start
		move.W	#$80+160-130,player1X		
		move.W	#$80+112-13,player1Y		
		move.W	#$80+160+130,player2X		
		move.W	#$80+112-13,player2Y		
		move.W	#$80+80+80,BallX			;center of screen		
		move.W	#$80+112-13,BallY			;center of screen (or around about)
		BRA	MAIN							;jump back to start
		

@hit:										;for if the ball hits a paddle
		neg.w 	d5							;flip X momentium (stored in D5)

;Ball movement code
@Ball_code:	
		add.w 	d0,BallY
		move.w	d0,ballym
		add.w 	d5,BallX
		move.w 	d5,BallXM

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
		move.L	#$7C000003,(A2)
		move.L	PLAYX,(A1)					;THIS TELLS THE VDP (VISUAL DISPLAY PROCESSOR) WHAT X POSITION THE PLAYFIELDS SHOULD BE AT

;SET VERTICAL OFFSETS
		move.L	#$40000010,(A2)				;THIS TELLS THE VDP WHAT Y POSITION THE PLAYFIELDS SHOULD BE AT
		move.L	PLAYY,(A1)

;COPY SPRITE TABLE TO VRAM
		JSR	SPRITEDUMP
;READ JOYPAD
		BSR	READJOY							;READ THE JOYPAD

		RTS

;----------------------------------------------------------
;tilemaps
;----------------------------------------------------------
tilemap1:	DC.W	$0001
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
		DC.B	$04,$44,$44,$40
		DC.B	$00,$00,$00,$00
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
tileset1:

		DC.B	$00,$44,$44,$00				;1 - line down
		DC.B	$00,$44,$44,$00
		DC.B	$00,$44,$44,$00
		DC.B	$00,$44,$44,$00
		DC.B	$00,$44,$44,$00
		DC.B	$00,$44,$44,$00
		DC.B	$00,$44,$44,$00
		DC.B	$00,$44,$44,$00
;----------------------------------------------------------
score-0:
		DC.B	$00,$00,$00,$00				;1
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;2
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
	
		DC.B	$00,$00,$00,$00				;3
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;4
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

score-1:
		DC.B	$00,$00,$00,$11				;1
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11

		DC.B	$00,$00,$00,$11				;2
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
		DC.B	$00,$00,$00,$11
	
		DC.B	$11,$00,$00,$00				;3
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00

		DC.B	$11,$00,$00,$00				;4
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00
		DC.B	$11,$00,$00,$00

score-2:
		DC.B	$00,$00,$00,$00				;1
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;2
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
	
		DC.B	$00,$00,$00,$00				;3
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;4
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

score-3:
		DC.B	$00,$00,$00,$00				;1
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;2
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
	
		DC.B	$00,$00,$00,$00				;3
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;4
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

score-4:
		DC.B	$00,$00,$00,$00				;1
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;2
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
	
		DC.B	$00,$00,$00,$00				;3
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;4
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

score-5:
		DC.B	$00,$00,$00,$00				;1
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;2
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
	
		DC.B	$00,$00,$00,$00				;3
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;4
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

score-6:
		DC.B	$00,$00,$00,$00				;1
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;2
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
	
		DC.B	$00,$00,$00,$00				;3
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;4
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

score-7:
		DC.B	$44,$44,$44,$44				;1
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00

		DC.B	$00,$00,$00,$00				;2
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$00
		DC.B	$00,$00,$00,$04
		DC.B	$00,$00,$00,$04
	
		DC.B	$44,$44,$44,$44				;3
		DC.B	$00,$00,$00,$44
		DC.B	$00,$00,$04,$40
		DC.B	$00,$00,$04,$40
		DC.B	$00,$00,$44,$00
		DC.B	$00,$00,$44,$00
		DC.B	$00,$04,$40,$00
		DC.B	$00,$04,$40,$00

		DC.B	$00,$44,$00,$00				;4
		DC.B	$00,$44,$00,$00
		DC.B	$04,$40,$00,$00
		DC.B	$04,$40,$00,$00
		DC.B	$44,$00,$00,$00
		DC.B	$44,$00,$00,$00
		DC.B	$40,$00,$00,$00
		DC.B	$40,$00,$00,$00

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

