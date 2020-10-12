.data

boardArray: .byte 0:42 #This will be the array that represents the gameboard: 0=Empty 1=Player1 2=Player2
prompt0: .asciiz "Welcome to Connect 4!\nThis is a MIPS version of the classic 2 player board game Connect 4.\nThe game will begin with Player 1's turn.\nEnter 1-7 to choose which column to place the game piece in.\nOnce Player 1 goes, Player 2 may then take their turn.\nThe game will automatically alternate user turns so be patient and once you see the game peice placed on the Bitmap it is time for the other player to take their turn!\n\nHave fun!\n\n"
prompt1: .asciiz "\nPlayer 1's turn: "
prompt2: .asciiz "\nPlayer 2's turn: "
prompt3: .asciiz "Player 1 Wins!\n"
prompt4: .asciiz "Player 2 Wins!\n"
prompt5: .asciiz "Please enter a number between 1 and 3 (inclusive)\n"
prompt6: .asciiz "The column you have chosen is full. Select a different column\n"
prompt7: .asciiz "It's a Tie!\n"

.text

#Load Welcome Prompt
la $a0, prompt0
li $v0, 4
syscall

################################  Begin Main ################################
main:

#Get Player 1 Input
playerOne:
la $a0, prompt1
li $v0, 4
syscall
li $v0, 5
syscall

#Place User Input into Array and Error Check
li $a0, 1
jal StoreInput

#Check for Player 1 "Connect 4"
#If found, go to Player 1 win
#If not found, continue game
jal WinCheck

#Get Player 2 Input
playerTwo:
la $a0, prompt2
li $v0, 4
syscall
li $v0, 5
syscall

#Place User Input into Array
li $a0, 2
jal StoreInput

#Check for Player 2 "Connect 4"
#If found, go to Player 2 win
#If not found, go back to Player 1 turn
jal WinCheck

j main #Play next set of turns
################################  End Main ################################

#Procedure: StoreInput
#Input: User entered value - $v0
#Input: Player Number (1 or 2) - $a0
#Output: Box Number ($v0)
#Will determine which exact array location to place user input and store it into array
StoreInput:
addiu $v0, $v0, -8 #Convert user input into Array notation(-1) and subtract for nextCheck Loop(-7)
bltu $v0, -7, OOBError
bgtu $v0, -1, OOBError

#Find out (in the column) where the next available row is
nextCheck:
addiu $v0, $v0, 7 #Increment row
bgtu $v0, 41, ColumnFull#If column is full go to error
lb $t1, boardArray($v0) #Load byte from boardArray that user has chosen
bnez $t1, nextCheck #If loaded byte is NOT EMPTY(1 or 2) then try next row up (add 7 to array index)

#Only reach here if boardArray(base + offset) = 0
sb $a0, boardArray($v0) #Place player number into boardArray at location player's chip will end

jr $ra #Finished Procedure Successfully

#Out of Bounds Error Catching
OOBError:
move $t0, $a0
la $a0, prompt5
li $v0, 4
syscall
move $a0, $t0
j returnToPlayer

#Column Full Error Catching
ColumnFull:
move $t0, $a0
la $a0, prompt6
li $v0, 4
syscall
move $a0, $t0

returnToPlayer:
beq $a0, 1, playerOne
beq $a0, 2, playerTwo

################################  Begin WinCheck ################################
#Procedure: WinCheck
#Input: $a0 - Player Number
#Input: $v0 - Last location offset chip was placed
#Will deterine is the current player's move have triggered a win using DFS
WinCheck:    
      #Must check FOUR different directions a win can happen:
      #1. Horizontal Line
      #2. Vertical Line
      #3. Forward Slash
      #4. Backward Slash
   
      #5. Check for Full Board (Tie)
      addiu $sp, $sp, -4
      sw $ra, ($sp)
     
        li $t8, 7 #Constant 7 used for modulo divison for left-most and right-most checking
         
    #-----------------Check horizontal-----------------#
      #From start, go LEFT as far possible
      li $t9, 1 #Counter - once reaches 4 then player-$a0 wins
