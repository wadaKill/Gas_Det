\ Embedded Systems
\ GPIO Setup
\ Università degli Studi di Palermo
\ Walter Madonia matr. 0757990 LM Ingegneria Informatica, 22 - 23

\ Modalità visualizzazione esadecimale

HEX

\ Definizione Word per effettuare un ritardo necessario per la temporizzazione degli eventi che prende in 
\ input un valore positivo che viene decrementato di 1 fin quando non si azzera.

: DELAY BEGIN 1 - DUP 0 = UNTIL DROP ;

\ Definizione Base Indirizzi del BCM2837 che partono dal valore 0x3F000000

3F000000 CONSTANT BASE

\ Definizione indirizzi registri
\
\ GPFSEL0 registro per selezionare modalità delle GPIO dalla 0...9
\ GPFSEL1 registro per selezionare modalità delle GPIO dalla 10...19
\ GPFSEL2 registro per selkezionare modalità delle GPIO dalla 20...29

BASE 200000 + CONSTANT GPFSEL0
BASE 200004 + CONSTANT GPFSEL1
BASE 200008 + CONSTANT GPFSEL2

\ GPFSET0 registro per abilitare GPIO da 0...31
\ GPCLR0 registro per disabilitare GPIO da 0...31

BASE 20001C + CONSTANT GPSET0
BASE 200028 + CONSTANT GPCLR0

\ Definizioni costanti per le modalità delle GPIO utili per settare la Funzione della GPIO dove:
\
\ 001 (0x1 in Esadecimale) è il valore che permette di settare la funzione di Output della GPIO
\ 101 (0x4 in Esadecimale) è il valore che permette di settare la Alternative Function 0 della GPIO

1 CONSTANT OUTPUT
4 CONSTANT ALT0

\ Modalità visualizzazione decimale

DECIMAL

\ Definizione Word che permettono di selezionare la funzione delle GPIO
\
\ MASK permette di andare a selezionare il range di bit del registro GPFSEL(N) in base al numero della GPIO
\ OUT permette di impostare la GPIO in modalità Output
\ AF0 permette di impostare la GPIO in modalità Alternative Function 0
\ SELECT va a scrivere in memoria il valore all'indirizzo GPFSEL(N) che permetterà la selezione della GPIO 

: MASK DECIMAL SWAP 10 MOD DUP 0> IF BEGIN SWAP 3 LSHIFT SWAP 1 - DUP 0= UNTIL THEN DROP ;
: OUT OUTPUT MASK ;
: AF0 ALT0 MASK ;
: SELECT DUP ROT SWAP @ OR SWAP ! ; 

\ Definizione Word di alto livello per andare a selezionare le funzioni delle GPIO:
\
\ GPIO2 e GPIO3 in Alternative Function 0 che permetteranno l'utilizzo dei canali SDA e SCL del bus I2C
\ GPIO18, GPIO23, GPIO24 e GPIO26 in Output per l'utilizzo degli attuatori

: GPIO2_ALT0 2 AF0 GPFSEL0 SELECT ;
: GPIO3_ALT0 3 AF0 GPFSEL0 SELECT ;
: GPIO18_OUT 18 OUT GPFSEL1 SELECT ;
: GPIO23_OUT 23 OUT GPFSEL2 SELECT ;
: GPIO24_OUT 24 OUT GPFSEL2 SELECT ;
: GPIO26_OUT 26 OUT GPFSEL2 SELECT ;

\ BSC1_SET è la Word che andrà a selezionare la Alternative Function 0 per le GPIO2 e GPIO3
\ che permetteranno l'abilitazione dei canali SDA ed SCL per l'utilizzo del bus I2C

: BSC1_SET 
	GPIO2_ALT0 
	GPIO3_ALT0 ;

\ LEDS_SET è la Word che andrà a selezionare la funzione Output per le GPIO18 ,GPIO23 e GPIO24
\ che permetteranno l'abilitazione dei 3 LED collegati al sistema

: LEDS_SET 
	GPIO18_OUT 
	GPIO23_OUT 
	GPIO24_OUT ;

\ BUZZER_SET è la Word che andrà a selezionare la funzione Output per la GPIO26 che permetterà
\ l'abilitazione del Buzzer Acustico collegato al sistema

: BUZZER_SET 
	GPIO26_OUT ;

\ Modalità visualizzazione Esadecimale

HEX

\ Definizione costanti che indentificano gli attuatori del sistema in base al bit dei registri GPSET0 e GPCLR0
\
\ BLUE collegato alla GPIO18
\ GREEN collegato alla GPIO23
\ RED collegato alla GPIO24
\ BUZZER collegato alla GPIO26

40000 CONSTANT BLUE
800000 CONSTANT GREEN
1000000 CONSTANT RED
4000000 CONSTANT BUZZER

\ Definizione Word di alto livello per la gestione degli attuatori
\
\ SWITCH permette in base alla Word successiva di utilizzare i registri GPSET0 oppure GPCLR0
\ ON permette di scrivere nel registro GPSEL0 per attivare l'attuatore
\ OFF permette di scrivere nel registro GPCLR0 per disattivare l'attuatore
\ BLINK permette di effettuare un Emsissione di corrente di breve durata utile per effettuare Lampeggiamenti dei Led
\ WARNING_BLINK permette di far Lampeggiare il Led Rosso e il Buzzer acustico utile per la segnalazione della presenza di Gas captati dal sensore

: SWITCH GPSET0 GPCLR0 ;
: ON DROP ! ;
: OFF SWAP DROP ! ;
: BLINK DUP SWITCH ON 9000 DELAY SWITCH OFF 10000 DELAY ;
: WARNING_BLINK RED BUZZER OVER OVER SWITCH ON SWITCH ON 9000 DELAY SWITCH OFF SWITCH OFF 10000 DELAY ;

\ Definizione eventi degli attuatori
\
\ CLEAN_LED definisce l'evento di assenza di Gas spegnendo tutti i led e il Buzzer e tenendo acceso solo il Led Verde
\ WARNING_LED definisce l'evento di presenza di Gas facendo lampeggiare il Led Rosso e il Buzzer acustico

: CLEAN_LED 
	RED SWITCH OFF 
	BUZZER SWITCH OFF 
	GREEN SWITCH ON ;

: WARNING_LED 
	GREEN SWITCH OFF 
	WARNING_BLINK ;
