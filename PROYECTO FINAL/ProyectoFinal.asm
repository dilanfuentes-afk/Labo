#INCLUDE "P16F887.INC"
	
	__CONFIG _CONFIG1,(_CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _LVP_OFF)
	__CONFIG _CONFIG2, _BOR21V

; === DIRECCIONES DE VARIABLES EN RAM (BANCO 0) ===
ADC_RESULT      EQU 0X20    ; RESULTADO DEL ADC (BYTE ALTO)
HUMEDAD_MIN     EQU 0X21    ; UMBRAL MÍNIMO DE HUMEDAD
HUMEDAD_MAX     EQU 0X22    ; UMBRAL MÁXIMO DE HUMEDAD
PWM_DUTY        EQU 0X23    ; VALOR DEL DUTY CYCLE (0–255)
FORZADO_TIMER   EQU 0X24    ; CONTADOR PARA MODO FORZADO (100 = 10 SEG)
MODO_FORZADO    EQU 0X25    ; FLAG: 0 = AUTOMÁTICO, 1 = FORZADO
TEMP_W          EQU 0X26    ; RESPALDO DE W EN LA ISR
TEMP_STATUS     EQU 0X27    ; RESPALDO DE STATUS EN LA ISR

; === DIRECCIONES EN EEPROM ===
EEPROM_MIN_ADDR EQU 0X00
EEPROM_MAX_ADDR EQU 0X01

; === VALORES POR DEFECTO ===
DEFAULT_MIN     EQU 0X1E    ; 30 DECIMAL
DEFAULT_MAX     EQU 0X46    ; 70 DECIMAL

    ORG 0X0000
    GOTO    INICIO

    ORG 0X0004
    GOTO    ISR

; ===================================================================
; SUBRUTINA: LEER UN BYTE DE EEPROM
; ENTRADA: W = DIRECCIÓN
; SALIDA: W = DATO LEÍDO
; ===================================================================
READ_EEPROM_BYTE
    BANKSEL EEADR
    MOVWF   EEADR
    BSF     EECON1, RD
    MOVF    EEDAT, W
    BANKSEL 0
    RETURN

; ===================================================================
; SUBRUTINA: ESCRIBIR HUMEDAD_MIN EN EEPROM
; ===================================================================
WRITE_MIN_TO_EEPROM
    BANKSEL EEADR
    MOVLW   EEPROM_MIN_ADDR
    MOVWF   EEADR
    MOVF    HUMEDAD_MIN, W
    MOVWF   EEDAT
    CALL    DO_EEPROM_WRITE
    RETURN

; ===================================================================
; SUBRUTINA: ESCRIBIR HUMEDAD_MAX EN EEPROM
; ===================================================================
WRITE_MAX_TO_EEPROM
    BANKSEL EEADR
    MOVLW   EEPROM_MAX_ADDR
    MOVWF   EEADR
    MOVF    HUMEDAD_MAX, W
    MOVWF   EEDAT
    CALL    DO_EEPROM_WRITE
    RETURN

; ===================================================================
; SUBRUTINA: SECUENCIA DE ESCRITURA EN EEPROM
; ===================================================================
DO_EEPROM_WRITE
    BANKSEL EECON1
    BCF     EECON1, EEPGD
    BSF     EECON1, WREN
    MOVLW   0X55
    MOVWF   EECON2
    MOVLW   0XAA
    MOVWF   EECON2
    BSF     EECON1, WR
WAIT_EEPROM_WRITE
    BTFSC   EECON1, WR
    GOTO    WAIT_EEPROM_WRITE
    BCF     EECON1, WREN
    BANKSEL 0
    RETURN

; ===================================================================
; SUBRUTINA: LEER ADC EN AN0
; RESULTADO EN ADC_RESULT (0–255)
; ===================================================================
READ_ADC
    BANKSEL ADCON0
    BSF     ADCON0, GO
