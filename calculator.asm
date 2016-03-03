#############################################################
# Anthony Poerio (adp59@pitt.edu)                           #
# CS 447 - Fall 2015                                        #
# PROJECT 05 - UPDATED CALCULATOR      	                    #
# Simplified calculator changed to work on simple processer #  
#############################################################

#  Architecture:
#     - Input:   connected to $t9 
#     - Output:  connected to $t8

# Operations Supported:
#     - Addition
#     - Subtraction
#     - Multiplication (both positive and negative numbers)
#     - Division (Only positive numbers)
#     - Clear

.text
##############################
### INITIALIZE AND DISPLAY ###
##############################

# Initalize the calculator here. Beginning of loop read, write, dispay -- loop. 
Init:
	
# Display to the $t8 output line here in this block	
ToScreen:	
	add  $t8, $zero, $s1     # We calculate a value in $s1 in program below, and by adding it to 
	    			 # $t8, we display to the screen
	addi $t9, $zero, 0       # Clearing $t9 input line gets the calculator ready for input
	beq  $s5, 1, NotEqual 
	j    noZeroOut

# Jump here of $s5 != 1			
NotEqual:	
	    # Zero out previous stacked operator, as it's already been used
	addi $t2, $zero, 0  

# Zero out each register	    	    
ZeroOut:
	addi $t9, $zero, 0       # Clear $t9, getting the calculator ready to accept new input, by setting it to 0
	add  $t4, $zero, $t8     # Add value of $t8 to $t4
	addi $s5, $zero, 0       # Zero out $s5 register	
	addi $s1, $zero, 0       # Zero out $s1 register
	addi $t7, $zero, 0       # Zero out $t7 register
	addi $t6, $zero, 0       # Zero out $t6 register
	addi $t5, $zero, 0       # Zero out $t5 register
	addi $t3, $zero, 0       # Zero out $t3 register
	addi $t1, $zero, 0       # Zero out $t1 register

# If we don't zero out, jump to here, ad continue with rest of the program
noZeroOut:
		
######################
### Wait for input ###
######################
wait:		
	beq $t9, $zero, wait         # Wait here until a a number is entered on calculator
				     # $t9 accepts input, so we wait until $t9 != 0 
	add $s1, $zero, $t9          # Store whichever value was pressed on the calculator in $t9
	
#####################
### Accept Input ####
#####################
accept_input:
	# Next two lines clear MSB, which defaults to 1, after being sent from $t9 by shifting 		 
	sll $s1, $s1,1              # Shift our value left by one, removing MSB
	srl $s1, $s1,1              # Shift our value right one, keeping rest of the number intact
	beq $s1, 15, Clear          # Jump to clear if user presses the C button. C = 15, when stored.
			
		
#################################
#####   Route  Function    ######
#################################	
		
Route:	
	# If an operator (10 - 14 on calculator) is pressed, store it in our makeshift "stack"
	beq $s1, 10, PushToStack    # Stores Plus
	beq $s1, 11, PushToStack    # Stores Minus
	beq $s1, 12, PushToStack    # Stores Times
	beq $s1, 13, PushToStack    # Stores Divide
	addi $t0, $zero, 0          # Clear out $t0
	
	
	# If equals prssed
	# Jump to equals, if pressed. Don't store it on stack.
	beq $s1, 14, Equals 
	
	# Display	
	add $t8, $zero, $s1        # Display input value, if not an oeperator (after shifting out MSB)			   
	add $t6, $zero, $t7        # Puts a "base" number in $t6 
				
       # Number builder:  Shift each decimal number left one place
	sll $t7, $t7, 3            # Multiply $t7 by 8 
	
	# Add muliplied number to our base twice
	add $t7, $t7, $t6          
	add $t7, $t7, $t6 
	
	# Now, we'll have a number multiplied by 10, and we can add it to our previous value safely
	add $t7, $t7, $s1  	
	
	# Store our new number in $s1			
	add $s1, $zero, $t7 
	
	# Go back to beginning of Read-Write Loop, check value fo $s1
	j Init 		
	

######################
### PUSH TO STACK ####
###################### 		
PushToStack:	
	beq  $t0, 1, continuePush     # if $t0 = 1, continue push operations
		
        # Check if an operator has already been stored, and use it if so. 
        # Avoids double operators.
        beq  $t2, $zero, Zero
        srl  $s6, $t2, 31
        beq  $s6, 0, StackOperator 
        Zero:
			
continuePush:
	# Value of first operand is in $t8
	# But we need to store it in $t4, so we can perform operations below
	add $t4, $zero, $t8  
	
	
	# Handle operator
	add $t2, $zero, $s1     # Store value of operator in $t2
	beq $t0, 1, ZeroOut  
	
	# Handle operands
	add $s1, $zero, $t4      # Put first operand in $s1; this ensures it will display, when we get back to Init
	
	# Prepare for build
	addi $t7, $zero, 0       # Zero out base number; ensures we can continue building a value, if necessary
	addi $t0, $zero, 1  
	
	# Now we're ready to go back to the loop		
	j Init  
	
	
