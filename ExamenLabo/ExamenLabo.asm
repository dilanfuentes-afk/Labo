#INCLUDE "P16F887.INC"
	
	__CONFIG _CONFIG1,(_CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _LVP_OFF)
	__CONFIG _CONFIG2, _BOR21V

DCounter1 EQU 0X0C
DCounter2 EQU 0X0D
BIT_CT EQU 0X20		
PDel0 EQU 0X21  ; defino reg GPR para rutina de tiempo
PDel1 EQU 0X22  ; defino reg GPR para rutina de tiempo
PDel2 EQU 0X23  ; defino reg GPR para rutina de tiempo
RESL EQU 0X24
RESH EQU 0X25


	ORG 0X00

	GOTO SALTO
;==============================INICIO SALTO========================================
SALTO
;===Anulamos las entradas analogicas menos la AN0===
	BANKSEL ANSEL 
	CLRF ANSELH
	CLRF ANSEL
	BSF ANSEL,0


;===Configuramos los Pines como salidas, menos el pin 0 de tris a (AN0)===
	BANKSEL TRISA
	CLRF TRISA
	BSF TRISA,0
	CLRF TRISE     ; Configura PORTE como salida (control del LCD)
	CLRF TRISD     ; Configura PORTD como salida (datos del LCD)


;===Configuramos ADCON0 y ADCON1===
	BANKSEL ADCON0
	MOVLW B'01000001';Fosc 8,adon
	MOVWF ADCON0

	BANKSEL ADCON1
	CLRF ADCON1
	BSF ADCON1,7;JUSTIFICACION DERECHA 
	BANKSEL PORTA 
	CALL LCD_CONFIG
	GOTO  INICIO

