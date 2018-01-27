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
	R0 = RETI; \
	[--sp] = R0; \
	[--sp] = fp; \
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
\
	[--sp] = RETS; \
	[--sp] = SEQSTAT; \
	[--sp] = SYSCFG; \

#define RESTORE_CONTEXT \
	SYSCFG = [sp++]; \
	SEQSTAT = [sp++]; \
	RETS = [sp++]; \
\
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
	fp = [sp++]; \
	R0 = [sp++]; \
	RETI = R0; \
\
	( R7 : 0, P5 : 0) = [ SP ++ ];

.global ___clzsi2;

.align 2
.global __scheduler_setup;
.type __scheduler_setup, STT_FUNC;
__scheduler_setup:
	LINK 0;
	[--SP] = P0;
	[--SP] = R1;

	//Set handler for IVG15
	P0.H = HI(REG_ICU_EVT13);
	P0.L = LO(REG_ICU_EVT13);
	R1.L = __scheduler_dispatch
	R1.H = __scheduler_dispatch
	[P0] = R1;

	//Set handler for IVG15
	P0.H = HI(REG_ICU_EVT14);
	P0.L = LO(REG_ICU_EVT14);
	R1.L = __scheduler_start
	R1.H = __scheduler_start
	[P0] = R1;

	R1 = [SP++];
	P0 = [SP++];
	UNLINK;
	RTS;

.align 2
.global __scheduler_dispatch;
.type __scheduler_dispatch, STT_FUNC;
__scheduler_dispatch:

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
	IF CC JUMP(task_resume);
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
	IF CC JUMP(task_resume);

	JUMP (task_start);
	CSYNC;

task_resume:
	RESTORE_CONTEXT;
	RTI;

.extern _active_tasks;
.type _active_tasks,STT_OBJECT;

.align 2
.global __scheduler_start;
.type __scheduler_start, STT_FUNC;
__scheduler_start:

	SAVE_CONTEXT;

task_start:

	//get the highest priority task
	P1.H = _active_tasks;
	P1.L = _active_tasks;
	R0 = [P1];
	R1 = R0;
	R2.H = HI(SCHEDULER_ACTIVE_MASK);
	R2.L = LO(SCHEDULER_ACTIVE_MASK);
	R0 = R0 & R2;
	[--SP] = R1;

	CALL ___clzsi2;

	R3 = 31 (X);
	R0 = R3 - R0;
	P0 = R0;

	R3 = 3 (X);
	R3 <<= R0;
	R1 = [SP++];

	R2 = R3 & R1;
	R2 >>= R0;
	CC = R2 == 0x3;
	IF CC JUMP(task_resume);

	R1 = R3 | R1;

	//mark the task as begun
	P1.H = _active_tasks;
	P1.L = _active_tasks;
	[P1] = R1;

	//get the task function
	.extern _scheduler_tasks;
	.type _scheduler_tasks,STT_OBJECT;
	P1.H = _scheduler_tasks;
	P1.L = _scheduler_tasks;
	P1 = P1 + (P0 << 1);
	R0 = [P1];

	//set RETI to new task
	RETI = R0;

	R0.H = _scheduler_end;
	R0.L = _scheduler_end;

	RETS = R0;

	RTI;


.align 2
.global _scheduler_end;
.type _scheduler_end, STT_FUNC;
_scheduler_end:
	RAISE 13;
	IDLE;
	CSYNC;






