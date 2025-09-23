#INCLUDE "P16F887.INC"
	
	__CONFIG _CONFIG1,(_CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _LVP_OFF)
	__CONFIG _CONFIG2, _BOR21V

PDel0 EQU 0X20  ; defino reg GPR para rutina de tiempo
PDel1 EQU 0X21  ; defino reg GPR para rutina de tiempo
PDel2 EQU 0X22  ; defino reg GPR para rutina de tiempo

	ORG 0X00

INICIO 
	BANKSEL ANSEL 
	CLRF ANSEL
	CLRF ANSELH

	BANKSEL TRISC
    BCF     TRISC, 2        ; RC2 como salida

    BANKSEL PR2
	MOVLW   .124
    MOVWF   PR2             ; PWM periodo

    BANKSEL CCP1CON
	MOVLW   B'00001100'     ; Modo PWM
    MOVWF   CCP1CON

   BANKSEL CCPR1L
	MOVLW   0x10
    MOVWF   CCPR1L          ; Parte alta del duty (8 bits)
    ; Bits DC1B1:DC1B0 ya están en CCP1CON

	BANKSEL T2CON  
	MOVLW   B'00000101'     ; Prescaler = 4, TMR2 ON
    MOVWF   T2CON


BUCLE
	NOP
	NOP
	NOP
	GOTO BUCLE








TIEMPO
        movlw     .0       ; 1 set numero de repeticion  (C)
        movwf     PDel0     ; 1 |
PLoop0  movlw     .17       ; 1 set numero de repeticion  (B)
        movwf     PDel1     ; 1 |
PLoop1  movlw     .247      ; 1 set numero de repeticion  (A)
        movwf     PDel2     ; 1 |
PLoop2  clrwdt              ; 1 clear watchdog
        decfsz    PDel2, 1  ; 1 + (1) es el tiempo 0  ? (A)
        goto      PLoop2    ; 2 no, loop
        decfsz    PDel1,  1 ; 1 + (1) es el tiempo 0  ? (B)
        goto      PLoop1    ; 2 no, loop
        decfsz    PDel0,  1 ; 1 + (1) es el tiempo 0  ? (C)
        goto      PLoop0    ; 2 no, loop
PDelL1  goto PDelL2         ; 2 ciclos delay
PDelL2  clrwdt              ; 1 ciclo delay
        return              ; 2+2 Fin.


	END