/******************************************************************************
 * FreeRTOS Kernel V10.4.4
 * Copyright (C) 2022 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * http://www.FreeRTOS.org
 * http://aws.amazon.com/freertos
 *
 * 1 tab == 4 spaces!
 ******************************************************************************/


/******************************************************************************
 * This project provides two demo applications.  A simple blinky style project,
 * and a more comprehensive test and demo application.  The
 * mainCREATE_SIMPLE_BLINKY_DEMO_ONLY setting (defined in this file) is used to
 * select between the two.  The simply blinky demo is implemented and described
 * in main_blinky.c.  The more comprehensive test and demo application is
 * implemented and described in main_full.c.
 *
 * This file implements the code that is not demo specific, including the
 * hardware setup and standard FreeRTOS hook functions.
 *
 * ENSURE TO READ THE DOCUMENTATION PAGE FOR THIS PORT AND DEMO APPLICATION ON
 * THE http://www.FreeRTOS.org WEB SITE FOR FULL INFORMATION ON USING THIS DEMO
 * APPLICATION, AND ITS ASSOCIATE FreeRTOS ARCHITECTURE PORT!
 *
 ******************************************************************************/


/******************************************************************************
 * Modified for the THUASRV32 processor. Based on the NEORV32 processor by Stephan Nolting.
 ******************************************************************************/

/* UART hardware constants. */
#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif

#include <stdint.h>

/* FreeRTOS kernel includes. */
#include <FreeRTOS.h>
#include <semphr.h>
#include <queue.h>
#include <task.h>

/* THUASRV32 includes. */
#include <thuasrv32.h>

/* misc */
//#include "driver_wrapper/uart_serial.h"

/* Set mainCREATE_SIMPLE_BLINKY_DEMO_ONLY to 1 to run the simple blinky demo,
or 0 to run the more comprehensive test and demo application. */
#ifndef mainCREATE_SIMPLE_BLINKY_DEMO_ONLY
#define mainCREATE_SIMPLE_BLINKY_DEMO_ONLY	1
#endif

/*-----------------------------------------------------------*/

/*
 * main_blinky() is used when mainCREATE_SIMPLE_BLINKY_DEMO_ONLY is set to 1.
 * main_full() is used when mainCREATE_SIMPLE_BLINKY_DEMO_ONLY is set to 0.
 */
#if( mainCREATE_SIMPLE_BLINKY_DEMO_ONLY == 1 )
	extern void main_blinky( void );
#else
	extern void main_full( void );
#endif /* #if mainCREATE_SIMPLE_BLINKY_DEMO_ONLY == 1 */

extern void freertos_risc_v_trap_handler( void );

/*
 * Prototypes for the standard FreeRTOS callback/hook functions implemented
 * within this file.  See https://www.freertos.org/a00016.html
 */
void vApplicationMallocFailedHook( void );
void vApplicationIdleHook( void );
void vApplicationStackOverflowHook( TaskHandle_t pxTask, char *pcTaskName );
void vApplicationTickHook( void );

/* Prepare hardware to run the demo. */
static void prvSetupHardware( void );

/* System */
void vToggleLED( void );
void vSendString( const char * pcString );

/*-----------------------------------------------------------*/

int main( void )
{
	prvSetupHardware();

    /* say hi */
    uart1_puts( "\r\nFreeRTOS " );
    uart1_puts( tskKERNEL_VERSION_NUMBER );
    uart1_puts( " running on THUASRV32!\r\n\n" );

	/* The mainCREATE_SIMPLE_BLINKY_DEMO_ONLY setting is described at the top
	of this file. */
#if( mainCREATE_SIMPLE_BLINKY_DEMO_ONLY == 1 )
  main_blinky();
#else
  main_full();
#endif
}

/*-----------------------------------------------------------*/

/* Handle THUASRV32-specific interrupts */
void freertos_risc_v_application_interrupt_handler( void ) {

    /* Handle specific interrupt. Don't forget to clear the pending interrupt flag */

    /* debug output - Use the value from the mcause CSR to call interrupt-specific handlers */
	uart1_puts( "FreeRTOS: Unknown interrupt: mcause = " );
	printhex( csr_read(mcause), 8 );
	uart1_puts( "\r\n" );
}

/* Handle THUASRV32-specific exceptions */
void freertos_risc_v_application_exception_handler( void ) {

    /* debug output - Use the value from the mcause CSR to call exception-specific handlers */
	uart1_puts( "FreeRTOS: Unknown exception: mcause = " );
	printhex( csr_read(mcause), 8 );
	uart1_puts( "\r\n" );
}

