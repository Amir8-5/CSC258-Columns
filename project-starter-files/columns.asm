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
WHITE: .word 0xFFFFFF

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
game_board: .space 832 #(26*8 *4)
match_map: .space 832

empty_cell: .word -1 

drop_counter: .word 0
drop_delay: .word 60

####SCORE######
score_count: .word 0
high_score: .word 0
chain_multiplier: .word 10

# These are 3 (width) x 5 (height) patterns for the scoer
#by the way u read it backwards
#so the top is the last 3 digits and back
digit_0: .word 0b111101101101111 # so 111 101 101 101 111
digit_1: .word 0b111010010110010 # and so on
digit_2: .word 0b111100111001111
digit_3: .word 0b111001111001111
digit_4: .word 0b001001111101101
digit_5: .word 0b111001111100111
digit_6: .word 0b111101111100111
digit_7: .word 0b001001001001111
digit_8: .word 0b111101111101111
digit_9: .word 0b111001111101111  
###############
##############################################################################
# Code
##############################################################################
	.text
	.globl main
    # Run the game.
main:
    # Initialize the game
    li $t0, 0
    sw $t0, high_score
    
    la $t0, game_board
    li $t1, 208
    li $t2, -1
    init_loop:
        sw $t2, 0($t0)
        addi $t0, $t0, 4
        addi $t1, $t1, -1
        bnez $t1, init_loop
 
    # Initial Draw
    jal load_default_column
    jal redraw_game_state 
    
    j game_loop
    li $v0, 10
    syscall

game_loop:
    # 1. Input
    lw $t0, ADDR_KBRD               
    lw $t8, 0($t0)                  
    beq $t8, 1, keyboard_input      

    # 2. Gravity Logic (Time based)
    lw $t1, drop_counter
    lw $t2, drop_delay
    
    addi $t1, $t1, 10
    blt $t1, $t2, skip_gravity 
    
    li $t1, 0                  
    jal auto_gravity
    
    skip_gravity:
        sw $t1, drop_counter        
        
        # redraw
        jal redraw_game_state

        # sleep
        li $v0, 32
        # small sleep for stability
        li $a0, 50
        syscall
        j game_loop
    
    auto_gravity:
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        
        jal check_collision_down
        beq $v0, 0, lock_and_new_column
        
        lw $t1, curr_column_y
        addi $t1, $t1, 1
        sw $t1, curr_column_y
        
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra

    keyboard_input:                     
        lw $a0, 4($t0)                  
        beq $a0, 0x71, respond_to_Q     
        beq $a0, 0x64, respond_to_D
        beq $a0, 0x61, respond_to_A
        beq $a0, 0x77, respond_to_W
        beq $a0, 0x73, respond_to_S
    
        j game_loop


#Function definitions

# function that redraws the game screen based on the game board
redraw_game_state:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)      # Row iter
    sw $s1, 8($sp)      # Col iter

    jal draw_walls

    # looping over gameboard
    li $s0, 1           
redraw_row_loop:
    #ignoring firt gray wall
    bge $s0, 25, redraw_active_piece 
    
    # ignoring grey wal
    li $s1, 1           

redraw_col_loop:
    # stop before grey wall
    bge $s1, 7, redraw_next_row

    # get value in memory
    move $a0, $s0
    move $a1, $s1
    jal read_cell_from_array
    move $t0, $v0       # t0 = gem index or -1

    li $t1, -1
    beq $t0, $t1, draw_black_cell

    # get color
    move $a0, $t0       
    jal load_random_color_value 
    move $a0, $v0       # Color
    move $a1, $s1       # X
    move $a2, $s0       # Y
    jal draw_unit
    j redraw_next_col

draw_black_cell:
    lw $a0, BLACK
    move $a1, $s1
    move $a2, $s0
    jal draw_unit

redraw_next_col:
    addi $s1, $s1, 1
    j redraw_col_loop

