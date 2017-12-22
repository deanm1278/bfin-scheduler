#include "scheduler.h"

//create the scheduler object
Scheduler sch;

//define priorities for our tasks
enum {
  PRIO_TASK_0 = 0,
  PRIO_TASK_1 = 1
};

void task0( void ){
  //print numbers 0-9 with delay
  for(int i=0; i<10; i++){
    Serial.println(i);
    delay(1000);
  }
}

void task1( void ){
  Serial.println("preempted!");
}

void setup() {
  Serial.begin(9600);
  Serial.println("scheduler example!");
  sch.begin();

  /* Add a low priority, long running task
   * Since this is the only task, the scheduler will start
   * on it right away.
   */
  sch.addTask(task0, PRIO_TASK_0);

  /* After all tasks are done, normal operation
   * will resume from here.
   */
  Serial.println("done!");
}

void loop() {
  //do nothing
}

extern "C" {
  /* When this interrupt is triggered, a higher priority task will be
   * added. This will preempt lower priority task0.
   */
  int UART0_STAT_Handler( int IQR_NUM ){
    sch.addTask(task1, PRIO_TASK_1);
    return IQR_NUM;
  }
}

