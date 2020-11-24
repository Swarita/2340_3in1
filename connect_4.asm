.data
	gamespace: .byte 0:18 # 6x3 game space
	welcomeprompt: .asciiz "3 in a Line: A MIPS version. Enter a column number (1, 2, or 3) to get started. \n"
	humanprompt: .asciiz "It's your turn: "
	cpuprompt: .asciiz "It's the computer's turn. The computer played: "
	humanwintext: .asciiz "You've beaten the computer. Congrats! \n"
	cpuwintext: .asciiz "You've lost to the computer. Tough luck. \n"
	tietext: .asciiz "The game is tied. \n"
	invalidinput: .asciiz "Input must be an integer between 1 and 3, inclusive: \n"
	full: .asciiz "The column you chose is full. Choose a different column: \n"
	separate: .asciiz " | "
	newline: .asciiz "\n"
	
.text
	la $a0, welcomeprompt		#print opening statement and gamespace
	li $v0, 4
	syscall
	jal display
	
	turns:
		human:
			la $a0, humanprompt		#prompt for input
			li $v0, 4
			syscall
			li $v0, 5			#read in input
			syscall
			la $a0, 1			#pass player num as argument then check for validity
			jal storeturn			#store play if valid
			jal display			#print the gamespace
			jal checkforwin			#check for a win
	
		computer:
			la $a0, cpuprompt		#alert that it's the computer's turn
			li $v0, 4
			syscall
			li $a1, 3			#randomly generate number between 1-3
			li $v0, 42
			syscall
			add $a0, $a0, 1
			li $v0, 1			#print the number
			syscall
			move $t0, $a0
			la $a0, newline
			li $v0, 4
			syscall
			move $v0, $t0			#pass play and player num as arguments
			la $a0, 2
			jal storeturn
			jal display
			jal checkforwin
	
	j turns					#begin next turns after both players play


# storeturn subroutine, takes input in v0 and player num in a0
storeturn:
	addiu $v0, $v0, -4		#checks if input is within bounds, error if not
	bltu $v0 -3, invalidinputerror
	bgtu $v0, -1, invalidinputerror
	
	nextCheck:			
	addiu $v0, $v0, 3		#check next row up
	bgtu $v0, 17, colfull		#if column is full there is an error
	lb $t1, gamespace($v0)
	bnez, $t1, nextCheck		#if row is not empty, check next row
	
	sb $a0, gamespace($v0)		#store play if it made it through checks
	
	jr $ra
	
	invalidinputerror:
	move $t0, $a0
	la $a0, invalidinput
	li $v0, 4
	syscall
	move $a0, $t0
	j getnewinput		#if play is out of bounds, ask for new input
	
	colfull:
		move $t0, $a0
		la $a0, full
		li $v0, 4
		syscall
		move $a0, $t0
	
	getnewinput:			#if play is in a full column, ask for new input
		beq $a0, 1, human
		beq $a0, 2, computer

#display subroutine prints the gamespace out
display:
	addiu $sp, $sp, -8		#save stack
	sw $v0, 4($sp)
	sw $a0, ($sp)

	la $a0, newline
	li $v0, 4
	syscall
	
	li $t0, 17 #loop counter starting from end of gamespaceArray, also val of column 3
	loop:
	sub $t2, $t0, 2			#store column 1 in t2
	sub $t1, $t0, 1			#store column 2 in t1
	lb $a0, gamespace($t2)		#print col 1
	li $v0, 1
	syscall
	la $a0, separate			#print separate
	li $v0, 4
	syscall
	lb $a0, gamespace($t1)		#print col 2
	li $v0, 1
	syscall
	la $a0, separate			#print separate
	li $v0, 4
	syscall
	lb $a0, gamespace($t0)		#print col 3
	li $v0, 1
	syscall
	la $a0, newline			#print new line
	li $v0, 4
	syscall
	sub $t0, $t0, 3			#iterate to next row down
	blt, $t0, 2, endLoop		#if past last row, end loop
	j loop
	
	endLoop:
	lw $a0, ($sp)			#restore stack then jump back
	lw $v0, 4($sp)
	addiu $sp, $sp, 8
	jr $ra
	
