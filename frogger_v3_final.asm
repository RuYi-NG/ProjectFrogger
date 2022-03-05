#####################################################################
#
# CSC258H5S Fall 2021 Assembly Final Project
# University of Toronto, St. George
#
# Student: Joseph Yan, 1005839577
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 5
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Additional rows of water/road (Easy 1)
# 2. Display lives (Easy 2)
# 3. Rows move at different speed (Easy 3)
# 4. 2P mode (Hard 1)
# 5. Sound effect (Hard 2)
# Any additional information that the TA needs to know:
#  Changed from 8x8 pixel size to 4x4 for larger canvas space for extra features
#
#####################################################################

.data
	displayadress: .word 0x10008000
	
	border_teal: .word 0x7801E4 # colors
	black: .word 0x000000
	safe_purple: .word 0x7801E4
	water_blue : .word 0x020180
	road_grey: .word 0x9E9E9E
	goal_default: .word 0x444444
	goal_yellow: .word 0xF4F8BB
	frog_green: .word 0xA1DF50
	log_brown: .word 0xC56D56
	car_yellow: .word 0xE6E501
	Turt_green: .word 0x487053
	truck_grey: .word 0x7A7A7A

	P1ShapeInit: .word 14620,14636,14876,14880,14884,14888,14892,15136, 15140, 15144, 15388, 15392,15400, 15404, 15644, 15660 # p1 initial location
	P1Shape: .word 14620,14636,14876,14880,14884,14888,14892,15136, 15140, 15144, 15388, 15392,15400, 15404, 15644, 15660 # p1 current location
	
	P2ShapeInit: .word 14780,14796,15036,15040,15044,15048,15052,15296, 15300, 15304, 15548, 15552,15560, 15564, 15804, 15820
	P2Shape: .word 14780,14796,15036,15040,15044,15048,15052,15296, 15300, 15304, 15548, 15552,15560, 15564, 15804, 15820
	
	logShape: .space 1440 # object spaces
	TurtShape: .space 624 
	carShape: .space 528
	truckShape: .space 816
	
	markers: .word 0, 0, 0, 0, 0	# counters for collision and goals

.text
################
##### MAIN #####
################
	main:
		jal draw_Background
		jal draw_Lives
		jal draw_P1
		jal draw_Logs
		jal draw_Cars
		jal draw_Turts
		jal draw_Trucks
		j detect_keyboard_input

##########################
##### KEYBOARD INPUT #####
##########################
	detect_keyboard_input:
		lw $t8, 0xffff0000
 		beq $t8, 1, keyboard_respond	# check for keyboard
		j refresh			# refresh loop

	keyboard_respond:
		lw $t1, 0xffff0004
 		beq $t1, 0x77, respond_to_w 	# respond to different p1 movement
		beq $t1, 0x61, respond_to_a
 		beq $t1, 0x73, respond_to_s
 		beq $t1, 0x64, respond_to_d

		beq $t1, 0x69, respond_to_i	
 		beq $t1, 0x6a, respond_to_j
 		beq $t1, 0x6b, respond_to_k
 		beq $t1, 0x6c, respond_to_l

 	respond_to_w:
 		jal P1up
 		j refresh
 		
 	respond_to_a:
 		jal P1left
 		j refresh

 	respond_to_s:
 		jal P1down
 		j refresh
 		
 	respond_to_d:
 		jal P1right
 		j refresh
 		
 	respond_to_i:
 		jal P2up
 		j refresh
 	
 	respond_to_j:
 		jal P2left
 		j refresh
 	
 	respond_to_k:
 		jal P2down
 		j refresh
 	
 	respond_to_l:
 		jal P2right
 		j refresh

###################
##### REFRESH #####
###################
	refresh:
		jal draw_border

		jal shiftLogs		# shifts objects on refresh loop
		jal shiftCars
		jal shiftTurts
		jal shiftTrucks		

		jal draw_Water_and_Road		# paint over old objects

		jal paint_Logs		# paint shifted objects
		jal paint_Cars
		jal paint_Turts
		jal paint_Trucks

		jal draw_SafeArea	# repaint areas that frogs have been
		jal draw_GoalArea	

		jal P1Collision		# Detect Player collision
		jal P2Collision
		
		beq $t5, 1, P1_reset
		beq $t5, 1, P2_reset

	refreshFrog:
		jal draw_life_bar	# update life count
		jal draw_Lives
		jal shift_P1
		jal draw_P1
		jal draw_P2

		li $v0, 32
		li $a0 80
		syscall		

		j detect_keyboard_input
		
