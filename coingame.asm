#################################################################
# Author:	Eren Ugur					                                    #
# Date:		April 29, 2024					                              #
# Description:	Catching Coins Game				                      #
#								                                                #
#	     	Bitmap Display Settings				                          #
#	- Unit Width in Pixels: 8				                              #
#	- Unit Height in Pixels: 8				                            #
#	- Display Width in Pixels: 512				                        #
#	- Display Height in Pixels: 256				                        #
#	- Base address for display: 0x10010000 (static data)	        #
#################################################################

.data
displaySize:	.space	8192			# This reserves 8192 bytes in memory for the frame buffer (area of memory used for storing pixels).
						# The size, 8192, corresponds to a bitmap of 64 pixels wide by 32 pixels high, with each pixel being
						# represented by 4 bytes. The base address of displaySize is 0x10010000.

playerColor:	.word	0x00000000		# Color of the player
currentTime:	.word	0			# Current time in milliseconds
player_X:	.word	0			# X position of player (initially 0)
coin1_Y:	.word	0			# Y position of coin 1
coin1_X:	.word	60			# X position of coin 1
q_ASCII:	.word	113			# The ASCII decimal value of the letter q (when 'q' is entered as input, the game stops)
userInput:	.word	0			# User input gets stored in here
coinsCollected:	.word	0			# The amount of times the player collected a coin (initially 0)
coinCollectMsg: .asciiz	"Coins Collected: "	# Message that is printed to the console to show how many coins the player has collected
newline:	.byte	'\n'			# Newline character
pixelsArray:	.word	6272, 6276, 6520, 6528, 6532, 6540, 6776, 6780, 6784, 6788, 6792, 6796, 7040, 7044, 7292, 7304, 7548, 7560	# pixelsArray is an array that contains the pixel locations which make up the player's sprite
gameOverPixels:	.word	3188, 3212, 3448, 3464, 3708, 3716, 3968, 4220, 4228, 4472, 4488, 4724, 4748	# gameOverPixels is an array that contains the pixel locations which make up the "X" that appears when the player loses

.text
#---- Main Function ----#
main:	
	#---- Draw blue background ----#
	addi	$t0, $zero, 0x0073FBFF	# $t0 = blue
	la	$t1, displaySize	# $t1 = displaySize's base address (0x10010000)
	addi	$t2, $zero, 1920	# $t2 = the number of times Loop_1 will loop
	
	Loop_1:	sw	$t0, 0($t1)	# Stores $t0's value (the color blue) into the address held by $t1
		addi	$t1, $t1, 4	# Increments the address by 4
		addi	$t2, $t2, -1	# Decrements the loop counter by 1
		bnez	$t2, Loop_1	# bnez = "Branch if Not Equal to Zero"
		
	#---- Draw gray ground ----#
	addi	$t0, $zero, 0x006E6E6E	# $t0 = gray
	la	$t1, displaySize	# $t1 = 0x10010000
	addi	$t1, $t1, 7680		# $t1 = 0x10010000 + 7680 = 0x10017680
	addi	$t2, $zero, 128		# $t2 = the number of times Loop_2 will loop
	
	Loop_2:	sw	$t0, 0($t1)
		addi	$t1, $t1, 4	
		addi	$t2, $t2, -1	
		bnez	$t2, Loop_2	

	#---- Store the current time in global variable currentTime ----# 
	addi	$v0, $zero, 30		# Syscall for current time
	syscall
	add	$t0, $zero, $a0
	sw	$t0, currentTime
	
	#---- Game Loop ----#
	jal 	drawPlayerLeft		# Draws player's initial position
	jal 	printCoinsCollected	# Prints to console "Coins Collected: 0"
	
	gameLoop:	lw	$t0, q_ASCII
			lw	$t3, userInput
			beq	$t3, $t0, endProgram
			jal	rainCoins
			jal 	movePlayer
			jal 	checkIfCoin1Touched
			j 	gameLoop
	
	endProgram:	li 	$v0, 10		# Sets up exit syscall
			syscall
	

#---- FUNCTIONS ----#
drawBlueLeft:
	add	$t2, $t2, $t0	# $t2 = pixel location + 0x10010000
	add	$t2, $t2, $t4	# $t2 = pixel location + 0x10010000 + x location of player
	addi	$t2, $t2, 4	# $t2 = pixel location + 0x10010000 + x location of player + 4
	sw	$t1, 0($t2)	# Draws blue pixel at address value $t2
	
	jr	$ra
	
