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

####ARRAY FUNCTIONS######
#
#the arguments are a0, a1, which are row, column
#if you wanna understand how this works lmk
get_offset_of_board:
    li $t0, 8
    mul $t1, $a0, $t0 #so im first multiplying the current row by 8
    add $t1, $t1, $a1 #then im adding the current column to to the result (r * 8) + col
    sll $v0, $t1, 2   #shift twice multiplies it by 4. (4 bytes per word)
    jr $ra

# Reads the gem color at board[row][col]
read_cell_from_array:
    add $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal get_offset_of_board
    la $t8, game_board
    add $t8, $t8, $v0 #i think this gets the address of the cell because v0 has the offset and gameboard is the adress sooo
    lw $v0, 0($t8)
    
    lw $ra, 0($sp)
    addi $sp, $sp,4
    jr $ra
    
#a0, a1 row, column, a2 is the value to store.
store_in_cell:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    move $t9, $a2              # Save value
    jal get_offset_of_board   # Get index in $v0
    la $t8, game_board         # Use $t8 instead of $t0!
    add $t8, $t8, $v0          # Add offset
    sw $t9, 0($t8)             # Store value
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

########################

#a0 is the row
# a1 is the column
# the result gives the memory address of the pixel u want to draw at

#loads the default starting values of the column into the global varibales
load_default_column:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Get random index (0-5) for gem 0
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    move $t0, $a0
    sw $t0, curr_gem_0
    
    # Get random index (0-5) for gem 1
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    move $t0, $a0
    sw $t0, curr_gem_1
    
    # Get random index (0-5) for gem 2
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    move $t0, $a0
    sw $t0, curr_gem_2
    
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

respond_to_S:
    jal check_collision_down
    beq $v0, 0, lock_and_new_column
    
    lw $t1, curr_column_y
    addi $t1, $t1, 1
    lw $a0, curr_column_x
    move $a1, $t1
    jal draw_screen
    j game_loop

respond_to_A:
    jal check_collision_left
    beq $v0, 0, game_loop
    
    lw $t1, curr_column_x
    addi $t1, $t1, -1
    
    move $a0, $t1
    lw $a1, curr_column_y
    jal draw_screen
    j game_loop

respond_to_D:
    jal check_collision_right
    beq $v0, 0, game_loop
    
    lw $t1, curr_column_x
    addi $t1, $t1, 1
    
    move $a0, $t1
    lw $a1, curr_column_y
    jal draw_screen
    j game_loop

respond_to_W:
    # Rotate gems
    lw $t0, curr_gem_0
    lw $t1, curr_gem_1
    lw $t2, curr_gem_2
    
    sw $t2, curr_gem_0  # gem2 -> gem0
    sw $t0, curr_gem_1  # gem0 -> gem1
    sw $t1, curr_gem_2  # gem1 -> gem2
    
    lw $a0, curr_column_x
    lw $a1, curr_column_y
    jal draw_screen
    j game_loop

lock_and_new_column:
    jal set_column_in_the_board
    
    li $t0, 4
    sw $t0, curr_column_x
    li $t0, 1
    sw $t0, curr_column_y
    jal load_default_column
    jal draw_screen_helper
    j game_loop

set_column_in_the_board:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    
    lw $s0, curr_column_x
    lw $s1, curr_column_y
    
    #gem 0
    move $a0, $s1
    move $a1, $s0
    lw $a2, curr_gem_0
    jal store_in_cell
    
    #gem 1 
    addi $a0, $s1, 1
    move $a1, $s0
    lw $a2, curr_gem_1
    jal store_in_cell
    
    #gem 2 
    addi $a0, $s1, 2
    move $a1, $s0
    lw $a2, curr_gem_2
    jal store_in_cell
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra
    
check_collision_down:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $a0, curr_column_y
    addi $a0, $a0, 3
    
    bge $a0, 25, collision_detected #hits a gray wall 
    
    lw $a1, curr_column_x
    jal read_cell_from_array
    lw $t1, empty_cell
    bne $v0, $t1, collision_detected
    
    li $v0, 1
    j check_collision_done

check_collision_right:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, curr_column_x
    addi $t0, $t0, 1
    
    bge $t0, 7, collision_detected
    
    lw $t1, curr_column_y

    move $a0, $t1
    move $a1, $t0
    jal read_cell_from_array
    lw $t2, empty_cell
    bne $v0, $t2, collision_detected
    
    lw $t1, curr_column_y
    addi $a0, $t1, 1
    lw $t0, curr_column_x
    addi $a1, $t0, 1
    jal read_cell_from_array
    lw $t2, empty_cell
    bne $v0, $t2, collision_detected
    
    lw $t1, curr_column_y
    addi $a0, $t1, 2
    lw $t0, curr_column_x
    addi $a1, $t0, 1
    jal read_cell_from_array
    lw $t2, empty_cell
    bne $v0, $t2, collision_detected
    
    li $v0, 1
    j check_collision_done

check_collision_left:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, curr_column_x
    addi $t0, $t0, -1
    
    ble $t0, 0, collision_detected
    
    lw $t1, curr_column_y

    move $a0, $t1
    move $a1, $t0
    jal read_cell_from_array
    lw $t2, empty_cell
    bne $v0, $t2, collision_detected
    
    lw $t1, curr_column_y
    addi $a0, $t1, 1
    lw $t0, curr_column_x
    addi $a1, $t0, -1
    jal read_cell_from_array
    lw $t2, empty_cell
    bne $v0, $t2, collision_detected
    
    lw $t1, curr_column_y
    addi $a0, $t1, 2
    lw $t0, curr_column_x
    addi $a1, $t0, -1
    jal read_cell_from_array
    lw $t2, empty_cell
    bne $v0, $t2, collision_detected
    
    li $v0, 1
    j check_collision_done
    
collision_detected:
    li $v0, 0
    
check_collision_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_column:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $s0, curr_column_x
    lw $s1, curr_column_y
    lw $s2, curr_gem_0      
    lw $s3, curr_gem_1
    lw $s4, curr_gem_2
    
    # Convert index to color for gem 0
    move $a0, $s2
    jal load_random_color_value
    move $a0, $v0           
    move $a1, $s0
    move $a2, $s1
    jal draw_unit
    
    # Convert index to color for gem 1
    move $a0, $s3
    jal load_random_color_value
    move $a0, $v0
    move $a1, $s0
    addi $a2, $s1, 1
    jal draw_unit
    
    # Convert index to color for gem 2
    move $a0, $s4
    jal load_random_color_value
    move $a0, $v0
    move $a1, $s0
    addi $a2, $s1, 2
    jal draw_unit
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

load_random_color_value:
    la $t0, GEM_COLOR_0
    sll $t1, $a0, 2
    add $t2, $t1, $t0
    lw $v0, 0($t2)
    jr $ra
        
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

draw_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #save arguments
    addi $sp, $sp, -8
    sw $a0, 0($sp)          # new_x
    sw $a1, 4($sp)          # new_y
    
    #erasing old columns
    lw $s0, curr_column_x
    lw $s1, curr_column_y
    
    move $a0, $s0
    move $a1, $s1
    jal erase_column 
    
    # Update position
    lw $s2, 0($sp)
    lw $s3, 4($sp)
    
    sw $s2, curr_column_x
    sw $s3, curr_column_y
    
    jal draw_screen_helper
    
    addi $sp, $sp, 8
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

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

erase_unit:
    addi $sp, $sp, -8
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

draw_screen_helper:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #redraw all parts of the game
    jal draw_column
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra