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

.extern _clobbered_reti;
.type _clobbered_reti,STT_OBJECT;

.align 2
.global __scheduler_switch;
.type __scheduler_switch, STT_FUNC;
__scheduler_switch:
	[--SP] = R0;
	[--SP] = P0;

	//make sure we return to the right spot
	P0.H = _clobbered_reti;
	P0.L = _clobbered_reti;
	R0 = [P0];

	RETS = R0;

	P0 = [SP++];
	R0 = [SP++];

	LINK 0;
	SAVE_CONTEXT;

	//CLI R7;

scheduler_start:
	//get the highest priority task
	P1.H = _active_tasks;
	P1.L = _active_tasks;
	R0 = [P1];
	R2 = R0;
	[--SP] = P1;

	CALL ___clzsi2;

	R1 = 31 (X);
	R0 = R1 - R0;
	P0 = R0;

	R1 = 3 (X);
	R1 <<= R0;
	R0 = R2 | R1;

	//mark the task as begun
	P1 = [SP++];
	[P1] = R0;

	//call the task function
	.extern _scheduler_tasks;
	.type _scheduler_tasks,STT_OBJECT;
	P1.H = _scheduler_tasks;
	P1.L = _scheduler_tasks;
	P1 = P1 + (P0 << 1);
	P0 = [P1];

	//STI R7;

	CALL (P0);

	//CLI R7;

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
	R3 = R0;

	CC = R0 == 0x0;
	IF CC JUMP(task_exit);
	CSYNC;

	//mask off tasks that are already begun
	R2.H = HI(SCHEDULER_RUNNING_MASK);
	R2.L = LO(SCHEDULER_RUNNING_MASK);
	R0 = R0 & R2;

	CALL ___clzsi2;

	//get the highest priority task that has already begun
	R1 = 32 (X);
	R0 = R1 - R0;

	R2.H = 0xFFFF;
	R2.L = 0xFFFF;

	R2 <<= R0;
	//mask highest prio running task and everything below
	R0 = R3 & R2;

	//a middle priority task has been added and needs to run
	CC = R0 == 0x0;
	IF CC JUMP(task_exit);

	JUMP (scheduler_start);
	CSYNC;

task_exit:
	//STI R7;

	RESTORE_CONTEXT;
 	UNLINK;
	RTS;