drawBlueRight:
	add	$t2, $t2, $t0	# $t2 = pixel location + 0x10010000
	add	$t2, $t2, $t4	# $t2 = pixel location + 0x10010000 + x location of player
	addi	$t2, $t2, -4	# $t2 = pixel location + 0x10010000 + x location of player + 4
	sw	$t1, 0($t2)	# Draws blue pixel at address value $t2
	
	jr	$ra

drawBlackPixel:
	add	$t2, $t2, $t0	# $t2 = pixel location + 0x10010000
	add	$t2, $t2, $t4	# $t2 = pixel location + 0x10010000 + x location of player
	sw	$t1, 0($t2)	# Draws black pixel at address value $t2
	
	jr	$ra

drawPlayerLeft:
	addiu 	$sp, $sp, -8	# 8 bytes are allocated for the stack
	sw 	$ra, 4($sp)	# $ra gets stored in the stack
	
	la	$t0, displaySize	# $t0 = displaySize's base address (0x10010000)
	addi	$t1, $zero, 0x0073FBFF	# $t1 = blue
	lw	$t4, player_X		# $t4 = X position of player
	addi	$t5, $zero, 18		# $t5 = the number of times Loop_3 will loop
	la	$t6, pixelsArray	# $t6 = base address of pixelsArray
	
	Loop_3:	lw	$t2, 0($t6)	
		jal	drawBlueLeft
		addi	$t6, $t6, 4	# Increments the address by 4
		addi	$t5, $t5, -1	# Decrements the loop counter by 1
		bnez	$t5, Loop_3	# bnez = "Branch if Not Equal to Zero"
		
	lw	$t1, playerColor	# $t1 = black
	addi	$t5, $zero, 18		# $t5 = the number of times Loop_4 will loop
	la	$t6, pixelsArray	# $t6 = base address of pixelsArray
	
	Loop_4:	lw	$t2, 0($t6)	
		jal	drawBlackPixel
		addi	$t6, $t6, 4	# Increments the address by 4
		addi	$t5, $t5, -1	# Decrements the loop counter by 1
		bnez	$t5, Loop_4	# bnez = "Branch if Not Equal to Zero"
		
	lw 	$ra, 4($sp)	# The $ra that was stored in the stack gets returned 
	addiu 	$sp, $sp, 8	# Stack gets restored
	jr 	$ra	
		
drawPlayerRight:
	addiu 	$sp, $sp, -8	# 8 bytes are allocated for the stack
	sw 	$ra, 4($sp)	# $ra gets stored in the stack
	
	la	$t0, displaySize	# $t0 = displaySize's base address (0x10010000)
	addi	$t1, $zero, 0x0073FBFF	# $t1 = blue
	lw	$t4, player_X		# $t4 = X position of player
	addi	$t5, $zero, 18		# $t5 = the number of times Loop_3 will loop
	la	$t6, pixelsArray	# $t6 = base address of pixelsArray
		
	Loop_5:	lw	$t2, 0($t6)	
		jal	drawBlueRight
		addi	$t6, $t6, 4	# Increments the address by 4
		addi	$t5, $t5, -1	# Decrements the loop counter by 1
		bnez	$t5, Loop_5	# bnez = "Branch if Not Equal to Zero"
		
	lw	$t1, playerColor	# $t1 = black
	addi	$t5, $zero, 18		# $t5 = the number of times Loop_4 will loop
	la	$t6, pixelsArray	# $t6 = base address of pixelsArray
	
	Loop_6:	lw	$t2, 0($t6)	
		jal	drawBlackPixel
		addi	$t6, $t6, 4	# Increments the address by 4
		addi	$t5, $t5, -1	# Decrements the loop counter by 1
		bnez	$t5, Loop_6	# bnez = "Branch if Not Equal to Zero"
		
	lw 	$ra, 4($sp)	# The $ra that was stored in the stack gets returned
	addiu 	$sp, $sp, 8	# Stack gets restored
	jr 	$ra
		