move $t2, $v0 #Copy the ORIGINAL offset into $t2 for manipulation when searching LEFT
move $t4, $v0 #Copy the ORIGINAL offset into $t4 for manipulation when searching RIGHT
        checkLeft:
      la $t0, boardArray($t2) #Load our current chip address
     
        #If we are at the leftmost slot, skip to check right
      div $t2, $t8
      mfhi $t3 #The modulo result of offset value % 7
      beqz $t3, checkRight #If result = 0 then go to check right
     
      #Else look at slot to our left
      lb $t1, -1($t0) #Left of current location
      bne $t1, $a0, checkRight #If value is not equal to player number, then proceed to check right
      addiu $t9, $t9, 1 #Else value IS player number, increment counter and check next left
      addiu $t2, $t2, -1
bgt $t9, 3, PlayerWon #If player has more than 3 connected (so 4+), then they won
      j checkLeft
     
      #From start, go RIGHT as far possible
checkRight:
la $t0, boardArray($t4)

#If we are at rightmost slot, end horizontal checking
div $t4, $t8
mfhi $t3
beq $t3, 6, endHorz #If modulo result = 6 then we know we are in rightmost slot

#Else look at slot to our right
lb $t1, 1($t0) #Right of current location
bne $t1, $a0, endHorz #If value is not player number, end checking
addiu $t9, $t9, 1 #Else increment coutner
addiu $t4, $t4, 1 #Move to next value to the right
bgt $t9, 3, PlayerWon #If player has more than 3 connected (so 4+), then they won
j checkRight

endHorz:
#-----------------End Horizontal Check-----------------#

     
      #-----------------Check vertical-----------------#
      #From start, go UP as far possible
      li $t9, 1 #Counter - once reaches 4 then player-$a0 wins
move $t2, $v0 #Copy the ORIGINAL offset into $t2 for manipulation when searching UP
move $t4, $v0 #Copy the ORIGINAL offset into $t4 for manipulation when searching DOWN
        checkUp:
      la $t0, boardArray($t2) #Load our current chip address
     
        #If we are at the top row, skip to checkDown
      bgtu $t2, 34, checkDown #If our offset is greater than 34 that means we are on the top row
     
      #Else look at slot above us
      lb $t1, 7($t0) #Left of current location
      bne $t1, $a0, checkDown #If value is not equal to player number, then proceed to check down
      addiu $t9, $t9, 1 #Else value IS player number, increment counter and check next row up
      addiu $t2, $t2, 7
bgt $t9, 3, PlayerWon #If player has more than 3 connected (so 4+), then they won
      j checkUp
     
      #From start, go DOWN as far possible
checkDown:
la $t0, boardArray($t4)

#If we are at bottom row, end vertical checking
bltu $t4, 7, endVert

#Else look at slot below us
lb $t1, -7($t0) #Below current location
bne $t1, $a0, endVert #If value is not player number, end checking
addiu $t9, $t9, 1 #Else increment coutner
addiu $t4, $t4, -7 #Move to next value below current location
bgt $t9, 3, PlayerWon #If player has more than 3 connected (so 4+), then they won
j checkDown

endVert:  
      #-----------------End Vertical Check-----------------#
     
     
     
     
      #-----------------Check forward-slash diagonal-----------------#
#From start, go UP-RIGHT (UR) as far possible
      li $t9, 1 #Counter - once reaches 4 then player-$a0 wins
move $t2, $v0 #Copy the ORIGINAL offset into $t2 for manipulation when searching UR
move $t4, $v0 #Copy the ORIGINAL offset into $t4 for manipulation when searching DL
        checkUR:
      la $t0, boardArray($t2) #Load our current chip address
     
        #If we are at the top row OR we are at the rightmost coloumn, then skip to down-left
      bgtu $t2, 34, checkDL #If our offset is greater than 34 that means we are on the top row
div $t2, $t8
mfhi $t3
beq $t3, 6, checkDL #If modulo result = 6 then we know we are in rightmost slot
     
      #Else look at slot above us and over to the right
      lb $t1, 8($t0) #UR of current location
      bne $t1, $a0, checkDL #If value is not equal to player number, then proceed to check right
      addiu $t9, $t9, 1 #Else value IS player number, increment counter and check next value in pattern
      addiu $t2, $t2, 8
