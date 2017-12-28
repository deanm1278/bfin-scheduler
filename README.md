# bfin-scheduler
this is a simple timerless preemptive task scheduler for blackfin.
It allows for a tasks to be added and assigned a priority, and then preempted if a higher priority task is added.
After the task is complete, it will return to executing the task that was interrupted.

Once there are no more tasks to be run, execution will continue from the point where the scheduler began (when the first task was added).

No synchronization tools (mutexes, semaphores, etc.) are included, and it is up to the programmer to make sure toes are not stepped on.
This is not a full RTOS.

This is not yet extensively tested, and race condition bugs may still exist when complex interrupt structures are used.
