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
match_map: .space 832

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


# Clears the entire match_map to 0
clear_match_map:
    la $t0, match_map
    li $t1, 208           
    li $t2, 0
clear_map_loop:
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bnez $t1, clear_map_loop
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
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal set_column_in_the_board
    
    jal clear_match_map
    jal scan_horizontal_matches
    jal scan_vertical_matches
    jal scan_diagonal
    jal clear_marked_cells
    jal apply_gravity
    
    
    li $t0, 4
    sw $t0, curr_column_x
    li $t0, 1
    sw $t0, curr_column_y
    jal load_default_column
    jal draw_screen_helper
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
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

# draws a unit at (color, x, y) = (a0, a1, a2)
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

# erases at (row, col) = (a0, a1)
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
    

scan_horizontal_matches:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $t0, 1
    
sh_row_loop:
    bge $t0, 25, sh_done
    li $t1, 1    
    
sh_col_loop:
    bge $t1, 7, sh_next_row
    addi $sp, $sp, -8
    sw $t0, 0($sp)    # save row
    sw $t1, 4($sp)    # save col
    
    move $a0, $t0
    move $a1, $t1
    jal read_cell_from_array
    move $t2, $v0 
    
    li $t3, -1
    beq $t2, $t3, sh_skip_empty
    
    # Count run
    li $t3, 0 
    lw $t4, 4($sp)    # check_col = col
    
sh_count_loop:
    bge $t4, 7, sh_check_run
    
    lw $a0, 0($sp)    
    move $a1, $t4     # check_col
    jal read_cell_from_array
    
    bne $v0, $t2, sh_check_run
    
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    j sh_count_loop
    
sh_check_run:
    blt $t3, 3, sh_skip_empty
    
    # Mark cells
    lw $t5, 4($sp)
    add $t6, $t5, $t3 
    
sh_mark_loop:
    bge $t5, $t6, sh_mark_done
    
    lw $a0, 0($sp)    # row
    move $a1, $t5     # col
    jal get_offset_of_board
    
    la $t7, match_map
    add $t7, $t7, $v0
    li $t8, 1
    sw $t8, 0($t7)
    
    addi $t5, $t5, 1
    j sh_mark_loop
    
sh_mark_done:
    lw $t1, 4($sp)  
    add $t1, $t1, $t3
    sw $t1, 4($sp)   
    
sh_skip_empty:
    lw $t0, 0($sp)    
    lw $t1, 4($sp)    
    addi $sp, $sp, 8  
    addi $t1, $t1, 1  
    j sh_col_loop
    
sh_next_row:
    addi $t0, $t0, 1
    j sh_row_loop
    
sh_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#same thing i think
scan_vertical_matches:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $t0, 1     
    
sv_col_loop:
    bge $t0, 7, sv_done   
    li $t1, 1       
    
sv_row_loop:
    bge $t1, 25, sv_next_col  


    addi $sp, $sp, -8
    sw $t1, 0($sp)    
    sw $t0, 4($sp)   

    move $a0, $t1     
    move $a1, $t0     
    jal read_cell_from_array
    move $t2, $v0     

    li $t3, -1
    beq $t2, $t3, sv_skip_empty   

    li $t3, 0      
    lw $t4, 0($sp)     

sv_count_loop:
    bge $t4, 25, sv_check_run    
    move $a0, $t4
    lw   $a1, 4($sp)   
    jal read_cell_from_array
    bne $v0, $t2, sv_check_run
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    j sv_count_loop

sv_check_run:
    blt $t3, 3, sv_skip_empty

    lw $t5, 0($sp)     
    add $t6, $t5, $t3  

sv_mark_loop:
    bge $t5, $t6, sv_mark_done

    move $a0, $t5       
    lw $a1, 4($sp)    
    jal get_offset_of_board

    la $t7, match_map
    add $t7, $t7, $v0
    li $t8, 1
    sw $t8, 0($t7)

    addi $t5, $t5, 1
    j sv_mark_loop

sv_mark_done:
    lw $t1, 0($sp)    
    add $t1, $t1, $t3
    sw $t1, 0($sp)