redraw_next_row:
    addi $s0, $s0, 1
    j redraw_row_loop

redraw_active_piece:
    #3 Draw score and active column
    jal draw_score
    jal draw_high_score
    jal draw_high_score_label
    jal draw_column

    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra
    


get_offset_of_board:
    li $t0, 8
    mul $t1, $a0, $t0 
    add $t1, $t1, $a1 
    sll $v0, $t1, 2   
    jr $ra

read_cell_from_array:
    add $sp, $sp, -4
    sw $ra, 0($sp)
    jal get_offset_of_board
    la $t8, game_board
    add $t8, $t8, $v0 
    lw $v0, 0($t8)
    lw $ra, 0($sp)
    addi $sp, $sp,4
    jr $ra
    
store_in_cell:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    move $t9, $a2              
    jal get_offset_of_board   
    la $t8, game_board         
    add $t8, $t8, $v0          
    sw $t9, 0($t8)             
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

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

load_default_column:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    sw $a0, curr_gem_0
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    sw $a0, curr_gem_1
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    sw $a0, curr_gem_2
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
    lw $t0, score_count
    lw $t1, high_score
    
    ble $t0, $t1, quit_game
    
    sw $t0, high_score

quit_game:
    li $v0, 10                      
    syscall

respond_to_S:
    jal check_collision_down
    beq $v0, 0, lock_and_new_column
    
    lw $t1, curr_column_y
    addi $t1, $t1, 1
    sw $t1, curr_column_y   # Update Memory Only
    j game_loop

respond_to_A:
    jal check_collision_left
    beq $v0, 0, game_loop
    
    lw $t1, curr_column_x
    addi $t1, $t1, -1
    sw $t1, curr_column_x   # Update Memory Only
    j game_loop

respond_to_D:
    jal check_collision_right
    beq $v0, 0, game_loop
    
    lw $t1, curr_column_x
    addi $t1, $t1, 1
    sw $t1, curr_column_x   # Update Memory Only
    j game_loop

respond_to_W:
    # Rotate gems
    lw $t0, curr_gem_0
    lw $t1, curr_gem_1
    lw $t2, curr_gem_2
    sw $t2, curr_gem_0  
    sw $t0, curr_gem_1  
    sw $t1, curr_gem_2  
    j game_loop
    
lock_and_new_column:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal set_column_in_the_board
    
    # Initialize chain multiplier
    li $t0, 10
    sw $t0, chain_multiplier
    
match_loop_start:
    jal clear_match_map
    jal scan_horizontal_matches
    jal scan_vertical_matches
    jal scan_diagonal
    
    jal check_if_matches_exist
    beq $v0, 0, match_loop_done
    
    jal clear_marked_cells
    jal apply_gravity
    
    
    lw $t0, chain_multiplier
    addi $t0, $t0, 5
    sw $t0, chain_multiplier
    
    li $v0, 32
    li $a0, 300
    syscall
    
    jal redraw_game_state
    j match_loop_start
    
match_loop_done:
    li $t0, 4
    sw $t0, curr_column_x
    li $t0, 1
    sw $t0, curr_column_y
    jal load_default_column
    
    jal check_collision_down
    beq $v0, 0, respond_to_Q
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    j game_loop

# Helper to run one pass of logic
#resolve_matches_and_gravity:
    #addi $sp, $sp, -4
    #sw $ra, 0($sp)
    #jal clear_match_map
    #jal scan_horizontal_matches
    #jal scan_vertical_matches
    #jal scan_diagonal
    #jal clear_marked_cells # Updates Memory Only
    #jal apply_gravity      # Updates Memory Only
    #lw $ra, 0($sp)
    #addi $sp, $sp, 4
    #jr $ra

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
    bge $a0, 25, collision_detected 
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
    
    move $a0, $s2
    jal load_random_color_value
    move $a0, $v0           
    move $a1, $s0
    move $a2, $s1
    jal draw_unit
    
    move $a0, $s3
    jal load_random_color_value
    move $a0, $v0
    move $a1, $s0
    addi $a2, $s1, 1
    jal draw_unit
    
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
    sw $t0, 0($sp)    
    sw $t1, 4($sp)    
    move $a0, $t0
    move $a1, $t1
    jal read_cell_from_array
    move $t2, $v0 
    li $t3, -1
    beq $t2, $t3, sh_skip_empty
    li $t3, 0 
    lw $t4, 4($sp)    
