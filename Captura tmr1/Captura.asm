#INCLUDE "P16F887.INC"

    __CONFIG _CONFIG1, (_CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _LVP_OFF)
    __CONFIG _CONFIG2, _BOR21V

PDel0 EQU 0X20  ; defino reg GPR para rutina de tiempo
PDel1 EQU 0X21  ; defino reg GPR para rutina de tiempo
PDel2 EQU 0X22  ; defino reg GPR para rutina de tiempo

	ORG 0X00
	GOTO INICIO
	
	ORG 0X04
	BSF PORTB,0

	CALL TIEMPO
	BCF PORTB,0
	BANKSEL PIR1
	BCF PIR1,CCP1IF
	BANKSEL PORTA
	RETFIE



INICIO
	BANKSEL ANSEL
	CLRF ANSEL
	CLRF ANSELH
	
	BANKSEL TRISB
	BCF TRISB,0


	BANKSEL CCP1CON
	MOVLW B'00000110'
	MOVWF CCP1CON

	BANKSEL TRISC
	MOVLW B'00000100'
	MOVWF TRISC
	
	BANKSEL T1CON
	MOVLW   B'00000001'      ; TMR1ON=1
	MOVWF   T1CON

	BANKSEL PIE1
	BSF PIE1,CCP1IE

	BANKSEL INTCON
	BSF INTCON,PEIE
	BSF INTCON,GIE

	BANKSEL PORTA
	CLRF PORTB

BUCLE
	NOP
	NOP 
	NOP
	GOTO BUCLE


TIEMPO
        movlw     .14       ; 1 set numero de repeticion  (C)
        movwf     PDel0     ; 1 |
PLoop0  movlw     .72       ; 1 set numero de repeticion  (B)
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