sv_skip_empty:
    lw $t1, 0($sp)    
    lw $t0, 4($sp)    
    addi $sp, $sp, 8  
    addi $t1, $t1, 1  
    j sv_row_loop

sv_next_col:
    addi $t0, $t0, 1
    j sv_col_loop

sv_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Clears all cells marked as 1 in match_map
clear_marked_cells:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    
    li $s0, 1
    
cmc_row_loop:
    bge $s0, 25, cmc_done
    li $s1, 1
    
cmc_col_loop:
    bge $s1, 7, cmc_next_row
    
    # Check if marked in match_map
    move $a0, $s0
    move $a1, $s1
    jal get_offset_of_board
    
    la $t0, match_map
    add $t0, $t0, $v0
    lw $t1, 0($t0)
    
    beqz $t1, cmc_next_col
    
    move $a0, $s0
    move $a1, $s1
    li $a2, -1
    jal store_in_cell
    
    move $a0, $s1
    move $a1, $s0
    jal erase_unit
    
cmc_next_col:
    addi $s1, $s1, 1
    j cmc_col_loop
    
cmc_next_row:
    addi $s0, $s0, 1
    j cmc_row_loop
    
cmc_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra
    
    
# Scanning for diagonal matches
scan_diagonal:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $t0, 0               # Row iterator
    
sd_row_loop:
    bge $t0, 26, sd_done    # Stop if Row >= 26
    li $t1, 0               # Col iterator
    
sd_col_loop:
    bge $t1, 8, sd_next_row #col stop > 8
    
    addi $sp, $sp, -8
    sw $t0, 0($sp)          # save outer row
    sw $t1, 4($sp)          # save outer col
    
    # getting color
    move $a0, $t0
    move $a1, $t1
    jal read_cell_from_array
    move $t2, $v0           # t2 = color
    
    li $t3, -1
    beq $t2, $t3, sd_skip_empty # Skip if cell is empty
    
    # from top left to bot right
    li $t3, 0               # Run Count
    lw $t4, 0($sp)          # curr_row = outer_row
    lw $t5, 4($sp)          # curr_col = outer_col
    
sd_count_loop_1:
    # Check bounds: Row < 26 AND Col < 8
    bge $t4, 26, sd_check_run_1
    bge $t5, 8,  sd_check_run_1
    
    move $a0, $t4
    move $a1, $t5
    jal read_cell_from_array
    
    bne $v0, $t2, sd_check_run_1 # stop if color doesnt match
    
    addi $t3, $t3, 1        # mark++
    addi $t4, $t4, 1        # row++
    addi $t5, $t5, 1        # col++
    j sd_count_loop_1
    
sd_check_run_1:
    blt $t3, 3, sd_start_dir_2   # If run < 3, try next direction
    
    # marking
    lw $t4, 0($sp)          # reset row
    lw $t5, 4($sp)          # reset col
    add $t6, $t4, $t3       # last = start-row + marks
    
sd_mark_loop_1:
    bge $t4, $t6, sd_start_dir_2
    
    move $a0, $t4       # row
    move $a1, $t5           # col
    jal get_offset_of_board
    
    la $t7, match_map
    add $t7, $t7, $v0       
    li $t8, 1
    sw $t8, 0($t7)          # marking at (row, col)
    
    addi $t4, $t4, 1        # row ++
    addi $t5, $t5, 1    # col ++
    j sd_mark_loop_1

# top right oto bot left direction
sd_start_dir_2:
    li $t3, 0               # markCount
    lw $t4, 0($sp)          # row
    lw $t5, 4($sp)          # col

sd_count_loop_2:
    # Check bounds: Row < 26 AND Col >= 0
    bge $t4, 26, sd_check_run_2
    blt $t5, 0,  sd_check_run_2
    
    move $a0, $t4
    move $a1, $t5
    jal read_cell_from_array
    
    bne $v0, $t2, sd_check_run_2 # stop if color doesnt match
    
    addi $t3, $t3, 1        # marks ++
    addi $t4, $t4, 1        # row ++
    addi $t5, $t5, -1       # col -- (Moving Left)
    j sd_count_loop_2
    