#################################
###   Mathematical Operators  ###
#################################	
	
		
#//////////////////////
#//////   MINUS  //////
#//////////////////////	
minus:	
	nor  $t3, $t3, $zero	# Nor with zero to flip bitwise
        addi $t3, $t3, 1 	# Add one to flipped number = 2's complement
       	add  $s3, $t4, $t3  	# Add negated number = sub
	
	 # jump to AnswerFound after we calculate		
        j AnswerFound	
	         
#/////////////////////////
#//////   DIVIDE  ////////
#/////////////////////////		         
Divide:		
	add $s3, $zero, 0            # Ensure division counter = 0
		
	# Negate second operand
	nor $t3, $t3, $zero	     # Nor with zero to flip bitwise
	addi $t3, $t3, 1	     # Add one to flipped number = 2's complement
	        

		
SubDivision:	
	# Subtract second operand from first, and increment $s3 + 1 every time we do this succesfully
	# Continue until first operand is <= 0; means division is over	
	add $t4, $t4, $t3            # Subtract 2's comp value 
	beq $t4, $zero, IplusOne     
			
	# Go here if division is over		
	beq $t4, $zero, AnswerFound   # Answer found if $t4 = 0  
	srl $s6, $t4, 31	      
	beq $s6, 1, AnswerFound       
	
			 
IplusOne:
	# Increment counter
        addi $s3, $s3, 1              
	
	# and continue loop!		
	j SubDivision   
	
#//////////////////////
#//////   PLUS  ///////
#//////////////////////

plus:		
	# Plus is simple, we use the add operation from MIPS
	add $s3, $t4, $t3
        j AnswerFound		

#//////////////////////////
#//////   MULTIPLY  ///////
#//////////////////////////		
Multiply:	
	# Clear counter in $s3
	add   $s3, $zero, 0 
	
	# Multiply uses a loop to add the first operand to itself using the second operator as the loop control variable
	
	# Prepare values for multiplication. We'll add first operator to itelf n times; 
	# where n = value of 2nd operand
	add   $s4, $zero, $t4       # Value of first operand = $s4, we'll use this to add
	addi  $s0, $zero, 0         # Ensure counter = 0
	beq   $t3, 1, NotEqual1
	j     StepOver

NotEqual1:     
       # If first operator = $s3, which is ZERO right now, we're done.
       # Multiplication = 0
       add    $s3, $zero, $t4     
       j      AnswerFound
	
StepOver: 
       # If we first operator != 0, we decrement counter by, then multiple
       addi   $t3, $t3, -1
			
plusMulti:	
	# Perform one iteration of multiplication, and sotre the value
        add    $t4, $t4, $s4	
	beq    $s0, $t3, AnswerFound  
	addi   $s0, $s0, 1        
	add    $s3, $zero, $t4
	j plusMulti 		
	
	
##########################
### CONTROL FUNCTIONS  ###
##########################
StackOperator:	
	# Remember whichver operator was pressed; but we'll continue with the operation in $t2
	add $t1, $zero, $s1	
	
	# Ensure base number = 0; so we can continue building a new one for 2nd operand  
	addi $t7, $zero, 0	
	
AnswerFound:	
	# Store the answer into $s1; we'll display it next time through the loop
	add $s1, $zero, $s3 
	beq $t1, $zero, Init   
	
	# Move the stored operator to $t2, for immediate use
	add $t2, $zero, $t1 
	# Clear out stored operator
	add $t1, $zero, 0   
	
	# First operand ($t4) = val in $s3
	add $t4, $zero, $s3 
	
	# Clear Second operand ($t3)
	addi $t3, $zero, 0  
	
	# Jump back to Init
	beq  $s5, $zero, Init  
	j Init	
	
#////////////
#// Equals //
#////////////	
Equals:     
	# Begin checks if equals was pressed
	beq $s1, 1, NotEqual2
        j StepOver2

NotEqual2:
	addi $s5, $zero, 1 
	
	
StepOver2:    
	# Jump back to beginning and display current value if no operator
	beq $t2, $zero, NotEqual3
	j StepOver3

NotEqual3:	
	addi $s1, $t8, 0 
 	j Init  

StepOver3:
	# Store second operand in ($3)
	add $t3, $zero, $t8  
	# Zero out $t7
	addi $t7, $zero, 0 	
	
	# Move to mathematical operator if one was pressed
	beq $t2, 10, plus  
	beq $t2, 11, minus 
	beq $t2, 12, Multiply 
	beq $t2, 13, Divide   
		
	j Init  
		
	
	
#////////////////////////
#//////   CLEAR  ////////
#////////////////////////
Clear:   
	# Clear all registers	    
	addi $s1, $zero, 0
	addi $t7, $zero, 0
	addi $t6, $zero, 0
	addi $t5, $zero, 0
    	addi $t4, $zero, 0
    	addi $t3, $zero, 0
    	addi $t2, $zero, 0
    	addi $t1, $zero, 0	
   	j     Init			