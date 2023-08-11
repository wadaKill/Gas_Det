\ Embedded Systems
\ Main
\ Università degli Studi di Palermo
\ Walter Madonia matr. 0757990 LM Ingegneria Informatica, 22 - 23

\ Definizioni word di alto livello per l'inizializzazione del sistema
\
\ SETUP_DETECTOR effettua tutte le operazioni di configurazione del sistema
\ START word di alto livelllo che inizializza il sistema partendo dalla Fase di Configurazione seguita da quella di Calibrazione ed in fine quella di Scansione.


: SETUP_DETECTOR 
	DECIMAL 
	BSC1_SET 
	LEDS_SET 
	BUZZER_SET
	HEX 
	ADC_SETUP ;

: START 
	SETUP_DETECTOR 
	CALIBRATION 
	SCANNER ;
