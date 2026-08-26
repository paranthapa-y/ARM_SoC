#ifndef REGISTERS_H
#define REGISTERS_H

#include <stdint.h>

#ifndef __I
#define __I  volatile const
#endif

#ifndef __O
#define __O  volatile
#endif

#ifndef __IO
#define __IO volatile
#endif

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t ERROR               :1;
        uint32_t SPI_EVENT           :1;
        uint32_t RESERVED_31_2       :30;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_INTERRUPT_STATE_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t ERROR               :1;
        uint32_t SPI_EVENT           :1;
        uint32_t RESERVED_31_2       :30;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_INTERRUPT_ENABLE_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t ERROR               :1;
        uint32_t SPI_EVENT           :1;
        uint32_t RESERVED_31_2       :30;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_INTERRUPT_TEST_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t FATAL_FAULT         :1;
        uint32_t RESERVED_31_1       :31;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_ALERT_TEST_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t RX_WATERMARK        :8;
        uint32_t TX_WATERMARK        :8;
        uint32_t RESERVED_28_16      :13;
        uint32_t OUTPUT_EN           :1;
        uint32_t SW_RST              :1;
        uint32_t SPIEN               :1;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_CONTROL_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t TXQD                :8;
        uint32_t RXQD                :8;
        uint32_t CMDQD               :4;
        uint32_t RXWM                :1;
        uint32_t RESERVED_21         :1;
        uint32_t BYTEORDER           :1;
        uint32_t RXSTALL             :1;
        uint32_t RXEMPTY             :1;
        uint32_t RXFULL              :1;
        uint32_t TXWM                :1;
        uint32_t TXSTALL             :1;
        uint32_t TXEMPTY             :1;
        uint32_t TXFULL              :1;
        uint32_t ACTIVE              :1;
        uint32_t READY               :1;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_STATUS_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t CLKDIV              :16;
        uint32_t CSNIDLE             :4;
        uint32_t CSNTRAIL            :4;
        uint32_t CSNLEAD             :4;
        uint32_t RESERVED_28         :1;
        uint32_t FULLCYC             :1;
        uint32_t CPHA                :1;
        uint32_t CPOL                :1;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_CONFIGOPTS0_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t CLKDIV              :16;
        uint32_t CSNIDLE             :4;
        uint32_t CSNTRAIL            :4;
        uint32_t CSNLEAD             :4;
        uint32_t RESERVED_28         :1;
        uint32_t FULLCYC             :1;
        uint32_t CPHA                :1;
        uint32_t CPOL                :1;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_CONFIGOPTS1_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t CSID                :32;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_CSID_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t LEN                 :9;
        uint32_t CSAAT               :1;
        uint32_t SPEED               :2;
        uint32_t DIRECTION           :2;
        uint32_t RESERVED_31_14      :18;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_COMMAND_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t RXDATA              :32;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_RXDATA_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t TXDATA              :32;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_TXDATA_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t CMDBUSY             :1;
        uint32_t OVERFLOW            :1;
        uint32_t UNDERFLOW           :1;
        uint32_t CMDINVAL            :1;
        uint32_t CSIDINVAL           :1;
        uint32_t RESERVED_31_5       :27;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_ERROR_ENABLE_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t CMDBUSY             :1;
        uint32_t OVERFLOW            :1;
        uint32_t UNDERFLOW           :1;
        uint32_t CMDINVAL            :1;
        uint32_t CSIDINVAL           :1;
        uint32_t ACCESSINVAL         :1;
        uint32_t RESERVED_31_6       :26;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_ERROR_STATUS_Type;

typedef union
{
    uint32_t WORD;

    struct
    {
        uint32_t RXFULL              :1;
        uint32_t TXEMPTY             :1;
        uint32_t RXWM                :1;
        uint32_t TXWM                :1;
        uint32_t READY               :1;
        uint32_t IDLE                :1;
        uint32_t RESERVED_31_6       :26;
    } BIT;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_EVENT_ENABLE_Type;

typedef struct
{
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_INTERRUPT_STATE_Type INTERRUPT_STATE;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_INTERRUPT_ENABLE_Type INTERRUPT_ENABLE;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_INTERRUPT_TEST_Type INTERRUPT_TEST;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_ALERT_TEST_Type ALERT_TEST;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_CONTROL_Type CONTROL;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_STATUS_Type STATUS;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_CONFIGOPTS0_Type CONFIGOPTS0;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_CONFIGOPTS1_Type CONFIGOPTS1;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_CSID_Type CSID;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_COMMAND_Type COMMAND;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_RXDATA_Type RXDATA;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_TXDATA_Type TXDATA;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_ERROR_ENABLE_Type ERROR_ENABLE;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_ERROR_STATUS_Type ERROR_STATUS;
    __IO SPI_HOST_RDL_INPUT_FORMAT_NEW_EVENT_ENABLE_Type EVENT_ENABLE;

} SPI_HOST_RDL_INPUT_FORMAT_NEW_TypeDef;

#endif /* REGISTERS_H */