######################
##### INITIALIZE #####
######################

	draw_Background:		# draws non-objects
		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal draw_border
		jal draw_life_bar
		jal draw_SafeArea
		jal draw_GoalArea
		jal draw_Water_and_Road


		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

	draw_life_bar:
		lw $t0, displayadress
		lw $t1, black
		add $t2, $zero, $zero
		add $t3, $zero, $zero

		addi $t0, $t0, 520
		
	draw_life_bar_Loop:
		beq $t2, 60, draw_life_bar_End
		sw $t1, 0($t0)
		sw $t1, 256($t0)
		sw $t1, 512($t0)
		sw $t1, 768($t0)
		sw $t1, 1024($t0)
		addi $t2, $t2, 1
		addi $t0, $t0, 4
		j draw_life_bar_Loop
		
	draw_life_bar_End:
		jr $ra

	draw_border:
		lw $t0, displayadress
		lw $t1, border_teal

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		add $t2, $zero, $zero
		jal borderLeft

		addi $t0, $t0, 15872
		jal borderBottom

		addi $t0, $t0, 16376
		jal borderRight

		addi $t0, $t0, 252
		jal borderTop

		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

	borderLeft:
		beq $t2, 62, border_End
		sw $t1, 0($t0)
		sw $t1, 4($t0)
		addi $t0, $t0, 256
		addi $t2, $t2, 1
		j borderLeft

	borderBottom:
		beq $t2, 62, border_End
		sw $t1, 0($t0)
		sw $t1, 256($t0)
		addi $t0, $t0, 4
		addi $t2, $t2, 1
		j borderBottom

	borderRight:
		beq $t2, 62, border_End
		sw $t1, 0($t0)
		sw $t1, 4($t0)
		addi $t0, $t0, -256
		addi $t2, $t2, 1
		j borderRight

	borderTop:
		beq $t2, 62, border_End
		sw $t1, 0($t0)
		sw $t1, 256($t0)
		addi $t0, $t0, -4
		addi $t2, $t2, 1
		j borderTop

	border_End:
		add $t2, $zero, $zero
		lw $t0, displayadress
		jr $ra

	draw_SafeArea:
		lw $t0, displayadress
		addi $t0, $t0, 1800
		lw $t1, safe_purple
		add $t2, $zero, $zero

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal safeArea_Loop 


		lw $t0, displayadress
		addi $t0, $t0, 8200
		add $t2, $zero, $zero
		jal safeArea_Loop 

		lw $t0, displayadress
		addi $t0, $t0, 14600
		add $t2, $zero, $zero
		jal safeArea_Loop 

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	safeArea_Loop:
		beq $t2, 60, safeArea_End
		sw $t1, 0($t0)
		sw $t1, 256($t0)
		sw $t1, 512($t0)
		sw $t1, 768($t0)
		sw $t1, 1024($t0)
		addi $t2, $t2, 1
		addi $t0, $t0, 4
		j safeArea_Loop

	safeArea_End:
		jr $ra

	draw_GoalArea:
		lw $t0, displayadress
		addi $t0, $t0, 1820
		lw $t1, goal_default
		add $t2, $zero, $zero
		add $t3, $zero, $zero
		addi $t4, $zero, 4

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal draw_Goal_Loop

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	draw_Goal_Loop:
		beq $t2, 4, draw_Goal_End

	goalAreaTaken:
		lw $t5, markers($t4)
		addi $t4, $t4, 4
		beq $t5, 1, draw_TakenGoal
		j draw_Goal

	draw_TakenGoal:
		lw $t1, goal_yellow

	draw_Goal:
		beq $t3, 5, Goal_End
		sw $t1, 0($t0)
		sw $t1, 256($t0)
		sw $t1, 512($t0)
		sw $t1, 768($t0)
		sw $t1, 1024($t0)
		addi $t3, $t3, 1
		addi $t0, $t0, 4
		j draw_Goal

	Goal_End:
		addi $t2, $t2, 1
		add $t3, $zero, $zero
		lw $t1, goal_default
		addi $t0, $t0, 40
		j draw_Goal_Loop

	draw_Goal_End:
		jr $ra

	draw_Water_and_Road:
		lw $t0, displayadress
		addi $t0, $t0, 3080
		lw $t1, water_blue
		add $t2, $zero, $zero
		add $t3, $zero, $zero

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal water_and_Road_Loop 

		lw $t0, displayadress
		addi $t0, $t0, 9480
		lw $t1, road_grey
		add $t2, $zero, $zero
		add $t3, $zero, $zero
		jal water_and_Road_Loop 

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	water_and_Road_Loop:
		beq $t2, 20, water_and_Road_End

	water_and_RoadRow_Loop:
		beq $t3, 60, water_and_Road_Loop_End
		sw $t1, 0($t0)
		addi $t3, $t3, 1
		addi $t0, $t0, 4
		j water_and_RoadRow_Loop

	water_and_Road_Loop_End:
		addi $t0, $t0, 16
		add $t3, $zero, $zero
		addi $t2, $t2, 1
		j water_and_Road_Loop


	water_and_Road_End:
		jr $ra

