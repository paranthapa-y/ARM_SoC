#include "CM3DS_MPS2.h"
#include <stdio.h>
#include <string.h>
#include "uart_stdout.h"
#include "CM3DS_MPS2_driver.h"
#include "CM3DS_function.h"


	int main(void) {

		uint32_t result = 0;

		 UartStdOutInit();
		 UartIOConfig();
		 result += uartinit();
		 result += tx_rx();


		 if(result != 0)
		 { printf1(0,"TEST FAILED\n");
			 printf1(0,"RESULT = %d\n", result); }
		 else
			 printf1(0,"TEST PASSED\n");

		 UartEndSimulation();

		 return 0;
	}

	
	int uartinit(void) {

		uint32_t err_code = 0;

		  if(CM3DS_MPS2_uart_init(CM3DS_MPS2_UART2, 0x20, 1, 0, 1, 0, 1, 0) == 0)
  			  printf("UART2 Initialised Successfully (Baud Divider of: %d)\n", CM3DS_MPS2_uart_GetBaudDivider(CM3DS_MPS2_UART2));
   		  else
 			 {
  			  puts("UART2 Initialization Failed\n");
  			  err_code = 1;
 			 }
 		 if(CM3DS_MPS2_uart_init(CM3DS_MPS2_UART3, 0x20, 0, 1, 0, 1, 0, 1) == 0)
 			   printf("UART3 Initialised Successfully (Baud Divider of: %d)\n", CM3DS_MPS2_uart_GetBaudDivider(CM3DS_MPS2_UART3));
 		   else
			  {
    				puts("UART3 Initialization Failed\n");
 				   err_code |= 2;
			  }

		   return err_code;

			}



	void UartIOConfig(void)
		{ 
 		 CM3DS_MPS2_GPIO0->ALTFUNCSET = (1<<0) | (1<<4);
 		 CM3DS_MPS2_GPIO1->ALTFUNCSET = (1<<7) | (1<<8) | (1<<10) | (1<<14);
		  return;
		}


	int tx_rx(void) {

		int err_code=0;

		char        received_text[20];
 		 const char  transmit_text[20] = "Hello world\n";
 		 unsigned int tx_count = 0;
 		 unsigned int rx_count = 0;
 		 unsigned int str_size = strlen(transmit_text);

	   do { /* test loop for both tx and rx process */
  		  /* tx process */
   		 if (((CM3DS_MPS2_UART2->STATE.bit.tx_buff_full)==0)&&(tx_count<str_size)) {
     		 CM3DS_MPS2_UART2->DATA = transmit_text[tx_count];
    		  tx_count++;
    		  }
   		 /* rx process */
   		 if ((CM3DS_MPS2_UART3->STATE.bit.rx_buff_full)!=0) {
    		  received_text[rx_count] = CM3DS_MPS2_UART3->DATA;
    		  UartPutc((char) received_text[rx_count]);
    		  rx_count++;
   		   }
 		 } while ( rx_count <str_size);
 		 received_text[rx_count]=0;

		 

 		 if (strcmp(transmit_text, received_text)!=0){ err_code |= (1<<2);}

  		return err_code;
	}