movePlayer:	
	addiu 	$sp, $sp, -8	# 8 bytes are allocated for the stack
	sw 	$ra, 4($sp)	# $ra gets stored in the stack

	#---- Checks for input ----#
	li	$t0, 0xffff0000		# $t0 = 0xffff0000, the address of the keyboard STATUS register
	lw	$t2, 0($t0)		# $t2 = the value at address 0xffff0000
	andi	$t2, $t2, 1		# Checks if the least significant bit is 1 (aka if input is available)
	beqz	$t2, finishMove		# If not, branch to finishMove
	#--------------------------#

	lw 	$t3, 0xffff0004		# $t3 = input from keyboard
	sw	$t3, userInput

	#---- In the following code, registers $t5 and $t6 are used to prevent user from breaking out of the map ----#
	lw	$t4, player_X
	lw	$t0, playerColor	# $t0 = black
	la	$t7, displaySize	# $t7 = 0x10010000
	addi	$t1, $t7, 6656		# $t1 = 0x10010000 + 6656
	addi	$t2, $t7, 6908		# $t2 = 0x10010000 + 6908
	lw	$t5, 0($t1)		# $t5 = hex color of pixel 1665
	lw	$t6, 0($t2)		# $t6 = hex color of pixel 1728
		
	beq	$t3, 100, moveRight	# if input is 'd', branch to moveRight
	beq	$t3, 97, moveLeft	# else if input is 'a', branch to moveLeft
	j	finishMove		# else, skip
		
	moveRight:	beq	$t0, $t6, finishMove	# If hex color of pixel 1728 is black, branch to finishMove
			addi	$t4, $t4, 4
			sw	$t4, player_X
			jal 	drawPlayerRight
			j	finishMove
				
	moveLeft:	beq	$t0, $t5, finishMove	# If hex color of pixel 1665 is black, branch to finishMove
			addi	$t4, $t4, -4
			sw	$t4, player_X
			jal 	drawPlayerLeft
		
	finishMove:	lw 	$ra, 4($sp)	# The $ra that was stored in the stack gets returned
			addiu 	$sp, $sp, 8	# Stack gets restored
			jr 	$ra

LFSR_0_to_63:
	lw	$t0, coin1_X
	srl	$t1, $t0, 1	# $t1 = n >> 1 (corresponds to tap at 4th bit)
	srl	$t2, $t0, 0	# $t2 = n >> 0 (corresponds to tap at 5th bit)
		
	xor	$t3, $t1, $t2	# bit = (n >> 1) ^ (n >> 0)
		
		
	addi	$t4, $zero, 1	#
	and	$t3, $t3, $t4	# bit = ((n >> 1) ^ (n >> 0)) & 1
		
	srl	$t1, $t0, 1	# $t1 = n >> 1
	sll	$t2, $t3, 5	# $t2 = bit << 5
				#
	or	$t3, $t1, $t2	# psuedoRandVal = (n >> 1) | (bit << 5)
	sw	$t3, coin1_X
		
	jr	$ra
	

rainCoins:	
	addiu 	$sp, $sp, -8	# 8 bytes are allocated for the stack
	sw 	$ra, 4($sp)	# $ra gets stored in the stack

	lw	$t0, currentTime	# $t0 = currentTime
	lw	$t1, coin1_Y		# $t1 = coin1_Y

	addi	$v0, $zero, 30		# Syscall for current time
	syscall
	add	$t2, $zero, $a0		# The current time gets stored in $t2
		
	sub	$t3, $t2, $t0		# $t3 = $t2 - $t0
	addi	$t4, $zero, 100		# $t0 = 100
	blt	$t3, $t4, finishRain	# if $t3 < 100, branch to finishRain
		
	addi	$t2, $zero, 7424		# $t2 = 7424
	bgt	$t2, $t1, skipGameOver	# if 7424 > (y location of coin1), do not reset coin1's height
		
	#---- Coin1 Reset ----#
	
	jal gameOverFunc
	
	# jal	drawCoin1Reset		#
	# addi	$t1, $zero, 0		# The code that was commented out can be used to replace "jal gameOverFunc"
	# sw	$t1, coin1_Y		# so that the game does not end when a coin touches the ground.
	# jal	LFSR_0_to_63		#
	
	#---------------------#
		
	skipGameOver:
	
	jal	drawCoin1		# Coin 1 moves down by 1 pixel OR is reset back to the top of the screen
	
	lw	$t1, coin1_Y		#
	addi	$t1, $t1, 256		# coin1_Y = coin1_Y + 256
	sw	$t1, coin1_Y		#
		
	addi	$v0, $zero, 30		# Syscall for current time
	syscall
	add	$t0, $zero, $a0		# The current time gets stored in $t0
	sw	$t0, currentTime
		
	finishRain:	lw 	$ra, 4($sp)	# The $ra that was stored in the stack gets returned
			addiu 	$sp, $sp, 8	# Stack gets restored
			jr 	$ra

