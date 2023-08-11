\ Embedded Systems
\ Gas Detection
\ Università degli Studi di Palermo
\ Walter Madonia matr. 0757990 LM Ingegneria Informatica, 22 - 23
\
\ Nel seguente codice sorgente vengono effettuate tutte le operazioni matematiche correlate al Partitore di Tensione e al grafico delle curve
\ dei Gas presente nella documentazione del sensore MQ-2
\
\ FORMULE DI RIFERIMENTO:
\ 
\ Formula 1 :
\
\ RS / RL = ( Vin - Vout ) / Vout
\
\ Formula 2 :
\
\ RS / R0 = 9.83
\ 
\ Formula 3 :
\
\ ConversionVoltage = 2.048 * (Data Code / 2^15 )
\
\ Non potendo effettuare operazioni in Virgola fissa le operazioni sono state portate in scala superiore moltiplicando tutti i numeri *1000
\ in modo da eliminare la virgola.


\ Definizioni Variabili necessarie per la fase di Calibrazione e di Scansione del Sistema:
\
\ R0_AIR è il valore di R0 cioè il valore della Resistenza del Sensore MQ-2 calcolata in totale assenza di Gas e dunque con la sola "Aria Pulita"
\ WARNING è la soglia di avvertenza che determina la presenza di Gas e l'esecuzione dell'evento di segnalazione
\ SUM è la somma dei campioni prelevati durante la fase di Calibrazione che permetterà il calcolo del valore di tensione medio

VARIABLE R0_AIR
VARIABLE WARNING
VARIABLE SUM 0 SUM !

\ Modalità di visualizzazione Decimale

DECIMAL

\ Definizioni dei valori costanti da utilizzare per il calcolo del valore di tensione e di resistenza del sistema
\
\ RL è la Resistenza di Carico prodotta dal Potenziometro installato nel Modulo con il sensore MQ-2 dal valore costante di 5 kOhm.
\ LPG_TRESHOLD è il valore del rapporto RS/R0 corrispondente al minimo valore di concentrazione di Gas (PPM) per la curva del Gas LPG (chiamato anche GPL) 
\              riportato nel grafico della documentazione del sensore MQ-2.
\ VCC è il valore di Tensione in ingresso nel sensore MQ-2 che è stato riscalato nel range +-2.048 dall'ADC

5000 CONSTANT RL
1620 CONSTANT LPG_TRESHOLD
2048 CONSTANT VCC

\ Definizione word per il calcolo delle Resistenze e dei Valori di tensione del sistema:
\
\ RS è la word che effettua il calcolo della Resistenza del Sensore MQ-2 dalla formula (1) : RS = [(Vin - Vout) / Vout] * RL
\ R0 è la word che calcola il valore della Resistenza del sensore in assenza di Gas dalla formula (2) : R0 = RS / 9.83 
\ RS1 è la word che permette di calcolare RS avendo già trovato R0 dalla formula : RS = 1.62 * R0
\ VOLT_LIMIT è la word che calcola in corrispondenza del LPG_TRESHOLD il valore della tensione 
\            che verrà utilizzato come limite di avvertenza dalla formula (1) : Vout = Vin * RL / (RS + RL)  

: RS DUP VCC SWAP - SWAP / RL * ;

: R0 9830 / R0_AIR ! ;

: RS1 R0_AIR @ * ;

: VOLT_LIMIT RL + VCC RL * SWAP / ;

\ Modalità di visualizzazione in Esadecimale

HEX

\ Definizioni Word per la conversione del valore di tensione convertito dall'ADS1115 utilizzando la Formula (3)
\
\ DC>VOLT effettua la conversione dal DataCode generato dall'ADC al suo corrispettivo Valore di Tensione
\ VOLT>DC effettua la conversione inversa dal valore di tensione al DataCode 

: DC>VOLT 4 RSHIFT ;

: VOLT>DC 4 LSHIFT ;

\ Definizioni word per la fase di calibrazione:
\
\ MEAN è la word che effettua il calcolo della media aritmetica
\ SAMPLES è la word che attraverso un ciclo preleva 100 campioni e li mette nello Stack

: MEAN 1 BEGIN SWAP SUM +! 1 + DUP 64 > UNTIL 1 - SUM @ SWAP / ;

: SAMPLES 0 BEGIN BLUE BLINK READ VALUE_ADC SWAP 1 + DUP 64 = UNTIL DROP ;

\ Definizioni Word di alto livello per le fasi di calibrazione:
\
\ SET_AIR permette di prelevare 100 campioni in assenza di Gas ed effettua una media dei valori generati dall'ADC 
\         per poi andare a calcolare i valori di RS e R0 in assenza di Gas
\ SET_WARNING permette di calcolare e di impostare il valore di tensione corrispondente alla soglia di avvertenza
\ CALIBRATION effettuat tutta la fase di Calibrazione attraverso le word precedenti
\ ?CLEAN è la word che definisce l'evento di Assenza di Gas confrontando il valore di tensione attuale con quello di soglia
\ ?WARNING è la word che definisce l'evento di Presenza di Gas confrontando il valore di tensione attuale con quello di soglia
\ SCANNER è la word di alto livello che attraverso un ciclo infinito inizializza la fase di Scansione del Sistema dopo la calibrazione.

: SET_AIR 
    SAMPLES 
    MEAN 
    DC>VOLT
    DECIMAL RS R0 ;

: SET_WARNING 
    DECIMAL 
    LPG_TRESHOLD 
    RS1 
    VOLT_LIMIT 
    HEX VOLT>DC 
    WARNING ! ;

: CALIBRATION 
    SET_AIR 
    SET_WARNING ;

: ?CLEAN DUP WARNING @ < IF CLEAN_LED THEN ;

: ?WARNING DUP DUP WARNING @ > IF WARNING_LED THEN DROP ;

: SCANNER 
    BEGIN READ VALUE_ADC DC>VOLT DECIMAL HEX VOLT>DC ?WARNING ?CLEAN DROP CR 0 UNTIL ;
