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

	active_tasks = 0;

	for(int i=0; i<SCHEDULER_MAX_TASKS; i++) scheduler_tasks[i] = NULL;

	return true;
}

bool Scheduler::addTask(void (*fn)(void), uint8_t prio)
{
	//make this prio level isn't already taken
	if(active_tasks & (SCHEDULER_TASK_ACTIVE << (prio << 1))){
		__asm__ volatile("EMUEXCPT;");
		return SCHEDULER_ERR_DUPLICATE_PRIO;
	}
	else{
		active_tasks |= (SCHEDULER_TASK_ACTIVE << (prio << 1));
		scheduler_tasks[prio] = (volatile void(*)(void))fn;
	}
	__asm__ volatile("RAISE 14;");
	return 0;
}
