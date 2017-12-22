/*
 * context.S
 *
 *  Created on: Dec 21, 2017
 *      Author: deanm
 */


#ifndef __ASSEMBLY__
#define __ASSEMBLY__
#endif

#include <bf706_device.h>
#include "scheduler.h"

#define SAVE_CONTEXT \
	[--sp] = ( R7:0, P5:0 ); \
	\
	[--sp] = i0; \
	[--sp] = i1; \
	[--sp] = i2; \
	[--sp] = i3; \
	\
	[--sp] = m0; \
	[--sp] = m1; \
	[--sp] = m2; \
	[--sp] = m3; \
	\
	[--sp] = l0; \
	[--sp] = l1; \
	[--sp] = l2; \
	[--sp] = l3; \
	\
	[--sp] = b0; \
	[--sp] = b1; \
	[--sp] = b2; \
	[--sp] = b3; \
	[--sp] = a0.x; \
	[--sp] = a0.w; \
	[--sp] = a1.x; \
	[--sp] = a1.w; \
	\
	[--sp] = LC0; \
	[--sp] = LC1; \
	[--sp] = LT0; \
	[--sp] = LT1; \
	[--sp] = LB0; \
	[--sp] = LB1; \
	\
	[--sp] = ASTAT; \
	[--sp] = SEQSTAT; \
	[--sp] = SYSCFG

#define RESTORE_CONTEXT \
	SYSCFG = [sp++]; \
	SEQSTAT = [sp++]; \
	ASTAT = [sp++]; \
	 \
	LB1 = [sp++]; \
	LB0 = [sp++]; \
	LT1 = [sp++]; \
	LT0 = [sp++]; \
	LC1 = [sp++]; \
	LC0 = [sp++]; \
	 \
	a1.w = [sp++]; \
	a1.x = [sp++]; \
	a0.w = [sp++]; \
	a0.x = [sp++]; \
	b3 = [sp++]; \
	b2 = [sp++]; \
	b1 = [sp++]; \
	b0 = [sp++]; \
	 \
	l3 = [sp++]; \
	l2 = [sp++]; \
	l1 = [sp++]; \
	l0 = [sp++]; \
	 \
	m3 = [sp++]; \
	m2 = [sp++]; \
	m1 = [sp++]; \
	m0 = [sp++]; \
	 \
	i3 = [sp++]; \
	i2 = [sp++]; \
	i1 = [sp++]; \
	i0 = [sp++]; \
	 \
	( R7 : 0, P5 : 0) = [ SP ++ ]

.global ___clzsi2;

.extern _active_tasks;
.type _active_tasks,STT_OBJECT;

.align 2
.global __scheduler_switch;
.type __scheduler_switch, STT_FUNC;
__scheduler_switch:
	LINK 0;
	[--SP] = R7;
	CLI R7; //disable all interrupts
	SAVE_CONTEXT;

	//get the highest priority task
	P0.H = _active_tasks;
	P0.L = _active_tasks;
	R0 = [P0];

	CALL ___clzsi2;

	R1 = 30 (X);
	R0 = R1 - R0;
	P0 = R0;

	//call the task function
	.extern _scheduler_tasks;
	.type _scheduler_tasks,STT_OBJECT;
	P1.H = _scheduler_tasks;
	P1.L = _scheduler_tasks;
	P1 = P1 + (P0 << 1);
	P0 = [P1];

	CALL (P0);

	//clear the flags for this task

	//get the highest priority task
	P0.H = _active_tasks;
	P0.L = _active_tasks;
	R0 = [P0];
    R3 = R0;

	CALL ___clzsi2;

	R1 = 30 (X);
	R2 = R1 - R0; //bit number of the highest priority task

	R1 = 3 (X);
	R1 <<= R2; //2 bits corresponding to the task

	R2.H = 0xFFFF;
	R2.L = 0xFFFF;

	R2 = R1 ^ R2; //clear the 2 bits
	R0 = R2 & R3; //or the result with the original value
	[P0] = R0; //clear both the active and running bits in the highest priority task

	//raise the interrupt to call the scheduler
	P0.H = HI(REG_SEC_Global_SEC0_RAISE);
	P0.L = LO(REG_SEC_Global_SEC0_RAISE);
	R0.H = 0;
	R0.L = SCHEDULER_IRQ_Num;
	[P0] = R0;

	RESTORE_CONTEXT;
	STI R7; //re-enable interrupts
	R7 = [SP++];
 	UNLINK;
 	RTS;