sd_check_run_2:
    blt $t3, 3, sd_skip_empty    # If run < 3, dont mark
    
    # marking
    lw $t4, 0($sp)          # reset row
    lw $t5, 4($sp)      # rset cok
    add $t6, $t4, $t3       # stop_row = start_row + marksCount
    
sd_mark_loop_2:
    bge $t4, $t6, sd_skip_empty
    
    move $a0, $t4           # row
    move $a1, $t5           # col
    jal get_offset_of_board
    
    la $t7, match_map
    add $t7, $t7, $v0   
    li $t8, 1
    sw $t8, 0($t7)  
    
    addi $t4, $t4, 1
    addi $t5, $t5, -1
    j sd_mark_loop_2

sd_skip_empty:
    # Restore Stack
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    addi $sp, $sp, 8
    
    addi $t1, $t1, 1
    j sd_col_loop

sd_next_row:
    addi $t0, $t0, 1
    j sd_row_loop

sd_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    

# gravity plan:
    #1 - read and write pointer intialized at (col, 25)
    #2 - write marks bottom ready to fill if empty
    #3 - if full, write goes up by one row
    #4 - write keeps going until it reaches an empty spot or the top, if it reaches the top game over
    #5 - if it finds an empty spot, read is initialized to writes position and looks up for any gems, 
    # if there are gems, it replaces their location with write and write moves up and read does the same thing again
    #6 - if read reaches the top, col ++
    #7- repeat until write goes out of bound

apply_gravity:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)      # col iter
    sw $s1, 8($sp)      # write pointer (row)
    sw $s2, 12($sp)     # read pointer (row)
    
    li $s0, 1        # col starts at 0
    
gravity_col_loop:
    bgt $s0, 6, gravity_done
    
    # start read and write at bottom=25
    li $s1, 24
    li $s2, 24
# finding first empty spot for write
gravity_write_placement_loop:
    li $t9, 1
    blt $s1, $t9, gravity_next_col
    
    # read val at (write, col)
    move $a0, $s1
    move $a1, $s0
    jal read_cell_from_array
    move $t0, $v0           # value at cell in t0
    
    # empty check
    li $t9, -1
    beq $t0, $t9, gravity_shift_start
    
gravity_next_write:
    addi $s1, $s1, -1
    j gravity_write_placement_loop

gravity_shift_start:
    addi $t1, $s1, -1
    move $s2, $t1
    j gravity_shift
    
# write pointer at empty spot, initialize read at write - 1
gravity_shift:
    li $t9, 1
    blt $s2, $t9, gravity_next_col
    
    #get value at (read, col)
    move $a0, $s2
    move $a1, $s0
    jal read_cell_from_array
    move $t0, $v0
    move $s4, $t0
    
    #emptiness check
    li $t9, -1
    bne $t0, $t9, gravity_replace_block
    
gravity_decrement_read:
    addi $s2, $s2, -1
    j gravity_shift

# replaces gem at (read, col) with (write, col). increments write and read
gravity_replace_block:
    # draw block at write
    # visual draw
    move $a0, $s4
    jal load_random_color_value
    move $a0, $v0
    move $a1, $s0
    move $a2, $s1
    jal draw_unit
    
    #store it
    move $a0, $s1
    move $a1, $s0
    move $a2, $s4
    jal store_in_cell
    
    #erase block at read
    move $a0, $s0
    move $a1, $s2
    jal erase_unit
    
    #store the erase
    li $a2, -1
    move $a1, $s0
    move $a0, $s2
    jal store_in_cell
    addi $s2, $s2, -1
    addi $s1, $s1, -1
    j gravity_sleep
gravity_sleep:
    move $t0, $a0
    li $v0, 32
    li $a0, 150
    syscall
    move $a0, $t0
    j gravity_write_placement_loop
    

gravity_next_col:
    addi $s0, $s0, 1
    j gravity_col_loop

gravity_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra