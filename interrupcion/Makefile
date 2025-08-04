# MPLAB IDE generated this makefile for use with GNU make.
# Project: interrupciones2.mcp
# Date: Tue Apr 22 15:41:08 2025

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

interrupciones.cof : interrupciones.o
	$(CC) /p16F887 "interrupciones.o" /u_DEBUG /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /o"interrupciones.cof" /M"interrupciones.map" /W /x

interrupciones.o : interrupciones.asm ../../../../Program\ Files\ (x86)/Microchip/MPASM\ Suite/P16F887.INC
	$(AS) /q /p16F887 "interrupciones.asm" /l"interrupciones.lst" /e"interrupciones.err" /d__DEBUG=1

clean : 
	$(CC) "interrupciones.o" "interrupciones.hex" "interrupciones.err" "interrupciones.lst" "interrupciones.cof"