#checkforwin subroutine checks for wins on the horizontal, vertical, and RL and LR diagonals. Takes input in v0
checkforwin:
	addiu $sp, $sp, -4		#save stack
	sw $ra, ($sp)
	
	li $t8, 3			#save constant row size
	
	#horizontal
	li $t9, 1 			#num in a line counter, 3 = win
	move $t2, $v0
	move $t4, $v0
	
	checkLeft:
	la $t0, gamespace($t2)
	#if at far left, then start checking right
	div $t2, $t8
	mfhi $t3
	beqz $t3, checkRight
	#else move left
	lb $t1, -1($t0)
	bne $t1, $a0, checkRight
	addiu $t9, $t9, 1
	addiu $t2, $t2, -1
	bgt $t9, 2, PlayerWon
	j checkLeft
	
	checkRight:
	la $t0, gamespace($t4)
	#if at far right, then end
	div $t4, $t8
	mfhi $t3
	beq $t3, 2, horzEnd
	#else check right
	lb $t1, 1($t0)
	bne $t1, $a0, horzEnd
	addiu $t9, $t9, 1
	addiu $t4, $t4, 1
	bgt $t9, 2, PlayerWon
	j checkRight
	
	horzEnd:
	
	#vertical
	li $t9, 1
	move $t2, $v0
	move $t4, $v0
	
	checkTop:
	la $t0, gamespace($t2)
	#if at top, then starting checking below
	bgtu $t2, 14, checkBottom
	#else move above
	lb $t1, 7($t0)
	bne $t1, $a0, checkBottom
	addiu $t9, $t9, 1
	addiu $t2, $t2, 3
	bgt $t9, 2, PlayerWon
	j checkTop
	
	checkBottom:
	la $t0, gamespace($t4)
	#if at bottom, then end
	bltu $t4, 3, vertEnd
	#else check below
	lb $t1, -3($t0)
	bne $t1, $a0, vertEnd
	addiu $t9, $t9, 1
	addiu $t4, $t4, -3
	bgt $t9, 2, PlayerWon
	j checkBottom
	
	vertEnd:
	
	#diagonal from right to left
	li $t9, 1
	move $t2, $v0
	move $t4, $v0
	
	checkTopR:
	la $t0, gamespace($t2)
	#if at top right corner, then start checking bottom right
	bgtu $t2, 14, checkBotL
	div $t2, $t8
	mfhi $t3
	beq $t3, 2, checkBotL
	#else move up one and right one
	lb $t1, 4($t0)
	bne $t1, $a0, checkBotL
	addiu $t9, $t9, 1
	addiu $t2, $t2, 4
	bgt $t9, 2, PlayerWon
	j checkTopR
	
	checkBotL:
	la $t0, gamespace($t4)
	#if at bottom left corner, then end
	bltu $t4, 3, diagRLEnd
	div $t4, $t8
	mfhi $t3
	beq $t3, 0, diagRLEnd
	#else check down one and left one
	lb $t1, -4($t0)
	bne $t1, $a0, diagRLEnd
	addiu $t9, $t9, 1
	addiu $t4, $t4, -4
	bgt $t9, 2, PlayerWon
	j checkBotL
	
	diagRLEnd:
	
	#diagonal from left to right
	li $t9, 1
	move $t2, $v0
	move $t4, $v0
	
	checkTopL:
	la $t0, gamespace($t2)
	#if at top left corner, then start checking bottom right
	bgtu $t2, 14, checkBotR
	div $t2, $t8
	mfhi $t3
	beq $t3, 0, checkBotR
	#else look above one and left one
	lb $t1, 2($t0)
	bne $t1, $a0, checkBotR
	addiu $t9, $t9, 1
	addiu $t2, $t2, 2
	bgt $t9, 2, PlayerWon
	j checkTopL
	
	checkBotR:
	la $t0, gamespace($t4)
	#if at bottom right corner, then end
	bltu $t4, 3, diagLREnd
	div $t4, $t8
	mfhi $t3
	beq $t3, 2, diagLREnd
	#else look below one and right one
	lb $t1, -2($t0)
	bne $t1, $a0, diagLREnd
	addiu $t9, $t9, 1
	addiu $t4, $t4, -2
	bgt $t9, 2, PlayerWon
	j checkBotR
	
	diagLREnd:
	
	#tie
	li $t9, 15
	la $t0, gamespace($t9)
	li $t2, 0
	
	checkFilled:
	lb $t1, ($t0)
	beqz $t1, tieEnd
	addi $t0, $t0, 1
	add $t2, $t2, 1
	beq $t2, 3, GameTie
	j checkFilled
	
	tieEnd:
	
	lw $ra, ($sp)			#restore stack then return to turns
	addiu $sp, $sp, 4
	jr $ra
	
#Three end game possibilities, a tie, human wins, or computer wins
	
GameTie:
	la $a0, tietext
	li $v0, 4
	syscall
	j End
	
PlayerWon:
	beq $a0, 1, player1Win
	
	#computer won
	la $a0, cpuwintext
	li $v0, 4
	syscall
	j End
	
	player1Win:
	la $a0, humanwintext
	li $v0, 4
	syscall
	
End:
	li $v0, 10
	syscall
