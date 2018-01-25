/*
 * scheduler.cpp
 *
 *  Created on: Dec 20, 2017
 *      Author: Dean
 */

#include "scheduler.h"

volatile uint32_t active_tasks;
volatile void (*scheduler_tasks[SCHEDULER_MAX_TASKS])( void );

extern "C" {
extern void _scheduler_setup( void );
};

bool Scheduler::begin()
{
	_scheduler_setup();

	disableIRQ(SCHEDULER_IRQ_Num);
	setIRQPriority(SCHEDULER_IRQ_Num, 0); //Lowest priority
	enableIRQ(SCHEDULER_IRQ_Num);

	active_tasks = 0;

	for(int i=0; i<SCHEDULER_MAX_TASKS; i++) scheduler_tasks[i] = NULL;

	return true;
}

bool Scheduler::addTask(void (*fn)(void), uint8_t prio)
{
	SCHEDULER_CRIT_ENTRY;
	//make this prio level isn't already taken
	if(active_tasks & (SCHEDULER_TASK_ACTIVE << (prio << 1))){
		__asm__ volatile("EMUEXCPT;");
		return SCHEDULER_ERR_DUPLICATE_PRIO;
	}
	else{
		active_tasks |= (SCHEDULER_TASK_ACTIVE << (prio << 1));
		scheduler_tasks[prio] = (volatile void(*)(void))fn;
	}
	raiseIRQ(SCHEDULER_IRQ_Num);
	SCHEDULER_CRIT_EXIT;
	__asm__ volatile("IDLE");
	return 0;
}

#if 0

extern "C" {

//extern void _scheduler_switch( void );

int SCHEDULER_Handler( int IQR_NUM )
{
#if 0
	//find the highest priority task
	int highest = (31 - __builtin_clz(active_tasks & SCHEDULER_ACTIVE_MASK));

	if( !(active_tasks & (SCHEDULER_TASK_BEGUN << highest)) )
	{
		/* Start the new task.
		 * - Set RETI to the context switch routine
		 * - The context switch routine will set up a new frame and
		 *   begin the highest priority task.
		 */
		__asm__ volatile("%0 = RETI;" : "=r"(clobbered_reti));
		__asm__ volatile("RETI = %0;" : : "r"(_scheduler_switch));
	}
	//otherwise the highest priority task is already running and was interrupted

	return IQR_NUM;
#endif
}
};
#endif