#################
##### LIVES #####
#################
	draw_Lives:			# draws life
		lw $t0, displayadress
		lw $t1, frog_green
		addi $t2, $zero, 520
		add $t0, $t0, $t2
		addi $t0, $t0, -14620

		lw $t2, markers($zero)

		addi $t3, $zero, 3
		sub $t2, $t3, $t2
		add $t3, $zero, $zero

		add $t4, $zero, $zero
		
	draw_Lives_Loop:
		beq $t3, $t2, draw_Live_End
		
	draw_Life:
		beq $t4, 64, draw_Life_End
		lw $t5, P1ShapeInit($t4)
		addi $t4, $t4, 4
		add $t5, $t5, $t0
		sw $t1, 0($t5)
		j draw_Life

	draw_Life_End:
		add $t4, $zero, $zero
		addi $t3, $t3, 1
		addi $t0, $t0, 24
		j draw_Lives_Loop
		
	draw_Live_End:
		jr $ra


###################
##### PLAYERS #####
###################
	draw_P1:			# draws player
		lw $t0, displayadress
		lw $t1, frog_green
		la $t2, P1Shape
		add $t3, $zero, $zero

	draw_P1__Loop:
		beq $t3, 16, draw_P2
		lw $t4, 0($t2)
		add $t4, $t4, $t0
		sw $t1, 0($t4)
		addi $t3, $t3, 1
		addi $t2, $t2, 4
		j draw_P1__Loop
	
	draw_P2:
		lw $t0, displayadress
		lw $t1, frog_green
		la $t2, P2Shape
		add $t3, $zero, $zero

	draw_P2__Loop:
		beq $t3, 16, draw_Players_End
		lw $t4, 0($t2)
		add $t4, $t4, $t0
		sw $t1, 0($t4)
		addi $t3, $t3, 1
		addi $t2, $t2, 4
		j draw_P2__Loop

	draw_Players_End:
		jr $ra

################
##### LOGS #####
################
	draw_Logs:
		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal saveLogs	
		jal paint_Logs	

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	saveLogs:
		addi $t0, $zero, 3336
		add $t1, $zero, $zero
		addi $t2, $zero, 5
		add $t3, $zero, $zero
		add $t4, $zero, $zero

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal saveLogsRow	

		addi $t2, $zero, 15
		addi $t0, $t0, 24
		jal saveLogsRow	 	

		addi $t2, $zero, 15
		addi $t0, $t0, 20
		jal saveLogsRow		

		addi $t2, $zero, 10
		addi $t0, $t0, 16
		jal saveLogsRow		


		addi $t2, $zero, 15
		addi $t0, $zero, 5900
		jal saveLogsRow		

		addi $t2, $zero, 15
		addi $t0, $t0, 24
		jal saveLogsRow		

		addi $t2, $zero, 20
		addi $t0, $t0, 20
		jal saveLogsRow		

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	saveLogsRow:
		beq $t1, $t2, saveLogs_End	
		
	saveLogsCol:
		beq $t3, 4, saveLogsCol_End	
		sw $t0, logShape($t4)

		addi $t4, $t4, 4
		addi $t0, $t0, 256
		addi $t3, $t3, 1
		j saveLogsCol

	saveLogsCol_End:
		addi $t0, $t0, -1020	
		add $t3, $zero, $zero
		addi $t1, $t1, 1
		j saveLogsRow

	saveLogs_End:
		add $t1, $zero, $zero
		jr $ra

	paint_Logs:
		lw $t0, displayadress
		lw $t1, log_brown
		add $t2, $zero, $zero
		add $t3, $zero, $zero

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal paint_Logs_Loop

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	paint_Logs_Loop:
		beq $t2, 1440, paint_Logs_End
		lw $t3, logShape($t2)
		add $t3, $t0, $t3
		sw $t1, 0($t3)
		addi $t2, $t2, 4
		j paint_Logs_Loop

	paint_Logs_End:
		jr $ra

################
##### CARS #####
################
	draw_Cars:
		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal saveCars
		jal paint_Cars

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	saveCars:
		addi $t0, $zero, 10760
		add $t1, $zero, $zero
		add $t2, $zero, $zero
		add $t3, $zero, $zero
		add $t4, $zero, $zero

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal saveCarsRow 

		addi $t0, $t0, 52
		jal saveCarsRow

		addi $t0, $t0, 52
		jal saveCarsRow

		addi $t0, $zero, 13364
		jal saveCarsRow

		addi $t0, $t0, 56
		jal saveCarsRow

		addi $t0, $t0, 56
		jal saveCarsRow

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	saveCarsRow:
		beq $t1, 2, saveCarsHead_End
		
	saveCarsHeadCol_Loop:
		beq $t2, 4, saveCarsHeadCol_End
		sw $t0, carShape($t4)

		addi $t4, $t4, 4
		addi $t2, $t2, 1
		addi $t0, $t0, 256
		j saveCarsHeadCol_Loop

	saveCarsHeadCol_End:
		addi $t0, $t0, -1020
		add $t2, $zero, $zero
		addi $t1, $t1, 1
		j saveCarsRow

	saveCarsHead_End:
		addi $t0, $t0 256
		sw $t0, carShape($t4)

		addi $t4, $t4, 4
		addi $t0, $t0, 256
		sw $t0, carShape($t4)
		addi $t4, $t4, 4

		addi $t0, $t0, -508

	saveCarsTail_Loop:
		beq $t1, 5, saveCars_End
		
	saveCarsTailCol_Loop:
		beq $t2, 4, saveCarsTailCol_End
		sw $t0, carShape($t4)


		addi $t4, $t4, 4
		addi $t2, $t2, 1
		addi $t0, $t0, 256
		j saveCarsTailCol_Loop

	saveCarsTailCol_End:
		addi $t0, $t0, -1020
		add $t2, $zero, $zero
		addi $t1, $t1, 1
		j saveCarsTail_Loop

	saveCars_End:
		add $t1, $zero, $zero
		jr $ra

	paint_Cars:
		lw $t0, displayadress
		lw $t1, car_yellow
		add $t2, $zero, $zero
		add $t3, $zero, $zero
		add $t4, $zero, $zero

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal paint_Cars_Loop

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	paint_Cars_Loop:
		beq $t2, 6, paint_Cars_End

	paint_Car:
		beq $t3, 88, paint_Car_End
		lw $t5, carShape($t4)
		add $t0, $t0, $t5
		sw $t1, 0($t0)
		lw $t0, displayadress
		addi $t3, $t3, 8
		addi $t4, $t4, 8
		j paint_Cars_Loop

	paint_Car_End:

		addi $t2, $t2, 1
		add $t3, $zero, $zero
		j paint_Cars_Loop

	paint_Cars_End:
		jr $ra

