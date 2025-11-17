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
BLACK: .word 0x000000

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

curr_column_x: .word 4       
curr_column_y: .word 1       
curr_gem_0: .word 0          
curr_gem_1: .word 1          
curr_gem_2: .word 2       

#each index stores the gem color
#this will help later
game_board: .space 832 #(26*8 *4)

empty_cell: .word -1 #im thinking we make empty blocks into -1
##############################################################################
# Code
##############################################################################
	.text
	.globl main
    # Run the game.
main:
    # Initialize the game
    
    #this initializes the game board
    #ive set every spot to -1 which indicates an empty cell
    #I think ive also added collision detection in the respond_to_(A,S,D) by checking if the value will overflow the boundaries or not.
    la $t0, game_board
    li $t1, 208
    li $t2, -1
    init_loop:
        sw $t2, 0($t0)
        addi $t0, $t0, 4
        addi $t1, $t1, -1
        bnez $t1, init_loop
 
    jal draw_walls
    jal load_default_column
    jal draw_screen_helper
    
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

#loads the default starting values of the column into the global varibales
load_default_column:
    addi $sp, $sp, -4
    sw, $ra, 0($sp)
    
    # store color 
    jal get_random_color_value
    sw $v0, curr_gem_0
    
    jal get_random_color_value
    sw $v0, curr_gem_1
    
    jal get_random_color_value
    sw $v0, curr_gem_2
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


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
    
        
respond_to_Q:
  li $v0, 10                      # Quit gracefully
  syscall

respond_to_D:
    lw $t1, curr_column_x
    addi $t1, $t1, 1
    bgt $t1, 6, game_loop
    
    move $a0, $t1
    lw $a1, curr_column_y
    lw $a2, curr_gem_0
    lw $a3, curr_gem_1
    lw $t0, curr_gem_2
    jal draw_screen
    j game_loop
    
    
    
respond_to_A:
    lw $t1, curr_column_x
    addi $t1, $t1, -1
    move $t2, $t1
    blt $t1, 1, game_loop
    
    move $a0, $t2
    lw $a1, curr_column_y
    lw $a2, curr_gem_0
    lw $a3, curr_gem_1
    lw $t0, curr_gem_2
    jal draw_screen
    j game_loop
    
respond_to_S:
    lw $t1, curr_column_y
    addi $t1, $t1, 1
    bgt $t1, 22, game_loop
 
    lw $a0, curr_column_x
    move $a1, $t1
    lw $a2, curr_gem_0
    lw $a3, curr_gem_1
    lw $t0, curr_gem_2
    jal draw_screen
    j game_loop
    

#shuffles gem colors pushing from top to bottom wrapping around
# calls draw_screen so uses (a0, a1, a2, a3, t0)
respond_to_W:
    lw $a0, curr_column_x
    lw $a1, curr_column_y
    lw $a2, curr_gem_2
    lw $a3, curr_gem_0
    lw $t0, curr_gem_1
    
    jal draw_screen 
    j game_loop
    
# draws a column based on starting x (curr_x) and y (curr_y) with a curr_gem colors
draw_column:
    #store return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #saving curr values into saved
    lw $s0, curr_column_x
    lw $s1, curr_column_y
    lw $s2, curr_gem_0
    lw $s3, curr_gem_1
    lw $s4, curr_gem_2
    
    # drawing top gme
    move $a1, $s0
    move $a2, $s1
    move $a0, $s2
    jal draw_unit
    
    # drawing middle gme
    move $a1, $s0
    addi $a2, $s1, 1 # moving one Y down
    move $a0, $s3
    jal draw_unit
    
    # drawing bottom gme
    move $a1, $s0
    addi $a2, $s1, 2 # move 2 Y down
    move $a0, $s4
    jal draw_unit
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Returns a color value from 6 options randomly and stores it at $v0
    get_random_color_value:
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        
        li $v0, 42
        li $a0, 0
        li $a1, 6 # Max value (exclusive)
        syscall
        
        # load the color vlue
        jal load_random_color_value
        
        lw $ra, 0($sp)
        addi $sp, $sp, 4
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
        
        sll $t1, $t1, 2   # mul by offset
        
        la $t0, ADDR_DSPL
        lw $t0, 0($t0)   #base add
        
        add $t4, $t0, $t1   # final = base + offset
        
        sw $a0, 0($t4)      # store the color value a0 at final address
        
        jr $ra

# erases old columns, redraws column with the updated position (new_x, new_y, top_color, mid_color, bot_color)
# addresses (a0, a1 a2, a3, t0)
draw_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #save arguments to stack
    addi $sp, $sp, -20      # 5 4 byte values
    sw $a0, 0($sp)          # new_x
    sw $a1, 4($sp)          # new_y
    sw $a2, 8($sp)          # new_gem_0
    sw $a3, 12($sp)          # new_gem_1
    sw $t0, 16($sp)          # new_gem_2
    
    #erasing old columns
    lw $s0, curr_column_x
    lw $s1, curr_column_y #old x, y vals
    
    move $a0, $s0
    move $a1, $s1
    jal erase_column 
    
    # update the global curr variables with new values
    lw $s2, 0($sp)      # s2 = new x
    lw $s3, 4($sp)      # s2 = new y
    lw $s4, 8($sp)      # s2 = new gem0
    lw $s5, 12($sp)      # s2 = new gem1
    lw $s6, 16($sp)      # s2 = new x=gem2
    
    sw $s2, curr_column_x
    sw $s3, curr_column_y
    sw $s4, curr_gem_0
    sw $s5, curr_gem_1
    sw $s6, curr_gem_2
    
    jal draw_screen_helper
    
    addi $sp, $sp, 20
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#erases old columns
# erases starting form (x, y) = (a0, a1)
erase_column:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $sp, $sp, -8
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    
    
    lw $a0, 0($sp)
    lw $a1, 4($sp)
    jal erase_unit
    
    # erase middle gem
    lw $t0, 4($sp)
    lw $a0, 0($sp)
    addi $a1, $t0, 1
    jal erase_unit
    
    # erase bottom gem
    lw $t0, 4($sp)
    lw $a0, 0($sp)
    addi $a1, $t0, 2
    jal erase_unit
    
    
    addi $sp, $sp, 8
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#erases the unit at (x, y) = (a0, a1)
# calls draw unit so uses a2 slot
erase_unit:
    addi, $sp, $sp, -8
    sw $ra, 0($sp)
    sw $a1, 4($sp)  # save y in stack because a1 is going to be overwritten
    
    # draw unit args (color, x, y) = (a0, a1, a2)
    # shift y to a2
    move $t0, $a0
    move $t1, $a1
    
    lw $a0, BLACK
    move $a1, $t0
    lw $a2, 4($sp)
    
    jal draw_unit
    
    lw $ra, 0($sp)
    addi $sp, $sp, 8
    jr $ra

# draws the screen with new values
draw_screen_helper:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #redraw all parts of the game
    jal draw_column
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    


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
