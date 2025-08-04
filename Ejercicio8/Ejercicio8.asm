; ======================================
; Simulación de entrada analógica y descomposición
; Microcontrolador: PIC16F887
; ======================================

    #INCLUDE "P16F887.INC"

    __CONFIG _CONFIG1, (_CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _LVP_OFF)
    __CONFIG _CONFIG2, _BOR21V

; === Declaración de registros ===
PDel0   EQU 0x25
PDel1   EQU 0x26
PDel2   EQU 0x27


; === Programa principal ===
    ORG 0x00
GOTO INICIO
;=========================================================
LCD_CONFIG
	BCF PORTE,0	;AS EN 0 PARA COMANDO
	BCF PORTE,1 ;AW EN 1 PARA ESCRIBIR 

COMANDOS3 ; IN OUT CHARACTER 
	MOVLW B'00000110'
	MOVWF PORTD
	CALL ENABLE

COMANDOS2 ; ON-OFF
	MOVLW B'00001100'
	MOVWF PORTD
	CALL ENABLE

COMANDOS1
	MOVLW B'00111100'
	MOVWF PORTD
	CALL ENABLE
	RETURN
;========================================================
INICIO 
	BANKSEL ANSEL
	CLRF ANSEL
	CLRF ANSELH
	
	BANKSEL TRISB
	CLRF TRISE
	CLRF TRISD

	BANKSEL PORTA
	CLRF PORTD
	CLRF PORTE

	CALL LCD_CONFIG
	GOTO ESCRIBIR

ESCRIBIR
	BSF PORTE,0
	BCF PORTE,1

	MOVLW 'H'
	MOVWF PORTD
	CALL ENABLE

	MOVLW 'o'
	MOVWF PORTD
	CALL ENABLE

	MOVLW 'l'
	MOVWF PORTD
	CALL ENABLE

	MOVLW 'a'
	MOVWF PORTD
	CALL ENABLE

	MOVLW '_'
	MOVWF PORTD
	CALL ENABLE

	MOVLW ':'
	MOVWF PORTD
	CALL ENABLE

	MOVLW 'D'
	MOVWF PORTD
	CALL ENABLE
	GOTO BUCLE 

ENABLE
	BSF PORTE,2
	CALL TIEMPO
	BCF PORTE,2
	RETURN

BUCLE
	GOTO BUCLE 
    
TIEMPO      
        movlw     .197      ; 1 set numero de repeticion  (B)
        movwf     PDel0     ; 1 |
PLoop1  movlw     .253      ; 1 set numero de repeticion  (A)
        movwf     PDel1     ; 1 |
PLoop2  clrwdt              ; 1 clear watchdog
        clrwdt              ; 1 ciclo delay
        decfsz    PDel1, 1  ; 1 + (1) es el tiempo 0  ? (A)
        goto      PLoop2    ; 2 no, loop
        decfsz    PDel0,  1 ; 1 + (1) es el tiempo 0  ? (B)
        goto      PLoop1    ; 2 no, loop
PDelL1  goto PDelL2         ; 2 ciclos delay
PDelL2  
        return              ; 2+2 Fin.
END