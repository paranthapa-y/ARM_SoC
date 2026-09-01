#include "CM3DS_MPS2.h"
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "uart_stdout.h"
#include "CM3DS_MPS2_driver.h"
#include "CM3DS_function.h"

#define APB_UART_PID4  0x04
#define APB_UART_PID5  0x00
#define APB_UART_PID6  0x00
#define APB_UART_PID7  0x00
#define APB_UART_PID0  0x21
#define APB_UART_PID1  0xB8
#define APB_UART_PID2  0x1B
#define APB_UART_PID3  0x00
#define APB_UART_CID0  0x0D
#define APB_UART_CID1  0xF0
#define APB_UART_CID2  0x05
#define APB_UART_CID3  0xB1



	int main(void) {
		
		uint32_t result = 0;
		UartStdOutInit();
		result = pid_check(CM3DS_MPS2_UART2);

		if(result != 0)
		{printf1(0,"TEST FAILED\n");
			printf1(0,"result = %d\n", result);}
		else	
			printf1(0,"TEST PASSED\n");

		UartEndSimulation();
		
		return 0;
	}


	int pid_check(CM3DS_MPS2_UART_TypeDef *CM3DS_MPS2_UART){
		
		uint32_t err_code = 0 ;
		unsigned int i;
		uintptr_t uart_base = (uintptr_t)CM3DS_MPS2_UART;
		
		if (HW32_REG(uart_base + 0xFD0) != APB_UART_PID4) {err_code |= (1<<0); }
 		 if (HW32_REG(uart_base + 0xFD4) != APB_UART_PID5) {err_code |= (1<<1); }
 		 if (HW32_REG(uart_base + 0xFD8) != APB_UART_PID6) {err_code |= (1<<2); }
 		 if (HW32_REG(uart_base + 0xFDC) != APB_UART_PID7) {err_code |= (1<<3); }
 		 if (HW32_REG(uart_base + 0xFE0) != APB_UART_PID0) {err_code |= (1<<4); }
 		 if (HW32_REG(uart_base + 0xFE4) != APB_UART_PID1) {err_code |= (1<<5); }
		  if (HW32_REG(uart_base + 0xFE8) != APB_UART_PID2) {err_code |= (1<<6); }
 		 if (HW32_REG(uart_base + 0xFEC) != APB_UART_PID3) {err_code |= (1<<7); }
 		 if (HW32_REG(uart_base + 0xFF0) != APB_UART_CID0) {err_code |= (1<<8); }
 		 if (HW32_REG(uart_base + 0xFF4) != APB_UART_CID1) {err_code |= (1<<9); }
 		 if (HW32_REG(uart_base + 0xFF8) != APB_UART_CID2) {err_code |= (1<<10); }
 		 if (HW32_REG(uart_base + 0xFFC) != APB_UART_CID3) {err_code |= (1<<11); }


	
 		 for (i=0; i <12; i++) {
   			 HW32_REG(uart_base + 0xFD0 + (i<<2)) = ~HW32_REG(uart_base + 0xFD0 + (i<<2));
  		  } 


 		 if (HW32_REG(uart_base + 0xFD0) != APB_UART_PID4) {err_code |= (1<<0); }
		  if (HW32_REG(uart_base + 0xFD4) != APB_UART_PID5) {err_code |= (1<<1); }
		  if (HW32_REG(uart_base + 0xFD8) != APB_UART_PID6) {err_code |= (1<<2); }
 		 if (HW32_REG(uart_base + 0xFDC) != APB_UART_PID7) {err_code |= (1<<3); }
 		 if (HW32_REG(uart_base + 0xFE0) != APB_UART_PID0) {err_code |= (1<<4); }
  		if (HW32_REG(uart_base + 0xFE4) != APB_UART_PID1) {err_code |= (1<<5); }
  		if (HW32_REG(uart_base + 0xFE8) != APB_UART_PID2) {err_code |= (1<<6); }
 		 if (HW32_REG(uart_base + 0xFEC) != APB_UART_PID3) {err_code |= (1<<7); }
  		if (HW32_REG(uart_base + 0xFF0) != APB_UART_CID0) {err_code |= (1<<8); }
 		 if (HW32_REG(uart_base + 0xFF4) != APB_UART_CID1) {err_code |= (1<<9); }
 		 if (HW32_REG(uart_base + 0xFF8) != APB_UART_CID2) {err_code |= (1<<10); }
 		 if (HW32_REG(uart_base + 0xFFC) != APB_UART_CID3) {err_code |= (1<<11); } 

  
		return err_code;

	}