###################
##### TURTLES #####
###################

	draw_Turts:
		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal saveTurts
		jal paint_Turts

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	saveTurts:
		addi $t0, $zero, 4624
		add $t1, $zero, $zero
		add $t2, $zero, $zero
		add $t3, $zero, $zero
		add $t4, $zero, $zero

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal saveTurts_Loop

		addi $t0, $zero, 4744
		jal saveTurts_Loop

		addi $t0, $zero, 7244
		jal saveTurts_Loop

		addi $t0, $zero, 7364
		jal saveTurts_Loop

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	saveTurts_Loop:
		beq $t1, 3, saveTurts_End
		
	saveTurt:
		beq $t2, 3, saveTurt_End
		
	saveTurtCol:
		beq $t3, 3, saveTurtCol_End
		sw $t0, TurtShape($t4)

		addi $t4, $t4, 4
		addi $t3, $t3, 1
		addi $t0, $t0, 256
		j saveTurtCol

	saveTurtCol_End:
		add $t3, $zero, $zero
		addi $t2, $t2, 1
		addi $t0, $t0, -764
		j saveTurt

	saveTurt_End:
		add $t2, $zero, $zero

		addi $t0, $t0, -256
		sw $t0, TurtShape($t4)
		addi $t4, $t4, 4

		addi $t0, $t0, -16
		sw $t0, TurtShape($t4)
		addi $t4, $t4, 4

		addi $t0, $t0, 1024
		sw $t0, TurtShape($t4)
		addi $t4, $t4, 4

		addi $t0, $t0, 16
		sw $t0, TurtShape($t4)
		addi $t4, $t4, 4

		addi $t0, $t0, -760
		addi $t1, $t1, 1
		j saveTurts_Loop
		
	saveTurts_End:
		add $t1, $zero, $zero
		jr $ra

	paint_Turts:
		lw $t0, displayadress
		lw $t1, Turt_green
		add $t2, $zero, $zero
		add $t3, $zero, $zero

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal paint_Turts_Loop

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	paint_Turts_Loop:
		beq $t2, 624, paint_Logs_End
		lw $t3, TurtShape($t2)
		add $t3, $t0, $t3
		sw $t1, 0($t3)
		addi $t2, $t2, 4
		j paint_Turts_Loop

	paint_Turts_End:
		jr $ra

