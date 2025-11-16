################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Muhammad Hashmi, 1011147910
# Student 2: Amir Diba, 1011228814
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

gray: .word 0x707070

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
 
    jal draw_walls
    
    # load a0 = x value and a1= y value to prepare to draw column
    li $a0, 2  #starting column
    li $a1, 1   # starting row
    
    #draw three gem column at x, y pos
    jal draw_column
    
    li $a0, 4  #starting column
    li $a1, 4   # starting row
    
    #draw three gem column at x, y pos
    jal draw_column
    
    li $a0, 4  #starting column
    li $a1, 8   # starting row
    
    #draw three gem column at x, y pos
    jal draw_column
    
    j game_loop
    li $v0, 10
    syscall

    
game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep
    # copied from the starter code
    # 5. Go back to Step 1
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    j game_loop


    keyboard_input:                     # A key is pressed 
        lw $a0, 4($t0)                  # Load second word from keyboard
        beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
        beq $a0, 0x64, respond_to_D
        beq $a0, 0x61, respond_to_A
        beq $a0, 0x77, respond_to_W
        beq $a0, 0x73, respond_to_S
    
        syscall
        j game_loop
    
    j game_loop


#Function definitions

#a0 is the row
# a1 is the column
# the result gives the memory address of the pixel u want to draw at
get_address:
    li $v0, 0x10008000
    sll $t0, $a0, 5
    add $t0, $t0, $a1
    sll $t0, $t0, 2
    add $v0, $v0, $t0
    jr $ra

draw_walls:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    lw $s0, gray
        
    li $a0, 0
    li $s1, 0
    top_loop:
        move $a1, $s1
        jal get_address
        sw $s0, 0($v0)
        addi $s1, $s1, 1
        ble $s1, 7, top_loop
        
        li $a0, 25
        li $s1, 0
    bottom_loop:
        move $a1, $s1
        jal get_address
        sw $s0, 0($v0)
        addi $s1, $s1, 1
        ble $s1, 7, bottom_loop
        
    li $a1, 0
    li $s1, 0
    left_loop:
        move $a0, $s1
        jal get_address
        sw $s0, 0($v0)
        addi $s1, $s1, 1
        ble $s1, 24, left_loop
        
    li $a1, 7
    li $s1, 0
    right_loop:
        move $a0, $s1
        jal get_address
        sw $s0, 0($v0)
        addi $s1, $s1, 1
        ble $s1, 24, right_loop
        
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    
    jr $ra
    
    
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
        
respond_to_Q:
  li $v0, 10                      # Quit gracefully
  syscall

respond_to_D:
    addi $s0, $s0, 1
    #
    j game_loop

respond_to_A:
    addi $s0, $s0, -1
    #
    j game_loop


respond_to_S:
    addi $s1, $s1, 1
    #
    j game_loop

respond_to_W:
# this is a problem of switching 3 addresses i think
# lets say a = 1, b = 2, c=3
# you have to assign a=c, b=a, c=b in parallel everytime w is pressed
# what you could do is make two temp variables (registers in this case)
# temp_c = c_0, temp_b = b_0, so you would do b = a, a = temp_c, c = temp b 
# i thinkkkk
# SO imagine it like this
# $s1 = a (top)
# $s3 = b (middle)
# $s4 = c (bottom)
# $t0, $t1 = temps
#move $t0, $s4   # temp_c = old c
#move $t1, $s3   # temp_b = old b
#move $s3, $s1   # b = a
#move $s1, $t0   # a = temp_c
#move $s4, $t1   # c = temp_b
