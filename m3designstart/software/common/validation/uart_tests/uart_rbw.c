#include "CM3DS_MPS2.h"
#include <stdio.h>
#include "uart_stdout.h"
#define UART_ERR_BAUDDIV   (1U << 0)
#define UART_ERR_CTRL      (1U << 1)
#define UART_ERR_STATE     (1U << 2)
#define UART_ERR_DATA      (1U << 3)
#define UART_BAUDDIV      0X2A
#define UART_CTRL	  0X3F
#define UART_STATE	  0XF
#define UART_DATA	  0X29


int main() {

	uint32_t result = 0;
	 CM3DS_MPS2_UART0->BAUDDIV = 0xFFF0002A;
  	 CM3DS_MPS2_UART0->CTRL.word = 0xFFFFFF3F; 
	 CM3DS_MPS2_UART0->STATE.word = 0xFFFFFFFF;
	 while(CM3DS_MPS2_UART0->STATE.bit.tx_buff_full);
	 CM3DS_MPS2_UART0->DATA = 0xFFFFFF29;
	
	 result = uart_check();
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
	int a = CM3DS_MPS2_UART0->BAUDDIV;
	int b = CM3DS_MPS2_UART0->CTRL.word;
	int c = CM3DS_MPS2_UART0->STATE.word;

	while(CM3DS_MPS2_UART0->STATE.bit.rx_buff_full == 0);
	int d = CM3DS_MPS2_UART0->DATA;

    if (a != UART_BAUDDIV)
        err_code |= UART_ERR_BAUDDIV;

    if (b !=UART_CTRL)
        err_code |= UART_ERR_CTRL;

    if (c != 0)
        err_code |= UART_ERR_STATE;

    if (d != UART_DATA)
        err_code |= UART_ERR_DATA;

    return err_code;
}

