;----------------------------------------------------------
;		pong revolution ver0.7(23:51 16/10/2021) 
;		BY Joe (FLC1 - in newer system file)
;----------------------------------------------------------
		INCLUDE	SYSTEM.S		;INCLUDES LOTS OF SYSTEM code TO MAKE ALL THIS POSSIBLE (hopefully replase later) By Jon Burton (GameHut)
;Please read:

;This version of pong revolution is using the old hit trajectory system, its a very basic system
;but will provide a nice prof of concept as well as learning for BGE and BLE

;This 0.7 will be produced before mainline 0.7, will include the new ball engine :) allowing the ball
;to go at speed 2, perhaps even speed 4, will set a counter for that

;verson 0.8 will hopefully have the new system file made by me

;anyway enjoy


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
		move.W	#$80+160-140,LBar			;player1'S X START POSITION
		move.W	#$80+160+140,RBar			;player1'S X START POSITION
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
		move.w	ballXM,d5
		;right paddle
		cmp		#$2,D5
		bpl.s	@rightpaddle				;goto right paddle hit decetion code
		;left paddle offset (makes it so it hits the start of the paddle instead of the start of the spite)
		move.w 	player1X,d1					;put player1X in to d1
		add.b	#8,D1						;adds 8 to D1 (player1X)

		cmp.b 	D1,D3						;if d3 = d1
		beq		@rightloop					;If the ball touches then do the setup loop
		jmp		@boarder					;goto the boarder code (top and bottom of screen)


@rightpaddle:									
		move.w 	player2X,d1					;put player2X in to D1
		sub.b	#8,D1						;subs 8 from player2x (d1) - does this so that we hit the front of player 2

		cmp.b 	D1,D3						;If D1(player2X) = D3(BallX)
		beq		@leftloop					;If the ball touches then do the setup loop
		jmp		@boarder					;If not then skip this and go to boarder hit code	

@rightloop:									;right paddle 
		move.w 	player2y,d1
		bra 	@highhit					

@leftloop:									;left paddle
		move.w 	player1y,d1

;Note, they scan downwards, so anything above them is considered part of them
;1	-highhit		+2
;2
;3
;4	
;5	
;6	-midhigh		+2
;7
;8
;9	
;10	

;1
;2	-lowhigh		+1
;3
;4
;5
;6
;7	-middle		0
;8	
;9	

;1
;2
;3
;4	-highlow		-1
;5
;6
;7	
;8	
;9
;10	-lowhit		-2

@highhit:									;this is the top of the paddle, if its above this its a miss
		add.w	#3,d4						;center the ball
		add.w	#3,d1						;top of the paddle (with centered ball)
		cmp.w	d4,d1
		bge.s	@boarder					;if the ball is higher the the top of the paddle					
		ble.s	@midhigh					;if the ball is lower then hte top of the paddle
		move.b	#2,d0						;give the ball a Y momentuim of 2		
		bra.w	@hit 

@midhigh:
		sub.w 	#5,d1
		cmp.w	d4,d1
		ble.s	@lowhigh
		move.w	#2,D0						;give the ball a Y momentuim of 1
		bra.w	@hit

 
@lowhigh:
		sub.w 	#6,d1
		cmp.w	d4,d1
		ble.s	@middle
		move.w	#1,D0						;give the ball a Y momentuim of 1
		bra.w	@hit



@middle:
		sub.w 	#5,d1
		cmp.w	d4,d1
		ble.s	@highlow
		move.w	#0,D0						;give the ball a Y momentuim of 1
		bra.w	@hit


@highlow:
		sub.w 	#6,d1
		cmp.w	d4,d1
		ble.s	@lowhit
		move.w	#1,D0						;give the ball a Y momentuim of 1
		bra.w	@hit

@lowhit:
		sub.w 	#5,d1
		cmp.w	d4,d1
		ble.s	@boarder
		move.w	#2,D0						;give the ball a Y momentuim of 1
		bra.W	@hit

@boarder:
		move.w	ballYM,d0

		move.W	Tbar, d1
		cmp.w	d1,d4
		beq		@BHit
		move.W	Bbar,d1
		cmp.w	d1,d4
		beq		@BHit
		bra		@sideboarder
@BHit:	
		neg.w	d0							;flip Y movement

@sideboarder:
		move.w  LBar,d1
		cmp.w	d1,D3
		beq.W	@miss
		move.w  RBar,d1
		cmp.w	d1,D3
		beq.W	@miss
		bra		@Ball_code
@miss:
		move.W	#$80+160-130,player1X		;player1'S X START POSITION
		move.W	#$80+112-13,player1Y		;player1'S Y START POSITION
		move.W	#$80+160+130,player2X		;player2'S X START POSITION
		move.W	#$80+112-13,player2Y		;player2'S Y START POSITION
		move.W	#$80+80+80,BallX			;ball X START POSITION
		move.W	#$80+112-13,BallY			;ball Y START POSITION
		move.W	#1,BallXM
		move.w	#1,ballYM
		BRA	MAIN
		

@hit:	
		neg 	d5

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