##################
##### TRUCKS #####
##################

	draw_Trucks:
		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal saveTrucks
		jal paint_Trucks

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	saveTrucks:
		addi $t0, $zero, 9480
		add $t1, $zero, $zero
		add $t2, $zero, $zero
		add $t3, $zero, $zero
		add $t4, $zero, $zero

		addi $sp, $sp, -4
		sw $ra, 0($sp)

		jal saveTruckTail

		addi $t0, $t0, 72
		jal saveTruckTail

		add $t0, $zero, 12088
		jal saveTruckTail

		addi $t0, $t0, 72
		jal saveTruckTail

		lw $ra, 0($sp)
		addi $sp, $sp, 4

		jr $ra

	saveTruckTail:
		beq $t2, 6, saveTruckTail_End
		
	saveTruckTailCol:
		beq $t3, 5, saveTruckTailCol_End
		sw $t0, truckShape($t4)
		addi $t4, $t4, 4
		addi $t0, $t0, 256
		addi $t3, $t3, 1
		j saveTruckTailCol

	saveTruckTailCol_End:
		addi $t2, $t2, 1
		add $t3, $zero, $zero
		addi $t0, $t0, -1276
		j saveTruckTail

	saveTruckTail_End:
		addi $t0, $t0, 256

	saveTruckLink:
		beq $t3, 3, saveTruckLink_End
		sw $t0, truckShape($t4)
		addi $t4, $t4, 4
		addi $t0, $t0, 256
		addi $t3, $t3, 1
		j saveTruckLink

	saveTruckLink_End:
		add $t3, $zero, $zero
		addi $t0, $t0, -1020

	saveTruckHead:
		beq $t2, 9, saveTruckHead_End
		
	saveTruckHeadCol:
		beq $t3, 5, saveTruckHeadCol_End
		sw $t0, truckShape($t4)
		addi $t4, $t4, 4
		addi $t0, $t0, 256
		addi $t3, $t3, 1
		j saveTruckHeadCol

	saveTruckHeadCol_End:
		addi $t2, $t2, 1
		add $t3, $zero, $zero
		addi $t0, $t0, -1276
		j saveTruckHead

	saveTruckHead_End:
		addi $t0, $t0, 256
		add $t3, $zero, $zero
		
	saveTruckTip:
		beq $t3, 3, saveTruck_End
		sw $t0, truckShape($t4)
		addi $t4, $t4, 4
		addi $t0, $t0, 256
		addi $t3, $t3, 1
		j saveTruckTip

	saveTruck_End:
		add $t1, $zero, $zero
		add $t2, $zero, $zero
		add $t3, $zero, $zero
		addi $t0, $t0, -1020
		jr $ra

	paint_Trucks:
		lw $t0, displayadress
		lw $t1, truck_grey
		add $t2, $zero, $zero
		add $t3, $zero, $zero

	paint_Trucks_Loop:
		beq $t2, 816, paint_Trucks_End
		lw $t3, truckShape($t2)
		add $t3, $t3, $t0
		sw $t1, 0($t3)
		addi $t2, $t2, 4
		addi $t4, $t4, 4
		j paint_Trucks_Loop

	paint_Trucks_End:
		jr $ra

####################
##### SHIFTING #####
####################

	shiftLogs:
		add $t0, $zero, $zero
		add $t1, $zero, $zero
		addi $t2, $zero, 256

	shiftLogs_Loop:
		beq $t1, 1440, shiftLogs_End
		lw $t0, logShape($t1)

		rem $t3, $t0, $t2
		
	shiftLogsRem:
		beq $t3, 244, shiftLogsOver

		addi $t0, $t0, 4
		sw $t0, logShape($t1)

		addi $t1, $t1, 4
		j shiftLogs_Loop
		
	shiftLogsOver:
		addi $t0, $t0, -236
		sw $t0, logShape($t1)

		addi $t1, $t1, 4
		j shiftLogs_Loop

	shiftLogs_End:
		jr $ra

	shiftCars:
		add $t0, $zero, $zero
		add $t1, $zero, $zero
		addi $t2, $zero, 256

	shiftCars_Loop:
		beq $t1, 528, shiftLogs_End
		lw $t0, carShape($t1)

		rem $t3, $t0, $t2
		
	shiftCarsRem:
		beq $t3, 8, shiftCarsOver

		addi $t0, $t0, -4
		sw $t0, carShape($t1)

		addi $t1, $t1, 4
		j shiftCars_Loop

	shiftCarsOver:
		addi $t0, $t0, 236
		sw $t0, carShape($t1)

		addi $t1, $t1, 4
		j shiftCars_Loop

	shiftCars_End:
		jr $ra

	shiftTurts:
		add $t0, $zero, $zero
		add $t1, $zero, $zero
		addi $t2, $zero, 256

	shiftTurts_Loop:
		beq $t1, 624, shiftTurts_End
		lw $t0, TurtShape($t1)

		rem $t3, $t0, $t2
		
	shiftTurtsRem:
		beq $t3, 8, shiftTurtsOver

		addi $t0, $t0, -4
		sw $t0, TurtShape($t1)

		addi $t1, $t1, 4
		j shiftTurts_Loop

	shiftTurtsOver:
		addi $t0, $t0, 236
		sw $t0, TurtShape($t1)

		addi $t1, $t1, 4
		j shiftTurts_Loop
		
	shiftTurts_End:
		jr $ra

	shiftTrucks:
		add $t0, $zero, $zero
		add $t1, $zero, $zero
		addi $t2, $zero, 256

	shiftTrucks_Loop:
		beq $t1, 816, shiftTrucks_End
		lw $t0, truckShape($t1)

		rem $t3, $t0, $t2
		
	shiftTrucksRem:
		beq $t3, 244, shiftTrucksOver

		addi $t0, $t0, 4
		sw $t0, truckShape($t1)

		addi $t1, $t1, 4
		j shiftTrucks_Loop
		
	shiftTrucksOver:
		addi $t0, $t0, -236
		sw $t0, truckShape($t1)

		addi $t1, $t1, 4
		j shiftTrucks_Loop

	shiftTrucks_End:
		jr $ra

