#INCLUDE "P16F887.INC"

	__CONFIG _CONFIG1, (_CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _LVP_OFF)
	__CONFIG _CONFIG2, _BOR21V

REGU EQU 0x20
REGD EQU 0x21
REGCONTADOR EQU 0x22
PDel0 EQU 0X23  ; defino reg GPR para rutina de tiempo
PDel1 EQU 0X24  ; defino reg GPR para rutina de tiempo
PDel2 EQU 0X25  ; defino reg GPR para rutina de tiempo

	ORG 0X00

	BANKSEL ANSEL
	CLRF ANSEL
	CLRF ANSELH


	BANKSEL TRISA
	CLRF TRISA
	BSF TRISA,4
	CLRF TRISB

	BANKSEL PORTB
	CLRF PORTB
	CLRF PORTA	

INICIO
	CLRF REGU
	CLRF REGD
	CLRF REGCONTADOR

MUESTRA
	MOVLW .5
	MOVWF REGCONTADOR

SIGO
	MOVF REGU,W
	CALL TABLA
	MOVWF PORTB
	BSF PORTA,0
	BSF PORTA,3
	CALL TIEMPO

	CLRF PORTA

	MOVF REGD,W
	CALL TABLA
	MOVWF PORTB
	BSF PORTA,2
	BSF PORTA,3
	CALL TIEMPO
	
	CLRF PORTA

	DECFSZ REGCONTADOR,1
	GOTO SIGO 
	GOTO BOTTON

BOTTON
	BTFSS PORTA, 4
	GOTO INCREMENTO
	GOTO DECREMENTO

INCREMENTO
	INCF REGU,F 
	MOVF REGU,W
	XORLW .10
	BTFSS STATUS,Z
	GOTO MUESTRA
	CLRF REGU
	INCF REGD,1
	MOVF REGD,W
	XORLW .10
	BTFSS STATUS, Z
	GOTO MUESTRA
	GOTO INICIO

DECREMENTO
    MOVF REGU, W       
    XORLW .0           
    BTFSC STATUS, Z    
    GOTO MENOS_DECENA  

    DECF REGU, F       
    GOTO MUESTRA       

MENOS_DECENA
    MOVLW .9           
    MOVWF REGU

    MOVF REGD, W       
    XORLW .0           
    BTFSC STATUS, Z    
    GOTO RESET_CONTADOR

    DECF REGD, F      
    GOTO MUESTRA      

RESET_CONTADOR
    MOVLW .9       
    MOVWF REGD
    MOVLW .9
    MOVWF REGU
    GOTO MUESTRA     
TABLA
	ADDWF PCL,F
	RETLW B'01111110'
	RETLW B'00110000'
	RETLW B'01101101'
	RETLW B'01111001'
	RETLW B'00110011'
	RETLW B'01011011'
	RETLW B'01011111'
	RETLW B'01110000'
	RETLW B'01111111'
	RETLW B'01110011'

TIEMPO
        movlw     .239      ; 1 set numero de repeticion  (B)
        movwf     PDel0     ; 1 |
PLoop1  movlw     .232      ; 1 set numero de repeticion  (A)
        movwf     PDel1     ; 1 |
PLoop2  clrwdt              ; 1 clear watchdog
PDelL1  goto PDelL2         ; 2 ciclos delay
PDelL2  goto PDelL3         ; 2 ciclos delay
PDelL3  clrwdt              ; 1 ciclo delay
        decfsz    PDel1, 1  ; 1 + (1) es el tiempo 0  ? (A)
        goto      PLoop2    ; 2 no, loop
        decfsz    PDel0,  1 ; 1 + (1) es el tiempo 0  ? (B)
        goto      PLoop1    ; 2 no, loop
PDelL4  goto PDelL5         ; 2 ciclos delay
PDelL5  goto PDelL6         ; 2 ciclos delay
PDelL6  goto PDelL7         ; 2 ciclos delay
PDelL7  clrwdt              ; 1 ciclo delay
        return              ; 2+2 Fin.
END