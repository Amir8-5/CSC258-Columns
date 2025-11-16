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

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    jal clear_screen
    jal draw_walls
    
    li $v0, 10
    syscall

clear_screen:
li $t0, 0x10008000
li $t1, 0
li $t2, 1024
clear_loop:
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, -1
    bnez $t2, clear_loop
    jr $ra

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


game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop
