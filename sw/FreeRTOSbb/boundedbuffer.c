/*
 * boundedbuffer.c - an implementation of the producer
 *                   consumer problem with semaphores
 */

#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"
#include <stdio.h>

#include <thuasrv32.h>

#define BUFFER_SIZE 8

// Shared buffer
int buffer[BUFFER_SIZE];
int in = 0;
int out = 0;

// Synchronization primitives
SemaphoreHandle_t empty;
SemaphoreHandle_t full;
SemaphoreHandle_t mutex;

// Import from main file
void vToggleLED( void );
void vSendString( const char * pcString );

// Producer Task
void vProducer( void *pvParameters )
{
    int item = 0;

    while( 1 )
    {
        item++;

        // Wait for empty slot
        xSemaphoreTake( empty, portMAX_DELAY );

        // Enter critical section
        xSemaphoreTake( mutex, portMAX_DELAY );

        // Add item to buffer
        buffer[in] = item;
        vSendString( "Produced " );
        printdec( item );
        vSendString( " at index " );
        printdec( in );
        vSendString( "\r\n" );
        vToggleLED();
        in = (in + 1) % BUFFER_SIZE;

        // Exit critical section
        xSemaphoreGive( mutex );

        // Signal that buffer has new item
        xSemaphoreGive( full );

        vTaskDelay( pdMS_TO_TICKS( 500 ) );
    }
}

// Consumer Task
void vConsumer( void *pvParameters )
{
    int item;

    while( 1 )
    {
        // Wait for available item
        xSemaphoreTake( full, portMAX_DELAY );

        // Enter critical section
        xSemaphoreTake( mutex, portMAX_DELAY );

        // Remove item from buffer
        item = buffer[out];
        vSendString( "Consumed " );
        printdec( item );
        vSendString( " at index " );
        printdec( out );
        vSendString( "\r\n" );
        out = (out + 1) % BUFFER_SIZE;

        // Exit critical section
        xSemaphoreGive( mutex );

        // Signal that buffer has free space
        xSemaphoreGive( empty );

        vTaskDelay( pdMS_TO_TICKS( 800 ) );
    }
}

int boundedbuffer(void)
{
    // Create semaphores
    empty = xSemaphoreCreateCounting( BUFFER_SIZE, BUFFER_SIZE );
    full  = xSemaphoreCreateCounting( BUFFER_SIZE, 0 );
    mutex = xSemaphoreCreateMutex();

    if( empty == NULL || full == NULL || mutex == NULL )
    {
        vSendString( "Semaphore creation failed!\r\n" );
        while( 1 );
    }

    // Create tasks
    xTaskCreate( vProducer, "Producer", 1000, NULL, 1, NULL );
    xTaskCreate( vConsumer, "Consumer", 1000, NULL, 1, NULL );

    // Start scheduler
    vTaskStartScheduler();

    while( 1 );
}
