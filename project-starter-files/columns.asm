################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Muhammad Hashmi, 1011147910
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
# The colors of the gems
GEM_COLOR_0: .word 0xFF0000 #0: red
GEM_COLOR_1: .word 0x00FF00 #1: green
GEM_COLOR_2: .word 0x0000FF #2: blue
GEM_COLOR_3: .word 0x800080 #3: purple
GEM_COLOR_4: .word 0xFFFF00 #4: yellow
GEM_COLOR_5: .word 0xFF8000 #5: orange
##############################################################################
# Code
##############################################################################
	.text
	.globl main
    # Run the game.
main:
    # Initialize the game
    # load a0 = x value and a1= y value to prepare to draw column
    li $a0, 0  #starting column
    li $a1, 0   # starting row
    
    #draw three gem column at x, y pos
    jal draw_column
    
    
game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	
	# 4. Sleep
	li $v0, 32
    li $a0, 1000  # Wait for 1000ms (1 second) to confirm it is drawing
    syscall

    # 5. Go back to Step 1
    j game_loop


#Function definitions

# draws a column based on starting x (a0) and y (a1) with a three gem height and random colors
draw_column:
    #store return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #saving x, y coordinates
    move $s0, $a0
    move $s1, $a1
    
    # starting loop counter with s4 = index
    li $s4, 0

#loops until $t0 reaches >= 3
draw_column_loop:
    bge $s4, 3, draw_column_end 
    
    # get random color index
    jal get_random_color_index
    move $s2, $v0
    
    # load random color value
    move $a0, $s2
    jal load_random_color_value
    move $s3, $v0
    
    # calculate new y based on loop index s4=i
    add $a2, $s1, $s4
    
    # draw a pixel at current a0=color, a1=x, a2=y
    move $a0, $s3
    move $a1, $s0
    
    jal draw_unit
    
    # increment loop index 
    addi $s4, $s4, 1
    j draw_column_loop

# wraps up the function
draw_column_end:
    #restore ra and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    

# Returns a random integer between 0-5 stores it at $v0
    get_random_color_index:
        li $v0, 42
        li $a0, 0
        li $a1, 6 # Max value (exclusive)
        syscall
        move $v0, $a0 # put the random number into v0
        jr $ra
        
#Loads the color value based on random index stored in a0
# the value is stored v0
    load_random_color_value:
        la $t0, GEM_COLOR_0
        sll $t1, $a0, 2
        add $t2, $t1, $t0
        lw $v0, 0($t2)
        jr $ra
        
# draws a pixel given color_value (a0), x (a1), y (a2)
    draw_unit:
        #constants
        li $t6, 32  #display width
        li $t7, 4   # bytes per unit
        
        mul $t1, $a2, $t6   # y * width
        add $t1, $t1, $a1   # (y * width) + x
        
        mul $t1, $t1, $t7   # mul by offset
        
        la $t0, ADDR_DSPL
        lw $t0, 0($t0)   #base add
        
        add $t4, $t0, $t1   # final = base + offset
        
        sw $a0, 0($t4)      # store the color value a0 at final address
        
        jr $ra
        