###########################
##### PLAYER MOVEMENT #####
###########################

	P1left:					# player movements reflected on relocating frogs
		lw $t0, P1Shape($zero)
		add $t2, $zero, $zero
		
	P1Left_Loop:
		beq $t2, 64, P1Left_End
		lw $t0, P1Shape($t2)
		addi $t0, $t0, -20

		sw $t0, P1Shape($t2)
		addi $t2, $t2, 4
		j P1Left_Loop
		
	P1Left_End:
		li $v0, 31 
		la $a0, 20
		la $a1, 500
		la $a2, 30
		la $a3, 100
		syscall 
		jr $ra
		
	P2left:
		lw $t0, P2Shape($zero)
		add $t2, $zero, $zero
		
	P2Left_Loop:
		beq $t2, 64, P2Left_End
		lw $t0, P2Shape($t2)
		addi $t0, $t0, -20

		sw $t0, P2Shape($t2)
		addi $t2, $t2, 4
		j P2Left_Loop
		
	P2Left_End:
		li $v0, 31 
		la $a0, 20
		la $a1, 500
		la $a2, 30
		la $a3, 100
		syscall 
		jr $ra

	P1right:
		lw $t0, P1Shape($zero)
		add $t2, $zero, $zero
		
	P1right_Loop:
		beq $t2, 64, P1right_End
		lw $t0, P1Shape($t2)

		addi $t0, $t0, 20

		sw $t0, P1Shape($t2)
		addi $t2, $t2, 4
		j P1right_Loop
		
	P1right_End:
		li $v0, 31 
		la $a0, 20
		la $a1, 500
		la $a2, 30
		la $a3, 100
		syscall 
		jr $ra
		
	P2right:
		lw $t0, P2Shape($zero)
		add $t2, $zero, $zero
		
	P2right_Loop:
		beq $t2, 64, P2right_End
		lw $t0, P2Shape($t2)

		addi $t0, $t0, 20

		sw $t0, P2Shape($t2)
		addi $t2, $t2, 4
		j P2right_Loop
		
	P2right_End:
		li $v0, 31 
		la $a0, 20
		la $a1, 500
		la $a2, 30
		la $a3, 100
		syscall 	
		jr $ra

	P1up:
		lw $t0, P1Shape($zero)
		add $t2, $zero, $zero
		
	P1up_Loop:
		beq $t2, 64, P1up_End
		lw $t0, P1Shape($t2)

		addi $t0, $t0, -1280

		sw $t0, P1Shape($t2)
		addi $t2, $t2, 4
		j P1up_Loop
		
	P1up_End:
		li $v0, 31 
		la $a0, 20
		la $a1, 500
		la $a2, 30
		la $a3, 100
		syscall 
		jr $ra

	P2up:
		lw $t0, P2Shape($zero)
		add $t2, $zero, $zero
		
	P2up_Loop:
		beq $t2, 64, P2up_End
		lw $t0, P2Shape($t2)

		addi $t0, $t0, -1280

		sw $t0, P2Shape($t2)
		addi $t2, $t2, 4
		j P2up_Loop
		
	P2up_End:
		li $v0, 31 
		la $a0, 20
		la $a1, 500
		la $a2, 30
		la $a3, 100
		syscall 
		jr $ra
		
	P1down:
		lw $t0, P1Shape($zero)
		add $t2, $zero, $zero
		
	P1down_Loop:
		beq $t2, 64, P1down_End
		lw $t0, P1Shape($t2)

		addi $t0, $t0, 1280

		sw $t0, P1Shape($t2)
		addi $t2, $t2, 4
		j P1down_Loop
		
	P1down_End:
		li $v0, 31 
		la $a0, 20
		la $a1, 500
		la $a2, 30
		la $a3, 100
		syscall 
		jr $ra
		
	P2down:
		lw $t0, P2Shape($zero)
		add $t2, $zero, $zero
		
	P2down_Loop:
		beq $t2, 64, P2down_End
		lw $t0, P2Shape($t2)

		addi $t0, $t0, 1280

		sw $t0, P2Shape($t2)
		addi $t2, $t2, 4
		j P2down_Loop
		
	P2down_End:
		li $v0, 31 
		la $a0, 20
		la $a1, 500
		la $a2, 30
		la $a3, 100
		syscall 
		jr $ra

