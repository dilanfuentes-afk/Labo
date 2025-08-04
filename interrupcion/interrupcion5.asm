#INCLUDE "P16F887.INC"

    __CONFIG _CONFIG1, (_CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _LVP_OFF)
    __CONFIG _CONFIG2, _BOR21V

PDel0 EQU 0x25
PDel1 EQU 0x26
REG5 EQU 0X28

ORG 0X00
	GOTO INICIO
;=========INTERRUPCION=========
ORG 0X04
INTER
BUCLE1
	MOVF PORTB,W
	CLRF PORTB
	BSF INTCON,0 ;LIMPIO BANDERA
	NOP
	NOP
	RETFIE
;=== ======INICIALIZACION==========
INICIO
	BANKSEL ANSEL
	CLRF ANSEL
	CLRF ANSELH

	BANKSEL TRISB
	MOVLW .255
	MOVWF TRISB ; DECLARO ENTRADAS 

	BANKSEL IOCB
	BSF IOCB,IOCB1

	BANKSEL PORTA
	BSF INTCON,3 ; Activa interrupción externa por RB0 (INTE = 1)
    BSF INTCON,7 ; Activa interrupciones globales (GIE = 1)
	NOP

BUCLE
	NOP
	GOTO BUCLE
 
TIEMPO
    movlw     .239
    movwf     PDel0
PLoop1
    movlw     .232
    movwf     PDel1
PLoop2
    clrwdt
PDelL1
    goto PDelL2
PDelL2
    goto PDelL3
PDelL3
    clrwdt
    decfsz     PDel1, 1
    goto      PLoop2
    decfsz     PDel0, 1
    goto      PLoop1
PDelL4
    goto PDelL5
PDelL5
    goto PDelL6
PDelL6
    goto PDelL7
PDelL7
    clrwdt
    return
    END