sh_count_loop:
    bge $t4, 7, sh_check_run
    lw $a0, 0($sp)    
    move $a1, $t4     
    jal read_cell_from_array
    bne $v0, $t2, sh_check_run
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    j sh_count_loop
sh_check_run:
    blt $t3, 3, sh_skip_empty
    lw $t5, 4($sp)
    add $t6, $t5, $t3 
sh_mark_loop:
    bge $t5, $t6, sh_mark_done
    lw $a0, 0($sp)    
    move $a1, $t5     
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
    lw $t0, 0($sp)
    addi $sp, $sp, 8
    j sh_col_loop
    
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
    lw $t0, 4($sp)
    addi $sp, $sp, 8
    j sv_row_loop

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

clear_marked_cells:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)

    li $s2, 0   
    li $s0, 1
    
cmc_row_loop:
    bge $s0, 25, cmc_done
    li $s1, 1
    
cmc_col_loop:
    bge $s1, 7, cmc_next_row
    
    move $a0, $s0
    move $a1, $s1
    jal get_offset_of_board
    
    la $t0, match_map
    add $t0, $t0, $v0
    lw $t1, 0($t0)
    
    beqz $t1, cmc_next_col
    
    # Count cleared gems
    addi $s2, $s2, 1
    
    # Update memory only (no visual draw)
    move $a0, $s0
    move $a1, $s1
    li $a2, -1
    jal store_in_cell
    
cmc_next_col:
    addi $s1, $s1, 1
    j cmc_col_loop
    
cmc_next_row:
    addi $s0, $s0, 1
    j cmc_row_loop
    
cmc_done:
    # Apply multiplier (gems * multiplier) / 10
    move $t0, $s2
    lw $t1, chain_multiplier
    mul $t0, $t0, $t1
    
    li $t2, 10
    div $t0, $t2
    mflo $t0
    
    lw $t1, score_count
    add $t1, $t1, $t0
    sw $t1, score_count    
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
scan_diagonal:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $t0, 0               
sd_row_loop:
    bge $t0, 26, sd_done    
    li $t1, 0               
sd_col_loop:
    bge $t1, 8, sd_next_row 
    addi $sp, $sp, -8
    sw $t0, 0($sp)          
    sw $t1, 4($sp)          
    move $a0, $t0
    move $a1, $t1
    jal read_cell_from_array
    move $t2, $v0           
    li $t3, -1
    beq $t2, $t3, sd_skip_empty 
    li $t3, 0               
    lw $t4, 0($sp)          
    lw $t5, 4($sp)          
sd_count_loop_1:
    bge $t4, 26, sd_check_run_1
    bge $t5, 8,  sd_check_run_1
    move $a0, $t4
    move $a1, $t5
    jal read_cell_from_array
    bne $v0, $t2, sd_check_run_1 
    addi $t3, $t3, 1        
    addi $t4, $t4, 1        
    addi $t5, $t5, 1        
    j sd_count_loop_1
sd_check_run_1:
    blt $t3, 3, sd_start_dir_2   
    lw $t4, 0($sp)          
    lw $t5, 4($sp)          
    add $t6, $t4, $t3       
sd_mark_loop_1:
    bge $t4, $t6, sd_start_dir_2
    move $a0, $t4       
    move $a1, $t5           
    jal get_offset_of_board
    la $t7, match_map
    add $t7, $t7, $v0       
    li $t8, 1
    sw $t8, 0($t7)          
    addi $t4, $t4, 1        
    addi $t5, $t5, 1    
    j sd_mark_loop_1
    