drawCoin1:	
	la	$t0, displaySize	# Loads displaySize's base address into $t0
	lw	$t4, coin1_Y
	lw	$t5, coin1_X
	addi	$t6, $zero, 4
	mul	$t5, $t5, $t6
		
	addi	$t1, $zero, 0x00E3CA4A	# $t1 = shade of yellow
	addi	$t2, $zero, 0		# $t2 = 0
	add	$t2, $t2, $t0		# $t2 = 0 + 0x10010000
	add	$t2, $t2, $t4		# $t2 = 0x10010000 + coin1_Y
	add	$t2, $t2, $t5		# $t2 = 0x10010000 + coin1_Y + coin1_X
	sw	$t1, 0($t2)		# Address "0x10010000 + coin1_Y + coin1_X" gets painted with yellow
		
	sub	$t3, $t2, $t0		# $t3 = (0x10010000 + coin1_Y + coin1_X) - 0x10010000 = coin1_Y + coin1_X
	addi	$t1, $zero, 256		# $t1 = 256
	blt	$t3, $t1, skip1		# If (coin1_Y + coin1_X) < 256, AKA when the coin is at the very top of the screen, branch to skip1.
					# 	(this skips the following block of code, which makes the pixel above the new yellow pixel the color blue

	addi	$t1, $zero, 0x0073FBFF	# $t1 = blue
	sub	$t3, $t3, 256		# $t3 = (coin1_Y + coin1_X) - 256 
	add	$t3, $t3, $t0		# $t3 = (coin1_Y + coin1_X) - 256 + 0x10010000
	sw	$t1, 0($t3)		# address held by $t3 gets painted with blue

	skip1:
		
	addi	$t1, $zero, 0x00E3CA4A	# $t1 = 0x00E3CA4A
	addi	$t2, $zero, 4		# $t2 = 4
	add	$t2, $t2, $t0		# $t2 = 4 + 0x10010000
	add	$t2, $t2, $t4		# $t2 = 0x10010004 + coin1_Y
	add	$t2, $t2, $t5		# $t2 = 0x10010004 + coin1_Y + coin1_X
	sw	$t1, 0($t2)		# Address "0x10010004 + coin1_Y + coin1_X" gets painted with yellow
		
	sub	$t3, $t2, $t0		# 
	addi	$t1, $zero, 256		#
	blt	$t3, $t1, skip2		#
					#
	addi	$t1, $zero, 0x0073FBFF	#   Replaces Coin1's previous position with blue
	sub	$t3, $t3, 256		#	(this is essentially what the code at lines 284-292 does as well)
	add	$t3, $t3, $t0		#
	sw	$t1, 0($t3)		#
					#
	skip2:				#
		
	addi	$t1, $zero, 0x00E3CA4A	# $t1 = 0x00E3CA4A
	addi	$t2, $zero, 256		# $t2 = 256
	add	$t2, $t2, $t0		# $t2 = 256 + 0x10010000
	add	$t2, $t2, $t4		# $t2 = 0x10010256 + coin1_Y
	add	$t2, $t2, $t5		# $t2 = 0x10010256 + coin1_Y + coin1_X
	sw	$t1, 0($t2)		# Address "0x10010256 + coin1_Y + coin1_X" gets painted with yellow
		
	addi	$t1, $zero, 0x00E3CA4A	# $t1 = 0x00E3CA4A
	addi	$t2, $zero, 260		# $t2 = 260
	add	$t2, $t2, $t0		# $t2 = 260 + 0x10010000
	add	$t2, $t2, $t4		# $t2 = 0x10010260 + coin1_Y
	add	$t2, $t2, $t5		# $t2 = 0x10010260 + coin1_Y + coin1_X
	sw	$t1, 0($t2)		# Address "0x10010260 + coin1_Y + coin1_X" gets painted with yellow
		
	jr 	$ra
	