WAIT_ADC_DONE
    BTFSC   ADCON0, GO
    GOTO    WAIT_ADC_DONE
    BANKSEL ADRESH
    MOVF    ADRESH, W
    MOVWF   ADC_RESULT
    BANKSEL 0
    RETURN

; ===================================================================
; SUBRUTINA: CONFIGURAR PWM EN CCP1
; ===================================================================
SET_PWM
    BANKSEL CCPR1L
    MOVF    PWM_DUTY, W
    MOVWF   CCPR1L
    BANKSEL CCP1CON
    MOVLW   B'00001100'
    MOVWF   CCP1CON
    RETURN

; ===================================================================
; SUBRUTINA: RETARDO DE ~100MS
; ===================================================================
DELAY_100MS
    MOVLW   .100
    MOVWF   0X70
D1  MOVLW   .250
    MOVWF   0X71
D2  DECFSZ  0X71, F
    GOTO    D2
    DECFSZ  0X70, F
    GOTO    D1
    RETURN

; ===================================================================
; SUBRUTINA: VERIFICAR BOTONES RB1 (SUBIR) Y RB2 (BAJAR)
; ===================================================================
CHECK_CONFIG_BUTTONS
    BANKSEL PORTB
    BTFSS   PORTB, 1
    GOTO    BUTTON_UP
    BTFSS   PORTB, 2
    GOTO    BUTTON_DOWN
    RETURN

BUTTON_UP
    CALL    DELAY_100MS
    INCF    HUMEDAD_MIN, F
    INCF    HUMEDAD_MAX, F
    CALL    WRITE_MIN_TO_EEPROM
    CALL    WRITE_MAX_TO_EEPROM
WAIT_UP_RELEASE
    BANKSEL PORTB
    BTFSC   PORTB, 1
    GOTO    CHECK_CONFIG_BUTTONS
    GOTO    WAIT_UP_RELEASE

BUTTON_DOWN
    CALL    DELAY_100MS
    MOVF    HUMEDAD_MIN, W
    BTFSS   STATUS, Z
    DECF    HUMEDAD_MIN, F
    MOVF    HUMEDAD_MAX, W
    BTFSS   STATUS, Z
    DECF    HUMEDAD_MAX, F
    CALL    WRITE_MIN_TO_EEPROM
    CALL    WRITE_MAX_TO_EEPROM
WAIT_DOWN_RELEASE
    BANKSEL PORTB
    BTFSC   PORTB, 2
    GOTO    CHECK_CONFIG_BUTTONS
    GOTO    WAIT_DOWN_RELEASE

; ===================================================================
; SUBRUTINA: CONTROL AUTOMÁTICO DE RIEGO
; ===================================================================
CONTROL_AUTOMATICO
    CALL    READ_ADC

    ; ¿ADC < HUMEDAD_MIN?
    MOVF    HUMEDAD_MIN, W
    SUBWF   ADC_RESULT, W
    BTFSS   STATUS, C
    GOTO    RIEGO_FUERTE

    ; ¿ADC > HUMEDAD_MAX?
    MOVF    ADC_RESULT, W
    SUBWF   HUMEDAD_MAX, W
    BTFSS   STATUS, C
    GOTO    RIEGO_APAGADO

    ; ZONA INTERMEDIA: PWM MEDIO
    MOVLW   .128
    MOVWF   PWM_DUTY
    CALL    SET_PWM
    RETURN

RIEGO_FUERTE
    MOVLW   .200
    MOVWF   PWM_DUTY
    CALL    SET_PWM
    RETURN

RIEGO_APAGADO
    CLRF    PWM_DUTY
    CALL    SET_PWM
    RETURN