bgt $t9, 3, PlayerWon #If player has more than 3 connected (so 4+), then they won
      j checkUR
     
      #From start, go DOWN-LEFT (DL) as far possible
checkDL:
la $t0, boardArray($t4)

#If we are at bottom row OR leftmost column, then end FSDiag checking
bltu $t4, 7, endFSDiag #Bottom row test
div $t4, $t8
mfhi $t3
beq $t3, 0, endFSDiag #Leftmost column test

#Else look at slot below us and over to the left one
lb $t1, -8($t0) #DL of current location
bne $t1, $a0, endFSDiag #If value is not player number, end checking
addiu $t9, $t9, 1 #Else increment coutner
addiu $t4, $t4, -8 #Move to next value
bgt $t9, 3, PlayerWon #If player has more than 3 connected (so 4+), then they won
j checkDL

endFSDiag:  
      #-----------------End Forward-Slash Diagonal Check-----------------#
     
     
     
     
      #-----------------Check backward-slash diagonal-----------------#
#From start, go UP-LEFT (UL) as far possible
      li $t9, 1 #Counter - once reaches 4 then player-$a0 wins
move $t2, $v0 #Copy the ORIGINAL offset into $t2 for manipulation when searching UL
move $t4, $v0 #Copy the ORIGINAL offset into $t4 for manipulation when searching DR
        checkUL:
      la $t0, boardArray($t2) #Load our current chip address
     
        #If we are at the top row OR we are at the leftmost coloumn, then skip to down-right
      bgtu $t2, 34, checkDR #Top row test
div $t2, $t8
mfhi $t3
beq $t3, 0, checkDR #Left-most column test
     
      #Else look at slot above us and over to the left
      lb $t1, 6($t0) #Up and Left of current position
      bne $t1, $a0, checkDR #If value is not equal to player number, then proceed to check right
      addiu $t9, $t9, 1 #Else value IS player number, increment counter and check next value in pattern
      addiu $t2, $t2, 6
bgt $t9, 3, PlayerWon #If player has more than 3 connected (so 4+), then they won
      j checkUL
     
      #From start, go DOWN-RIGHT (DR) as far possible
checkDR:
la $t0, boardArray($t4)

#If we are at bottom row OR rightmost column, then end BSDiag checking
bltu $t4, 7, endBSDiag #Bottom row test
div $t4, $t8
mfhi $t3
beq $t3, 6, endBSDiag #Right-most column test

#Else look at slot below us and over to the right one
lb $t1, -6($t0) #BR of current location
bne $t1, $a0, endBSDiag #If value is not player number, end checking
addiu $t9, $t9, 1 #Else increment coutner
addiu $t4, $t4, -6 #Move to next value
bgt $t9, 3, PlayerWon #If player has more than 3 connected (so 4+), then they won
j checkDR

endBSDiag:    
      #-----------------End Backward-Slash Diagonal Check-----------------#
     
      #-----------------Start Full Board Check-----------------#
      li $t9, 35 #Load the offset for the top row of the gameboard
      la $t0, boardArray($t9)
     
      li $t2, 0 #Counter for # of player chips in top row
    checkTop:
    lb $t1, ($t0)
    beqz $t1, endTie #If a blank slot is found then stop checking
    addi $t0, $t0, 1
    add $t2, $t2, 1
    beq $t2, 7, GameTie #If there are 7 chips in top row, it's a tie
    j checkTop
   
    endTie:
      #-----------------End Full Board Check-----------------#

lw $ra, ($sp)
addiu $sp, $sp, 4
jr $ra #Return to game after all checks are made


################################  End WinCheck ################################

#Sub-Procedure: GameTie
#Triggered when the top row of game board is filled and no one is a winner
GameTie:
la $a0, prompt7
li $v0, 4
syscall
li $v0, 10
syscall


#Procedure: PlayerWon
#Input: $a0 - Player Number
#Triggered when a player wins a game
#Will show winner message then exit program
PlayerWon:
beq $a0, 1 player1Win #If player 1 won, jump to second instruction set

#Player 2 Won
la $a0, prompt4
li $v0, 4
syscall
li $v0, 10
syscall

#Player 1 Won
player1Win:
la $a0, prompt3
li $v0, 4
syscall
li $v0, 10
syscall
	