/*-----------------------------------------------------------*/

static void prvSetupHardware( void )
{
    /* install the freeRTOS trap handler */
    set_mtvec( freertos_risc_v_trap_handler, TRAP_DIRECT_MODE );

    /* clear GPIOA out port */
    GPIOA->POUT = 0;

    /* setup UART at default baud rate, no interrupts (yet) */
    uart1_init( BAUD_RATE, UART_CTRL_NONE );

    /* check clock tick configuration */
    if( ( uint32_t ) configCPU_CLOCK_HZ != 1000000UL ) {
        uart1_puts( "Warning! Incorrect configCPU_CLOCK_HZ configuration! Must be 1000000UL.\r\n ");
    }

    /* other hardware setup */

}

/*-----------------------------------------------------------*/
/* Note: not thread-save */
void vToggleLED( void )
{
	GPIOA->POUT ^= 0x01;
}

/*-----------------------------------------------------------*/
/* Note: not thread-save */
void vSendString( const char * pcString )
{
	uart1_puts( ( char * ) pcString );
}

/*-----------------------------------------------------------*/

void vApplicationMallocFailedHook( void )
{
	/* vApplicationMallocFailedHook() will only be called if
	configUSE_MALLOC_FAILED_HOOK is set to 1 in FreeRTOSConfig.h.  It is a hook
	function that will get called if a call to pvPortMalloc() fails.
	pvPortMalloc() is called internally by the kernel whenever a task, queue,
	timer or semaphore is created.  It is also called by various parts of the
	demo application.  If heap_1.c or heap_2.c are used, then the size of the
	heap available to pvPortMalloc() is defined by configTOTAL_HEAP_SIZE in
	FreeRTOSConfig.h, and the xPortGetFreeHeapSize() API function can be used
	to query the size of free heap space that remains (although it does not
	provide information on how the remaining heap might be fragmented). */
	taskDISABLE_INTERRUPTS();
    uart1_puts( "FreeRTOS_FAULT: vApplicationMallocFailedHook (solution: increase 'configTOTAL_HEAP_SIZE' in FreeRTOSConfig.h)\r\n" );
	__asm volatile( "ebreak" );
	for( ;; );
}
/*-----------------------------------------------------------*/

void vApplicationIdleHook( void )
{
	/* vApplicationIdleHook() will only be called if configUSE_IDLE_HOOK is set
	to 1 in FreeRTOSConfig.h.  It will be called on each iteration of the idle
	task.  It is essential that code added to this hook function never attempts
	to block in any way (for example, call xQueueReceive() with a block time
	specified, or call vTaskDelay()).  If the application makes use of the
	vTaskDelete() API function (as this demo application does) then it is also
	important that vApplicationIdleHook() is permitted to return to its calling
	function, because it is the responsibility of the idle task to clean up
	memory allocated by the kernel to any task that has since been deleted. */

	/* Currently not used */
}

/*-----------------------------------------------------------*/

void vApplicationStackOverflowHook( TaskHandle_t pxTask, char *pcTaskName )
{
	( void ) pcTaskName;
	( void ) pxTask;

	/* Run time stack overflow checking is performed if
	configCHECK_FOR_STACK_OVERFLOW is defined to 1 or 2.  This hook
	function is called if a stack overflow is detected. */
	taskDISABLE_INTERRUPTS();
    uart1_puts( "FreeRTOS_FAULT: vApplicationStackOverflowHook\r\n" );
	__asm volatile( "ebreak" );
	for( ;; );
}

/*-----------------------------------------------------------*/

void vApplicationTickHook( void )
{
    /* The tests in the full demo expect some interaction with interrupts. */
#if( mainCREATE_SIMPLE_BLINKY_DEMO_ONLY != 1 )
    {
        extern void vFullDemoTickHook( void );
        vFullDemoTickHook();
    }
#endif
}

/*-----------------------------------------------------------*/

/* This handler is responsible for handling all interrupts. Only the machine timer interrupt is handled by the kernel. */
void SystemIrqHandler( uint32_t mcause )
{
	/* Currently, print an error message and carry on... */
	uart1_puts( "FreeRTOS: SystemIrqHandler: Unknown interrupt: mcause = " );
	printhex( mcause, 8 );
	uart1_puts( "\r\n" );
}