######################
##### COLLISIONS #####
######################
	P1Collision:				# check for different collision conditions and regions
		lw $t0, P1Shape($zero)
		j P1OverStartArea
	
	P2Collision:
		lw $t9, P2Shape($zero)
		j P2OverStartArea
		
	P1OverStartArea:
		slti $t2, $t0, 14592
		beq $t2, 1, P1BelowSafeArea
		j frogNotDead
		
	P2OverStartArea:
		slti $t2, $t9, 14592
		beq $t2, 1, P2BelowSafeArea
		j frogNotDead
		
	P1BelowSafeArea:
		sgt, $t2, $t0, 9468
		beq $t2, 1, P1RoadCollision
		j P1OverMidArea
		
	P2BelowSafeArea:
		sgt, $t2, $t9, 9468
		beq $t2, 1, P2RoadCollision
		j P2OverMidArea
		
	P1OverMidArea:
		slti $t2, $t0, 8200
		beq $t2, 1, P1BelowGoalArea
		j frogNotDead
		
	P2OverMidArea:
		slti $t2, $t9, 8200
		beq $t2, 1, P2BelowGoalArea
		j frogNotDead
		
	P1BelowGoalArea:
		sgt, $t2, $t0, 3060
		beq $t2, 1, P1WaterCollision
		j P1GoalCollision
		
	P2BelowGoalArea:
		sgt, $t2, $t9, 3060
		beq $t2, 1, P2WaterCollision
		j P2GoalCollision

	P1RoadCollision:
		lw $t0, displayadress
		lw $t1, P1Shape($zero)
		lw $t2, road_grey
		add $t3, $zero, $zero
		add $t0, $t0, $t1
		
	P1RoadCollision_Loop:
		beq $t3, 5, frogNotDead
		lw $t4, 0($t0)
		bne $t2, $t4, P1Dead
		addi $t3, $t3, 1
		addi $t0, $t0, 4
		j P1RoadCollision_Loop

	P2RoadCollision:
		lw $t0, displayadress
		lw $t9, P2Shape($zero)
		lw $t2, road_grey
		add $t3, $zero, $zero
		add $t0, $t0, $t9
		
	P2RoadCollision_Loop:
		beq $t3, 5, frogNotDead
		lw $t4, 0($t0)
		bne $t2, $t4, P2Dead
		addi $t3, $t3, 1
		addi $t0, $t0, 4
		j P2RoadCollision_Loop

	P1WaterCollision:
		lw $t0, displayadress
		addi $t0, $t0, 260
		lw $t1, P1Shape($zero)
		lw $t2, water_blue
		add $t0, $t0, $t1
		add $t3, $zero, $zero
		add $t5, $zero, $zero

	P1WaterCollision_Loop:
		beq $t3, 5, P1_countWater
		lw $t4, 0($t0)
		beq $t2, $t4, P1_addWater
		addi $t3, $t3, 1
		addi $t0, $t0, 4
		j P1WaterCollision_Loop
		
	P2WaterCollision:
		lw $t0, displayadress
		addi $t0, $t0, 260
		lw $t9, P2Shape($zero)
		lw $t2, water_blue
		add $t0, $t0, $t9
		add $t3, $zero, $zero
		add $t5, $zero, $zero

	P2WaterCollision_Loop:
		beq $t3, 5, P2_countWater
		lw $t4, 0($t0)
		beq $t2, $t4, P2_addWater
		addi $t3, $t3, 1
		addi $t0, $t0, 4
		j P2WaterCollision_Loop

	P1_addWater:
		addi $t5, $t5, 1
		addi $t3, $t3, 1
		addi $t0, $t0, 4
		j P1WaterCollision_Loop
	
	P2_addWater:
		addi $t5, $t5, 1
		addi $t3, $t3, 1
		addi $t0, $t0, 4
		j P2WaterCollision_Loop
		
	P1_countWater:
		slti, $t5, $t5, 3
		beq $t5, 1, frogNotDead
		j P1Dead
	
	P2_countWater:
		slti, $t5, $t5, 3
		beq $t5, 1, frogNotDead
		j P2Dead

	P1GoalCollision:
		lw $t0, displayadress
		lw $t1, P1Shape($zero)
		lw $t2, safe_purple
		add $t3, $zero, $zero
		add $t0, $t0, $t1
		add $t5, $zero, $zero

	P1GoalCollision_Loop:
		beq $t3, 5, P1_countGoal
		lw $t4, 0($t0)
		beq $t4, $t2, P1_addGoal
		addi $t3, $t3, 1
		addi $t0, $t0, 4
		j P1GoalCollision_Loop

	P2GoalCollision:
		lw $t0, displayadress
		lw $t9, P2Shape($zero)
		lw $t2, safe_purple
		add $t3, $zero, $zero
		add $t0, $t0, $t9
		add $t5, $zero, $zero

	P2GoalCollision_Loop:
		beq $t3, 5, P2_countGoal
		lw $t4, 0($t0)
		beq $t4, $t2, P2_addGoal
		addi $t3, $t3, 1
		addi $t0, $t0, 4
		j P2GoalCollision_Loop
	
	P1_addGoal:
		addi $t5, $t5, 1
		addi $t3, $t3, 1
		j P1GoalCollision_Loop
		
	P2_addGoal:
		addi $t5, $t5, 1
		addi $t3, $t3, 1
		j P2GoalCollision_Loop
		
	P1_countGoal:
		slti, $t5, $t5, 3
		beq, $t5, 1, frogGoalOccupied
		j P1Dead
		
	P2_countGoal:
		slti, $t5, $t5, 3
		beq, $t5, 1, frogGoalOccupied
		j P2Dead

	frogGoalOccupied:
		addi $t6, $zero, 1
		lw $t1, P1Shape($zero)
		lw $t9, P2Shape($zero)

	frogFirstGoal:
		beq $t1, 1820, P1_FirstChange
		beq $t9, 1820, P2_FirstChange
		
	frogSecondGoal:
		beq $t1, 1880, P1_SecondChange
		beq $t9, 1880, P2_SecondChange
		
	frogThirdGoal:
		beq $t1, 1940, P1_ThirdChange
		beq $t9, 1940, P2_ThirdChange
		
	frogFourthGoal:
		beq $t1, 2000, P1_FourthChange
		beq $t9, 2000, P2_FourthChange
		
	P1_FirstChange:
		addi $t7, $zero, 4
		j P1_GoalTaken
		
	P1_SecondChange:
		addi $t7, $zero, 8
		j P1_GoalTaken
		
	P1_ThirdChange:
		addi $t7, $zero, 12
		j P1_GoalTaken
		
	P1_FourthChange:
		addi $t7, $zero, 16
		j P1_GoalTaken
	
	P2_FirstChange:
		addi $t7, $zero, 4
		j P2_GoalTaken
		
	P2_SecondChange:
		addi $t7, $zero, 8
		j P2_GoalTaken
		
	P2_ThirdChange:
		addi $t7, $zero, 12
		j P2_GoalTaken
		
	P2_FourthChange:
		addi $t7, $zero, 16
		j P2_GoalTaken
		
	P1_GoalTaken:
		sw $t6, markers($t7)
		li $v0, 31 
		la $a0, 0
		la $a1, 500
		la $a2, 30
		la $a3, 80
		syscall
		j P1_reset
		
	P2_GoalTaken:
		sw $t6, markers($t7)
		li $v0, 31 
		la $a0, 0
		la $a1, 500
		la $a2, 30
		la $a3, 80
		syscall
		j P2_reset
		