;===CONFIGURAMOS LCD===
LCD_CONFIG
    BCF PORTE,0         ; RS = 0  Instruccion o comando 
    BCF PORTE,1         ; RW = 0  Escribir

    ; Modo de entrada de caracteres (El texto no se desplaza, incrementa la posicion)
    MOVLW B'00000110'
    MOVWF PORTD
    CALL ENABLE

    ; Apagado y encendido de la pantalla (Intermitencia del cursor apagado, cursor apagado, pantalla encendida)
    MOVLW B'00001100'
    MOVWF PORTD
    CALL ENABLE

    ; Funtion set (Matriz para el caracter de 5x10,activacion de dos lineas, bus de datos de 8 bits
    MOVLW B'00111100'
    MOVWF PORTD
    CALL ENABLE
	RETURN
;==============================FIN SALTO========================================

;==============================INICIO "INICIO"========================================
INICIO
	BSF ADCON0,1;GO/DONE
	BTFSC ADCON0,1
	GOTO $-.1
	GOTO CONVERTIR	

;==============================FIN "INICIO"========================================

;==============================INICIO PREGUNTA HORA========================================
CONVERTIR
	; Copiar ADRESL y ADRESH a RESL/RESH
    BANKSEL ADRESL
    MOVF ADRESL,W
    BANKSEL PORTA
    MOVWF RESL

    BANKSEL ADRESH
    MOVF ADRESH,W
    BANKSEL PORTA
    MOVWF RESH
	
    GOTO PREGUNTA_H

;==============================FIN PREGUNTA HORA========================================

;==============================INICIO CONVERTIR========================================
PREGUNTA_H
	
	; === NOCHE ===
	; RESH = 0 y RESL <= 93
	MOVF RESH, W
	XORLW .0
	BTFSS STATUS, Z
	GOTO NOT_NOCHE
	MOVF RESL, W
	SUBLW .93
	BTFSS STATUS, C
	GOTO NOT_NOCHE
	GOTO MENSAJE_NOCHE
	
NOT_NOCHE
	
	; === MEDIODIA ===
	; RESH = 3 y RESL 84-206
	XORLW .3
	BTFSS STATUS, Z
	GOTO NOT_MEDIO
	MOVF RESL, W
	SUBLW .84
	BTFSC STATUS, C
	GOTO NOT_MEDIO
	ADDLW .84
	MOVF RESL,W
	SUBLW .206
	BTFSS STATUS, C
	GOTO NOT_MEDIO
	GOTO MENSAJE_MEDIO
	
NOT_MEDIO:
	; === MAÑANA/TARDE ===
	; Todo lo que no sea noche o mediodía
	; Decide dirección con Bit de control
	MOVFW BIT_CT
	XORLW .1
	BTFSS STATUS,Z
	GOTO MENSAJE_TARDE
	GOTO MENSAJE_MANANA

;==============================FIN CONVERTIR========================================

;==============================INICIO MENSAJES========================================

MENSAJE_MEDIO
    BCF BIT_CT,0 ;Desactivo el Bit de control

	BSF PORTE,0 ;Rs
    BCF PORTE,1 ;Rw
	CALL TIEMPO250MS

    MOVLW 'M'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'E'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'D'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'I'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'O'
    MOVWF PORTD
    CALL ENABLE
    MOVLW '-'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'D'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'I'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'A'
    MOVWF PORTD
    CALL ENABLE

	BCF PORTE,0
	BCF PORTE,1
	
	MOVLW B'00000010'; Curso Home 
	MOVWF PORTD
	CALL ENABLE

    GOTO INICIO

MENSAJE_TARDE

    BSF PORTE,0 ;RS
    BCF PORTE,1	;RW
	CALL TIEMPO

    MOVLW 'T'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'A'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'R'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'D'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'E'
    MOVWF PORTD
    CALL ENABLE

    MOVLW ' '
    MOVWF PORTD
    CALL ENABLE
    MOVLW ' ' ; 	
    MOVWF PORTD
    CALL ENABLE
    MOVLW ' '
    MOVWF PORTD
    CALL ENABLE
    MOVLW ' '
    MOVWF PORTD
    CALL ENABLE

	BCF PORTE,0
	BCF PORTE,1

	MOVLW B'00000010' ;Curso home 
	MOVWF PORTD
	CALL ENABLE 

 	GOTO INICIO

MENSAJE_MANANA

	BSF PORTE,0
    BCF PORTE,1
	CALL TIEMPO

    MOVLW 'M'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'A'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'N'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'A'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'N'
    MOVWF PORTD
    CALL ENABLE
    MOVLW 'A'
    MOVWF PORTD
    CALL ENABLE


    MOVLW ' '
    MOVWF PORTD
    CALL ENABLE
    MOVLW ' '
    MOVWF PORTD
    CALL ENABLE
    MOVLW ' '
    MOVWF PORTD
    CALL ENABLE


	BCF PORTE,0
	BCF PORTE,1

	MOVLW B'00000010'
	MOVWF PORTD
	CALL ENABLE 

	GOTO INICIO


MENSAJE_NOCHE
	BSF BIT_CT,0 ;activo el Bit de control

	BSF PORTE,0
    BCF PORTE,1

	CALL TIEMPO250MS
	
    MOVLW 'N'
    MOVWF PORTD
    CALL ENABLE

    MOVLW 'O'
    MOVWF PORTD
    CALL ENABLE

    MOVLW 'C'
    MOVWF PORTD
    CALL ENABLE

    MOVLW 'H'
    MOVWF PORTD
    CALL ENABLE

    MOVLW 'E'
    MOVWF PORTD
    CALL ENABLE

	MOVLW ' '
    MOVWF PORTD
    CALL ENABLE
    MOVLW ' '
    MOVWF PORTD
    CALL ENABLE
    MOVLW ' '
    MOVWF PORTD
    CALL ENABLE
    MOVLW ' '
    MOVWF PORTD
    CALL ENABLE

	BCF PORTE,0
	BCF PORTE,1

	MOVLW B'00000010'
	MOVWF PORTD
	CALL ENABLE

	GOTO INICIO
;==============================FIN MENSAJE========================================

;==============================INICIO ENABLE========================================
ENABLE
    BSF PORTE,2
    CALL TIEMPO
    BCF PORTE,2
    RETURN

;==============================FIN ENABLE========================================

;==============================INICIO TIEMPO========================================
TIEMPO ; 4 mili-segundos
	MOVLW 0X2f
	MOVWF DCounter1
	MOVLW 0X06
	MOVWF DCounter2
LOOP
	DECFSZ DCounter1, 1
	GOTO LOOP
	DECFSZ DCounter2, 1
	GOTO LOOP
	RETURN


TIEMPO250MS      
    movlw   .40        ; Bucle externo: ~40
    movwf   PDel0
DelayOuter
    movlw   .250       ; Bucle interno: ~250
    movwf   PDel1
DelayInner
    clrwdt
    clrwdt
    decfsz  PDel1, 1
    goto    DelayInner
    decfsz  PDel0, 1
    goto    DelayOuter
    return
;==============================FIN TIEMPO========================================
	END