# top right oto bot left direction
sd_start_dir_2:
    li $t3, 0               
    lw $t4, 0($sp)          
    lw $t5, 4($sp)          
sd_count_loop_2:
    bge $t4, 26, sd_check_run_2
    blt $t5, 0,  sd_check_run_2
    move $a0, $t4
    move $a1, $t5
    jal read_cell_from_array
    bne $v0, $t2, sd_check_run_2 
    addi $t3, $t3, 1        
    addi $t4, $t4, 1        
    addi $t5, $t5, -1       
    j sd_count_loop_2
sd_check_run_2:
    blt $t3, 3, sd_skip_empty    
    lw $t4, 0($sp)          
    lw $t5, 4($sp)      
    add $t6, $t4, $t3       
sd_mark_loop_2:
    bge $t4, $t6, sd_skip_empty
    move $a0, $t4           
    move $a1, $t5           
    jal get_offset_of_board
    la $t7, match_map
    add $t7, $t7, $v0   
    li $t8, 1
    sw $t8, 0($t7)  
    addi $t4, $t4, 1
    addi $t5, $t5, -1
    j sd_mark_loop_2
    
sd_skip_empty:
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

apply_gravity:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)      # col iter
    sw $s1, 8($sp)      # write pointer (row)
    sw $s2, 12($sp)     # read pointer (row)
    
    li $s0, 1        # col starts at 1 (to avoid left wall)
    
gravity_col_loop:
    bgt $s0, 6, gravity_done # Stop at col 6 (to avoid right wall)
    
    # start read and write at bottom=25 (actually 24 for safety in loop bounds)
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
    
    # store gem in new location
    move $a0, $s1
    move $a1, $s0
    move $a2, $s4
    jal store_in_cell
    
    # erase gem from old location
    li $a2, -1
    move $a1, $s0
    move $a0, $s2
    jal store_in_cell
    
    addi $s2, $s2, -1
    addi $s1, $s1, -1
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


####### SCORE FUNCTIONS #########
increment_score:
    lw $t0, score_count
    addi $t0, $t0, 1
    sw $t0, score_count
    jr $ra

# a0 (which digit), a1 (row), a2(column)
draw_digit:
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    
    # look up the pattern
    la $t0, digit_0
    sll $t1, $a0, 2
    add $t0, $t0, $t1
    lw $s0, 0($t0)
    
    move $s3, $a1
    move $t9, $a2
    
    li $s1, 0
    
draw_digit_row:
    bge $s1, 5, draw_digit_done
    li $s2, 0
    
draw_digit_col:
    bge $s2, 3, draw_digit_next_row
    
    andi $t0, $s0, 1
    beqz $t0, draw_digit_skip_pixel
    
    # Draw white pixel
    add $a0, $s3, $s1
    sub $a1, $t9, $s2
    addi $a1, $a1, 2
    jal get_address
    lw $t1, WHITE
    sw $t1, 0($v0)
    
draw_digit_skip_pixel:
    srl $s0, $s0, 1
    addi $s2, $s2, 1
    j draw_digit_col
    
draw_digit_next_row:
    addi $s1, $s1, 1
    j draw_digit_row
    
draw_digit_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    addi $sp, $sp, 20
    jr $ra

# Actually drawing the score
draw_score:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    li $s0, 2
clear_score_row:
    bge $s0, 7, clear_done
    li $s1, 19
clear_score_col:
    bge $s1, 30, next_clear_row
    
    move $a0, $s0
    move $a1, $s1
    jal get_address
    lw $t0, BLACK
    sw $t0, 0($v0)
    
    addi $s1, $s1, 1
    j clear_score_col
next_clear_row:
    addi $s0, $s0, 1
    j clear_score_row
    