#######################
##### FROG STATUS #####
#######################
	P1Dead:
		addi $t5, $zero, 1
		lw $t7, markers($zero)
		addi $t7, $t7, 1
		sw $t7, markers($zero)
		li $v0, 31 
		la $a0, 60
		la $a1, 500
		la $a2, 50
		la $a3, 80
		syscall 
		beq $t7, 3, Exit
		j P1_reset
		jr $ra
		
	P2Dead:	addi $t5, $zero, 1
		lw $t7, markers($zero)
		addi $t7, $t7, 1
		sw $t7, markers($zero)
		li $v0, 31 
		la $a0, 60
		la $a1, 500
		la $a2, 50
		la $a3, 80
		syscall 
		beq $t7, 3, Exit
		j P2_reset
		jr $ra
		
	frogNotDead:
		add $t5, $zero, $zero
		jr $ra


#################
##### RESET #####
#################
	P1_reset:			# resets players to starting location when reaching goal or upon dying
		add $t1, $zero, $zero
		
	P1_reset_Loop:
		beq $t1, 64, P1_reset_End
		lw $t2, P1ShapeInit($t1)
		sw $t2, P1Shape($t1)
		addi $t1, $t1, 4
		j P1_reset_Loop
		
	P1_reset_End:
		j refreshFrog
		
	P2_reset:
		add $t9, $zero, $zero
		
	P2_reset_Loop:
		beq $t9, 64, P2_reset_End
		lw $t2, P2ShapeInit($t9)
		sw $t2, P2Shape($t9)
		addi $t9, $t9, 4
		j P2_reset_Loop
		
	P2_reset_End:
		j refreshFrog

######################
##### FROG SHIFT #####
######################
					# log and turtle shift that carries players
	shift_P1:
		lw $t0, P1Shape($zero)
		
	P1_OverMid:
		slti $t2, $t0, 8200
		beq $t2, 1, P1_on_Water
		jr $ra
	
		
	P1_on_Water:
		sgt, $t2, $t0, 3060
		beq $t2, 1, P1_on_logOrTurt
		jr $ra

	P1_on_logOrTurt:
		addi $t2, $zero, 256
		div $t0, $t2
		mflo $t3

	P1_on_log1:
		beq $t3, 12, P1_moveWithLog
	P1_on_Turt1:
		beq $t3, 17, P1_moveWithTurt
	P1_on_log2:
		beq $t3, 22, P1_moveWithLog
	P1_on_Turt2:
		beq $t3, 27, P1_moveWithTurt

	P1_moveWithLog:
		add $t2, $zero, $zero
		
	P1_moveWithLog_Loop:
		beq $t2, 64, shift_P1_End
		lw $t3, P1Shape($t2)
		addi $t3, $t3, 4
		sw $t3, P1Shape($t2)
		addi $t2, $t2, 4
		j P1_moveWithLog_Loop
		
	P1_moveWithTurt:
		add $t2, $zero, $zero
		
	P1_moveWithTurt_Loop:
		beq $t2, 64, shift_P1_End
		lw $t3, P1Shape($t2)
		addi $t3, $t3, -4
		sw $t3, P1Shape($t2)
		addi $t2, $t2, 4
		j P1_moveWithTurt_Loop
		
	shift_P1_End:
		jr $ra
#######################
##### EXIT ############
#######################
	Exit:		
		li $v0, 31 
		la $a0, 70
		la $a1, 750
		la $a2, 10
		la $a3, 70
		syscall
		li $v0, 32
		li $a0 17
		syscall