checkIfCoin1Touched:
	addiu 	$sp, $sp, -8	# 8 bytes are allocated for the stack
	sw 	$ra, 4($sp)	# $ra gets stored in the stack

	addi	$t8, $zero, 18		# $t5 = the number of times Loop_7 will loop
	la	$t9, pixelsArray	# $t6 = base address of pixelsArray
		
	Loop_7:	la	$t0, displaySize	# $t0 = displaySize's base address (0x10010000)
		li	$t3, 0x00E3CA4A		# $t3 = yellow
		lw	$t4, player_X		# $t4 = X position of player
	
		lw	$t2, 0($t9)	# $t2 = pixel location (e.g., 6272)
		add	$t2, $t2, $t0	# $t2 = pixel location + 0x10010000
		add	$t2, $t2, $t4	# $t2 = pixel location + 0x10010000 + x location of player
		lw	$t1, 0($t2)
		bne 	$t1, $t3, coin1NotTouched
		
		lw	$t3, coinsCollected
		addi	$t3, $t3, 1
		sw	$t3, coinsCollected
		jal	printCoinsCollected
		
		jal	drawCoin1Reset
		lw	$t7, coin1_Y
		addi	$t7, $zero, 0		# Resets coin1's height
		sw	$t7, coin1_Y
		jal	LFSR_0_to_63
		
		la	$t0, displaySize	# $t0 = displaySize's base address (0x10010000)
		lw	$t2, 0($t9)		# $t2 = pixel location (e.g., 6272)
		lw	$t4, player_X		# $t4 = X position of player
		add	$t2, $t2, $t0		# $t2 = pixel location + 0x10010000
		add	$t2, $t2, $t4		# $t2 = pixel location + 0x10010000 + x location of player
		li	$t0, 0x00000000
		sw	$t0, 0($t2)
		
		li	$v0, 31		# Syscall for sound (MIDI)
		li	$a0, 100		# $a0 = pitch
		li	$a1, 1000	# $a1 = time duration of sound (in milliseconds)
		li	$a2, 121	# $a2 = type of sound
		li	$a3, 70		# a3 = volume
		syscall
			
		coin1NotTouched:
		
		addi	$t9, $t9, 4	# Increments the address by 4
		addi	$t8, $t8, -1	# Decrements the loop counter by 1
		bnez	$t8, Loop_7	# bnez = "Branch if Not Equal to Zero"
		
	lw 	$ra, 4($sp)	# The $ra that was stored in the stack gets returned
	addiu 	$sp, $sp, 8	# Stack gets restored
	jr 	$ra
	
	jr 	$ra
	
drawCoin1Reset:
	la	$t0, displaySize	# Loads displaySize's base address into $t0
	lw	$t4, coin1_Y		# $t4 = coin1_Y
	sub	$t4, $t4, 256		# $t4 = coin1_Y - 256
	lw	$t5, coin1_X		# $t5 = coin1_X
	addi	$t6, $zero, 4		# $t6 = 4
	mul	$t5, $t5, $t6		# $t5 = (coin1_X * 4)
		
	addi	$t1, $zero, 0x0073FBFF	# $t1 = shade of yellow
	addi	$t2, $zero, 0		# $t2 = 0
	add	$t2, $t2, $t0		# $t2 = 0 + 0x10010000
	add	$t2, $t2, $t4		# $t2 = 0x10010000 + coin1_Y
	add	$t2, $t2, $t5		# $t2 = 0x10010000 + coin1_Y + (coin1_X * 4)
	sw	$t1, 0($t2)		# address "0x10010000 + coin1_Y + (coin1_X * 4)" gets painted with yellow
	
	addi	$t1, $zero, 0x0073FBFF	# $t1 = shade of yellow
	addi	$t2, $zero, 4		# $t2 = 4
	add	$t2, $t2, $t0		# $t2 = 4 + 0x10010000
	add	$t2, $t2, $t4		# $t2 = 0x10010004 + coin1_Y
	add	$t2, $t2, $t5		# $t2 = 0x10010004 + coin1_Y + (coin1_X * 4)
	sw	$t1, 0($t2)		# address "0x10010004 + coin1_Y + (coin1_X * 4)" gets painted with yellow
	
	addi	$t1, $zero, 0x0073FBFF	# $t1 = shade of yellow
	addi	$t2, $zero, 256		# $t2 = 256
	add	$t2, $t2, $t0		# $t2 = 256 + 0x10010000
	add	$t2, $t2, $t4		# $t2 = 0x10010256 + coin1_Y
	add	$t2, $t2, $t5		# $t2 = 0x10010256 + coin1_Y + (coin1_X * 4)
	sw	$t1, 0($t2)		# address "0x10010256 + coin1_Y + (coin1_X * 4)" gets painted with yellow
		
	addi	$t1, $zero, 0x0073FBFF	# $t1 = shade of yellow
	addi	$t2, $zero, 260		# $t2 = 260
	add	$t2, $t2, $t0		# $t2 = 260 + 0x10010000
	add	$t2, $t2, $t4		# $t2 = 0x10010260 + coin1_Y
	add	$t2, $t2, $t5		# $t2 = 0x10010260 + coin1_Y + (coin1_X * 4)
	sw	$t1, 0($t2)		# address "0x10010260 + coin1_Y + (coin1_X * 4)" gets painted with yellow
	
	jr	$ra

