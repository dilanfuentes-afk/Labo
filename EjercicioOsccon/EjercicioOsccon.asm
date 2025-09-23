   #INCLUDE "P16F887.INC"

    __CONFIG _CONFIG1, (_CP_OFF & _WDT_OFF & _PWRTE_ON & _INTOSCIO & _LVP_OFF)
    __CONFIG _CONFIG2, _BOR21V

PDel0 EQU 0X20
PDel1 EQU 0X21
PDel2 EQU 0X22

            ORG     0x0000
            GOTO    INIT

;========================= FRECUENCIAS ====================
SET_4MHZ:
            BANKSEL OSCCON
            MOVLW   b'01100001'     ; IRCF=110 (4 MHz), SCS=1
            MOVWF   OSCCON
            RETURN

SET_31KHZ:
            BANKSEL OSCCON
            MOVLW   b'00000001'     ; IRCF=000 (31 kHz), SCS=1
            MOVWF   OSCCON
            RETURN

;========================== PROGRAMA ======================
INIT:
            BANKSEL ANSEL
            CLRF    ANSEL
            CLRF    ANSELH

            BANKSEL TRISB
            BSF     TRISB, 0        ; RB0 = entrada

            CALL    SET_4MHZ        ; arranca en 4 MHz

MAIN:
; esperar botón presionado (nivel bajo en RB0)
            BTFSC   PORTB, 0
            GOTO    MAIN

; leer IRCF
            BANKSEL OSCCON
            MOVF    OSCCON, W
            ANDLW   b'01110000'     ; solo IRCF<2:0>
            BTFSC   STATUS, Z       ; ¿está en 000 ? 31 kHz?
            GOTO    TO4MHZ
            GOTO    TO31KHZ

TO4MHZ:     CALL    SET_4MHZ
            GOTO    WAIT_RELEASE

TO31KHZ:    CALL    SET_31KHZ
            GOTO    WAIT_RELEASE

WAIT_RELEASE:
            BTFSS   PORTB, 0
            GOTO    WAIT_RELEASE
            GOTO    MAIN

            END