clear_done:
    lw $s0, score_count
    
    li $t0, 100
    div $s0, $t0
    mflo $s1     # $s1 = hundreds digit
    mfhi $t1     # $t1 = remainder (0-99)
    
    # Extract tens and ones from remainder
    li $t0, 10
    div $t1, $t0
    mflo $s0     # $s0 = tens digit
    mfhi $s2     # $s2 = ones digit
    
    # Draw hundreds digit
    move $a0, $s1
    li $a1, 2
    li $a2, 19
    jal draw_digit
    
    # Draw tens digit
    move $a0, $s0
    li $a1, 2
    li $a2, 23
    jal draw_digit
    
    # Draw ones digit
    move $a0, $s2
    li $a1, 2
    li $a2, 27
    jal draw_digit
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
check_if_matches_exist:
    la $t0, match_map
    li $t1, 208
    
check_match_loop:
    lw $t2, 0($t0)
    bnez $t2, matches_found
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bnez $t1, check_match_loop
    
    li $v0, 0  
    jr $ra
    
matches_found:
    li $v0, 1
    jr $ra
    
    
draw_high_score:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    li $s0, 27  # Start row
clear_hs_row:
    bge $s0, 32, hs_clear_done
    li $s1, 19
clear_hs_col:
    bge $s1, 30, next_hs_clear_row
    
    move $a0, $s0
    move $a1, $s1
    jal get_address
    lw $t0, BLACK
    sw $t0, 0($v0)
    
    addi $s1, $s1, 1
    j clear_hs_col
next_hs_clear_row:
    addi $s0, $s0, 1
    j clear_hs_row
    
hs_clear_done:
    lw $s0, high_score
    
    li $t0, 100
    div $s0, $t0
    mflo $s1
    mfhi $t1
    
    li $t0, 10
    div $t1, $t0
    mflo $s0
    mfhi $s2
    
    move $a0, $s1
    li $a1, 27
    li $a2, 19
    jal draw_digit
    
    move $a0, $s0
    li $a1, 27
    li $a2, 23
    jal draw_digit
    
    move $a0, $s2
    li $a1, 27
    li $a2, 27
    jal draw_digit
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
draw_high_score_label:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $a0, WHITE

    li $a1, 9
    li $a2, 27
    jal draw_unit
    li $a1, 9
    li $a2, 28
    jal draw_unit
    li $a1, 9
    li $a2, 29
    jal draw_unit
    li $a1, 9
    li $a2, 30
    jal draw_unit
    li $a1, 9
    li $a2, 31
    jal draw_unit

    li $a1, 10
    li $a2, 29
    jal draw_unit
    
    li $a1, 11
    li $a2, 27
    jal draw_unit
    li $a1, 11
    li $a2, 28
    jal draw_unit
    li $a1, 11
    li $a2, 29
    jal draw_unit
    li $a1, 11
    li $a2, 30
    jal draw_unit
    li $a1, 11
    li $a2, 31
    jal draw_unit
    
    #S
    li $a1, 13
    li $a2, 27
    jal draw_unit
    li $a1, 14
    li $a2, 27
    jal draw_unit
    li $a1, 15
    li $a2, 27
    jal draw_unit
    
    li $a1, 13
    li $a2, 28
    jal draw_unit
    
    li $a1, 13
    li $a2, 29
    jal draw_unit
    li $a1, 14
    li $a2, 29
    jal draw_unit
    li $a1, 15
    li $a2, 29
    jal draw_unit
    
    li $a1, 15
    li $a2, 30
    jal draw_unit
    
    li $a1, 13
    li $a2, 31
    jal draw_unit
    li $a1, 14
    li $a2, 31
    jal draw_unit
    li $a1, 15
    li $a2, 31
    jal draw_unit
    
    # the column
    li $a1, 17
    li $a2, 28
    jal draw_unit
    li $a1, 17
    li $a2, 30
    jal draw_unit
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
#################################
