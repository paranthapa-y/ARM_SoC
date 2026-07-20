#include "CM3DS_MPS2.h"
#include <stdio.h>

void UartStdOutInit1(void)
{

		CM3DS_MPS2_UART1->BAUDDIV = 63 ;
  CM3DS_MPS2_UART1->CTRL    = 0x01; 


  return;
}
// Output a character

unsigned char Uart1Putc(unsigned char my_ch)
{
	while ((CM3DS_MPS2_UART1->STATE & 1)); // Wait if Transmit Holding register is full
  CM3DS_MPS2_UART1->DATA = my_ch; // write to transmit holding register
}

/*
unsigned char UartPutc(unsigned char my_ch)
{
    while (CM3DS_MPS2_UART0->STATE & 1);

    if (my_ch == '\n')
        CM3DS_MPS2_UART0->DATA = '\n';      // don't modify newline
    else
        CM3DS_MPS2_UART0->DATA = my_ch + 1;

    return my_ch;
} */
// Get a character
unsigned char UartGet1c(void)
{
  while ((CM3DS_MPS2_UART1->STATE & 2)==0); // Wait if Receive Holding register is empty
  return (CM3DS_MPS2_UART1->DATA);
}

void UartEndSimulation1(void)
{

  fflush(stdout);
//  UartPutc((char) 0x4);
  // End of simulation
  Uart1Putc((char)0x4);
  while(1);
}