; ===================================================================
; INTERRUPCIÓN EXTERNA (RB0) – MODO FORZADO
; ===================================================================
ISR
    MOVWF   TEMP_W
    MOVF    STATUS, W
    MOVWF   TEMP_STATUS

    BANKSEL INTCON
    BCF     INTCON, INTF

    BANKSEL 0
    MOVLW   .200
    MOVWF   PWM_DUTY
    CALL    SET_PWM
    MOVLW   .100
    MOVWF   FORZADO_TIMER
    BSF     MODO_FORZADO, 0

    MOVF    TEMP_STATUS, W
    MOVWF   STATUS
    MOVF    TEMP_W, W
    RETFIE

; ===================================================================
; INICIALIZACIÓN
; ===================================================================
INICIO
    ; OSCILADOR INTERNO 4 MHZ
    BANKSEL OSCCON
    MOVLW   B'01100000'
    MOVWF   OSCCON

    ; CONFIGURAR PUERTOS
    BANKSEL TRISA
    BSF     TRISA, 0        ; RA0 = ENTRADA

    BANKSEL TRISC
    BCF     TRISC, 2        ; RC2 = SALIDA

    BANKSEL TRISB
    BSF     TRISB, 0        ; RB0 = ENTRADA (INT)
    BSF     TRISB, 1        ; RB1 = ENTRADA
    BSF     TRISB, 2        ; RB2 = ENTRADA

    ; PULL-UPS EN PUERTO B
    BANKSEL OPTION_REG
    BCF     OPTION_REG, NOT_RBPU

    ; CONFIGURAR ADC
    BANKSEL ANSEL
    BSF     ANSEL, 0
    BANKSEL ADCON1
    MOVLW   B'00000000'
    MOVWF   ADCON1
    BANKSEL ADCON0
    MOVLW   B'11000001'
    MOVWF   ADCON0

    ; CONFIGURAR PWM
    BANKSEL PR2
    MOVLW   .255
    MOVWF   PR2
    BANKSEL T2CON
    MOVLW   B'00000100'
    MOVWF   T2CON
    CLRF    PWM_DUTY
    CALL    SET_PWM

    ; LEER EEPROM
    MOVLW   EEPROM_MIN_ADDR
    CALL    READ_EEPROM_BYTE
    MOVWF   HUMEDAD_MIN

    MOVLW   EEPROM_MAX_ADDR
    CALL    READ_EEPROM_BYTE
    MOVWF   HUMEDAD_MAX

    ; INICIALIZAR EEPROM SI ESTÁ VACÍA
    MOVLW   0XFF
    SUBWF   HUMEDAD_MIN, W
    BTFSS   STATUS, Z
    GOTO    SKIP_EEPROM_INIT
    MOVLW   DEFAULT_MIN
    MOVWF   HUMEDAD_MIN
    MOVLW   DEFAULT_MAX
    MOVWF   HUMEDAD_MAX
    CALL    WRITE_MIN_TO_EEPROM
    CALL    WRITE_MAX_TO_EEPROM
SKIP_EEPROM_INIT

    ; HABILITAR INTERRUPCIÓN EXTERNA
    BANKSEL INTCON
    BSF     INTCON, INTE
    BSF     INTCON, GIE

    ; INICIALIZAR VARIABLES
    CLRF    MODO_FORZADO
    CLRF    FORZADO_TIMER

; ===================================================================
; BUCLE PRINCIPAL
; ===================================================================
MAIN_LOOP
    BTFSC   MODO_FORZADO, 0
    GOTO    MODO_FORZADO_ACTIVO

    CALL    CONTROL_AUTOMATICO
    CALL    CHECK_CONFIG_BUTTONS
    CALL    DELAY_100MS
    GOTO    MAIN_LOOP

MODO_FORZADO_ACTIVO
    DECFSZ  FORZADO_TIMER, F
    GOTO    ESPERA_FORZADO

    BCF     MODO_FORZADO, 0
    CLRF    PWM_DUTY
    CALL    SET_PWM

ESPERA_FORZADO
    CALL    DELAY_100MS
    GOTO    MAIN_LOOP

	END