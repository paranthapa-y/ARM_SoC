#include "CM3DS_MPS2.h"
#include <stdio.h>
#include "uart_stdout.h"
#define UART_ERR_BAUDDIV   (1U << 0)
#define UART_ERR_CTRL      (1U << 1)
#define UART_ERR_STATE     (1U << 2)
#define UART_ERR_DATA      (1U << 3)



int main(void) {


	uint32_t result=0;
	result = uart_check();
	UartStdOutInit();
		
		if(result & UART_ERR_BAUDDIV)
			printf1(0,"TEST FAILED: error in bauddiv register \n");
	       if(result & UART_ERR_CTRL)
	       		printf1(0, "TEST FAILED: error in CTRL register \n");
		if(result & UART_ERR_STATE)
	 		printf1(0, "TEST FAILED: error in STATE register \n");		
		if(result & UART_ERR_DATA)
			printf1(0, "TEST FAILED: error in DATA register \n");
		if(result == 0)
			printf1(0, "TEST PASSED \n");		
	UartEndSimulation();

	return 0;

	}


int uart_check(void)
{
    uint32_t err_code = 0;

    if (CM3DS_MPS2_UART0->BAUDDIV != 0)
        err_code |= UART_ERR_BAUDDIV;

    if (CM3DS_MPS2_UART0->CTRL.word != 0)
        err_code |= UART_ERR_CTRL;

    if (CM3DS_MPS2_UART0->STATE.word != 0)
        err_code |= UART_ERR_STATE;

    if (CM3DS_MPS2_UART0->DATA != 0)
        err_code |= UART_ERR_DATA;

    return err_code;
}
