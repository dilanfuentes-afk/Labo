#INCLUDE "P16F887.INC"

    __CONFIG _CONFIG1, (_CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _LVP_OFF)
    __CONFIG _CONFIG2, _BOR21V

PDel0 EQU 0X20  ; defino reg GPR para rutina de tiempo
PDel1 EQU 0X21  ; defino reg GPR para rutina de tiempo
PDel2 EQU 0X22  ; defino reg GPR para rutina de tiempo

	ORG 0X00
	GOTO INICIO
	

; --- Rutina de interrupción ---
    ORG 0x04
ISR:
    BANKSEL PIR1
    BTFSS PIR1, CCP1IF
    RETFIE

    BANKSEL PORTC
    BCF PORTC,2   ; Apagar LED

    BANKSEL PIR1
    BCF PIR1, CCP1IF
    RETFIE

INICIO
	BANKSEL ANSEL
	CLRF ANSEL
	CLRF ANSELH
	
    ; --- Configurar RC2 como salida CCP1 ---
    BANKSEL TRISC
    BCF TRISC,2      ; RC2 salida

    ; --- Encender LED (antes de compare) ---
    BANKSEL PORTC
    BSF PORTC,2

	BANKSEL T1CON
	MOVLW   B'00000001'      ; TMR1ON=1
	MOVWF   T1CON

	BANKSEL CCP1CON
	MOVLW B'000001001'
	MOVWF CCP1CON

    ; --- Cargar valor de comparación ---
	BANKSEL CCPR1H
    MOVLW 0x1F
    MOVWF CCPR1H
	BANKSEL CCPR1L
    MOVLW 0x40
    MOVWF CCPR1L
	
    ; --- Habilitar interrupciones ---
    BANKSEL PIR1
    BCF PIR1, CCP1IF   ; Limpiar bandera
    BSF PIE1, CCP1IE   ; Habilitar interrupción CCP1
    BSF INTCON, PEIE
    BSF INTCON, GIE


BUCLE
	NOP
	NOP 
	NOP
	GOTO BUCLE






END