printCoinsCollected:
	li	$t0, 20	# Number of times Loop_Newline will cycle
	lb	$t1, newline
	lw	$t2, coinsCollected
	
	Loop_Newline: 	li	$v0, 11		# 
			move	$a0, $t1	# Syscall for printing a character (in this case, '\n')
			syscall			#
			
			addi	$t0, $t0, -1		# Decrements the loop counter by 1
			bnez	$t0, Loop_Newline	# bnez = "Branch if Not Equal to Zero"
			
	li $v0, 4		#
	la $a0, coinCollectMsg	# Syscall for printing a string (in this case, "Coins Collected: "
	syscall			#
	
	li $v0, 1		#
	move $a0, $t2		# Syscall for printing an integer (in this case, the number stored in coinsCollected)
	syscall			#
		
	jr	$ra

gameOverFunc:
	la	$t0, displaySize	# $t0 = displaySize's base address (0x10010000)
	addi	$t1, $zero, 0x00ED1C24	# $t1 = red
	addi	$t2, $zero, 13		# Number of times Loop_8 will cycle
	la	$t3, gameOverPixels	# $t3 = base address of gameOverPixels array
	addi	$t8, $zero, 0x00000000	# $t8 = pink
	
	li	$v0, 31		# Syscall for sound (MIDI)
	li	$a0, 30		# $a0 = pitch
	li	$a1, 2000	# $a1 = time duration of sound (in milliseconds)
	li	$a2, 120	# $a2 = type of sound
	li	$a3, 70		# a3 = volume
	syscall
	
	Loop_8:	lw	$t4, 0($t3)	# $t4 = address of one of the elements in the gameOverPixels array
		add	$t4, $t4, $t0	# $t4 = $t4 + 0x10010000
		sw	$t1, 0($t4)	# Paints one of the red pixels that helps form the red game over "X"
		
		addi	$t3, $t3, 4	# Increments the address by 4
		addi	$t2, $t2, -1	# Decrements the loop counter by 1
		
		addi	$t7, $zero, 4		# Number of times Loop_9 will cycle
		Loop_9:	li	$v0, 42		# Syscall for random integer
			li	$a1, 2048	# Upper bound of random integer syscall is 2048
			syscall
			
			add	$t5, $zero, $a0	# $t5 = random integer between 0 and 2048
			li	$t6, 4		# $t6 = 4
			mul	$t5, $t5, $t6	# $t5 = $t5 * 4
			add	$t5, $t5, $t0	# $t5 = $t5 + 0x10010000
			sw	$t8, 0($t5)	# Random pixel on screen gets 
				
			li	$v0, 32		# Syscall for sleep
			li	$a0, 10		# Sleep delay (10 milliseconds)
			syscall
			
			addi	$t7, $t7, -1	# Decrements the loop counter by 1
			bnez	$t7, Loop_9	# bnez = "Branch if Not Equal to Zero"
		
		bnez	$t2, Loop_8	# bnez = "Branch if Not Equal to Zero"
		
	li 	$v0, 10		# Sets up exit syscall
	syscall
	

		
	
	
	
		
				
