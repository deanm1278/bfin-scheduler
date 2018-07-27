#include "scheduler.h"

//create the scheduler object
Scheduler sch;

//define priorities for our tasks
enum {
  PRIO_TASK_0 = 0,
  PRIO_TASK_1 = 1,
  PRIO_TASK_2 = 2,
};

void task0( void ){
  //print numbers 0-9 with delay
  for(int i=0; i<10; i++){
    Serial.println(i);
    delay(1000);
  }
}

void task1( void ){
  for(int i=57; i>55; i--){
    Serial.println(i);
    delay(1000);
  }
}

void task2( void ){
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
   *
   * Make sure UART1_STAT_Handler isn't defined anywhere else
   */
  int UART1_STAT_Handler( int IQR_NUM ){
	Serial.IrqHandler();
	if(Serial.available()){
		char c = Serial.read();
		if(c == 'a')
			sch.addTask(task1, PRIO_TASK_1);
		else if(c == 's')
			sch.addTask(task2, PRIO_TASK_2);
	}
    return IQR_NUM;
  }
}