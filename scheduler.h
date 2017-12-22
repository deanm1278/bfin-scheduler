/*
 * scheduler.h
 *
 *  Created on: Dec 20, 2017
 *      Author: Dean
 */

#ifndef BFIN_SCHEDULER_SCHEDULER_H_
#define BFIN_SCHEDULER_SCHEDULER_H_

#define SCHEDULER_IRQ_Num 89 //SYS_SOFT3_IRQ_Num

#if !defined(__ASSEMBLY__)

#include <Arduino.h>

#define SCHEDULER_Handler SYS_SOFT3_INT_Handler

#define SCHEDULER_MAX_TASKS 16
#define SCHEDULER_MAX_PRIO SCHEDULER_MAX_TASKS

#define SCHEDULER_TASK_ACTIVE 0x01UL
#define SCHEDULER_TASK_BEGUN 0x02UL

#define SCHEDULER_ACTIVE_MASK 0x55555555

/* For now lets assume we can't switch to a new task
 * while inside a critical section.
 */
#define SCHEDULER_CRIT_ENTRY disableIRQ(SCHEDULER_IRQ_Num)
#define SCHEDULER_CRIT_EXIT enableIRQ(SCHEDULER_IRQ_Num)

enum {
	SCHEDULER_ERR_SUCCESS = 0,
	SCHEDULER_ERR_DUPLICATE_PRIO,
};

class Scheduler {
public:
	Scheduler(void) {};
	~Scheduler(void) {};

	bool begin();

	bool addTask(void (*fn)(void), uint8_t prio);
};

#endif //__ASSEMBLY__

#endif /* BFIN_SCHEDULER_SCHEDULER_H_ */
