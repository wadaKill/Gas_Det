\ Embedded Systems
\ I2C Driver  
\ Università degli Studi di Palermo
\ Walter Madonia matr. 0757990 LM Ingegneria Informatica, 22 - 23


\ Definizione BASE BSC1

3F804000 CONSTANT BSC1

\ Definizione registri per gestire I2C
\
\ CONTROL_REGISTER (BSC1 + 0x0)		--> C_R
\ STATUS_REGISTER (BSC1 + 0x4)		--> SR
\ DATA_LENGTH_REGISTER (BSC1 + 0x8)	--> DLR
\ SLAVE_ADDR_REGISTER (BSC1 + 0xC)	--> SAR
\ FIFO_REGISTER (BSC1 + 0x10)		--> FIFO

BSC1 0 + CONSTANT C_R
BSC1 4 + CONSTANT SR
BSC1 8 + CONSTANT DLR
BSC1 C + CONSTANT SAR
BSC1 10 + CONSTANT FIFO

\ Definizione registri per la configurazione del ADC ADS1115
\
\ CONVERT_R (0x0) permette di accedere al registro che conterrà i 16bit generati dalla conversione
\ CONFIG_R (0x1) permette di accedere al registro di configurazione del ADC sulla modalità di conversione/Gain/InputMux
\ MSB_CONFIG è il Most Significant Byte dei 16bit di configurazione del ADS1115 ( In binario 0100 0100 )
\ LSB_CONFIG è il Least Significant Byte dei 16bit di configurazione del ADS1115 ( In binario 1000 0011 )
\
\ bit[15] 	 -> Inizia una nuova conversione se è in Power State Mode
\ bit[14:12] -> Configurazione Input Multiplexer
\ bit[11:9]	 -> Configurazione Gain amplifier
\ bit[8]	 -> modalità di conversione
\ bit[7:5]	 -> Data rate
\ bit[4]	 -> Modalità comparatore
\ bit[3]	 -> Polarità comparatore
\ bit[2]	 -> Latching comparatore
\ bit[1:0]	 -> Coda comparatore e disabilitazione
\
\ I due byte ( 0x4483 in Binario 0100 0100 1000 0011) configurano il dispositivo nel modo seguente :
\ 
\ Input Multiplexer -> AIN(p) = AIN0 and AIN(n) = GND
\ Gain amplifler	-> +- 2.048 V
\ Modalità			-> Conversione continua
\ Data Rate 		-> 128 SPS
\ Comparatore		-> Traditional
\ Comp Polarity		-> Active Low
\ Latching Comp 	-> Nonlatching
\ Coda Comp 		-> Disabilitata

48 CONSTANT ADC_ADDR
00 CONSTANT CONVERT_R
01 CONSTANT CONFIG_R
44 CONSTANT MSB_CONFIG
83 CONSTANT LSB_CONFIG

\ Word per la gestione del CONTROL_REGISTER
\
\ I2C_ON setta a 1 il bit[15] che abilità I2C
\ CLEAR_FIFO setta a 10 i bit[5:4] che azzerano il contenuto del FIFO_REGISTER
\ SET_READ setta a 1 il bit[0] per indicare che il Master effettuerà un lettura dallo Slave
\ SET_WRITE setta a 0 il bit[0] per indicare che il Master effettuerò una scrittura dello Slave
\ SEND setta a 1 il bit[7] per inizializzare un Trasferimento I2C ed inviando una START Condition

: I2C_ON 8000 C_R @ OR C_R ! ;

: CLEAR_FIFO 10 C_R @ OR C_R ! ;

: SET_READ 1 C_R @ OR C_R ! ;

: SET_WRITE 0 C_R @ OR C_R ! ;

: SEND 80 C_R @ OR C_R ! ;

\ Word per la gestione dello STATUS_REGISTER
\
\ RESET setta a 1 i bit[9:8 , 1 ] per resettare lo Status del Trasferimento
\ 
\ ?FIFO_EMPTY effettua il controllo del valore dello STATUS_REGISTER e se esso è pari a 51 (HEX) oppure 0101 0001 (BINARIO) riporta sullo Stack il valore 0
\ che permetterà l'uscita dal ciclo della Word successiva ignorando i restanti bit[31:10] in quanto da documentazione viene riportato : "Write as 0, read as don't care" . 
\ In questo caso il valore 0101 0001 indica che:
\
\ bit[0] -> settato a 1 indica che il Trasferimento è attivo e in corso.
\ bit[1] -> settato a 0 indica che il Trasferimento non è ancora completato.
\ bit[4] -> settato a 1 indica che la FIFO ha spazio libero per almeno 1 Byte .
\ bit[6] -> settato a 1 indica che la FIFO è vuota.
\
\ CHECK_EMPTY word che effettua un ciclo leggendo ad ogni iterazione il valore dello STATUS_REGISTER ed effettua il controllo con ?FIFO_EMPTY attendendo come uscita
\ il valore 0 generato da ?FIFO_EMPTY
\
\ COMPLETE word che effettua un ciclo leggendo ad ogni iterazione il valore dello STATUS_REGISTER e controllando se il suo valore sia pari a 52 (HEX) oppure 0101 0010 (Binario)
\ In questo caso il valore 0101 0010 indica che :
\
\ bit[0] -> settato a 0 indica che il trasferimento non è attivo.
\ bit[1] -> settato a 1 indica che il Trasferimento è stato completato e dunque è stata inviata una STOP Condition.
\ bit[4] -> settato a 1 indica che la FIFO ha spazio libero per almeno 1 Byte.
\ bit[6] -> settato a 1 indica che la FIFO è vuota.

: RESET 302 SR @ OR SR ! ;

: ?FIFO_EMPTY 51 AND 51 = IF 0 THEN ;

: CHECK_EMPTY 
	BEGIN SR @ ?FIFO_EMPTY 0= UNTIL ;

: COMPLETE 
	BEGIN SR @ 52 AND 52 = UNTIL ;

\ Word per la gestione del FIFO_REGISTER
\
\ WRITE_FIFO word che scrive 1 byte all'interno del FIFO_REGISTER
\ READ_FIFO word che legge 1 byte all'interno del FIFO_REGISTER

: WRITE_FIFO FIFO ! ;

: READ_FIFO FIFO @ ;

\ Word per la gestione del DATA_LENGTH_REGISTER e SLAVE_ADDRESS_REGISTER
\
\ DATA_LEN permette di scrivere nel DATA_LENGTH_REGISTER per definire la quantità di Byte da Inviare/Ricevere durante il trasferimento
\ SLAVE_ADDR permette di scrivere nel SLAVE_ADDRESS_REGISTER il Byte che definisce l'indirizzo dello Slave

: DATA_LEN DLR @ OR DLR ! ;
: SLAVE_ADDR SAR @ OR SAR ! ;

\ Word di alto livello per la configurazione e gestione del Trasferimento I2C
\
\ SETUP_I2C legge sullo Stack il valore che definisce il numero di Byte da Leggere/Scrivere durante il Trasferimento e lo passa a DATA_LEN
\ poi effettua un reset dello STATUS_REGISTER con RESET, pulisce il FIFO_REGISTER con CLEAR_FIFO e scrive il valore dell'indirizzo dello SLAVE
\ nello SLAVE_ADDR_REGISTER


: SETUP_I2C 
	DATA_LEN 
	RESET 
	CLEAR_FIFO 
	ADC_ADDR SLAVE_ADDR ;

\ CONFIG_ADC prepara ed inizializza il primo trasferimento per la scrittura da parte del Master dei 3 Byte necessari a configurare ADS1115
\ 1° Byte è l'indirizzo del CONFIG_REGISTER del ADS1115
\ 2° Byte è il MSB della Configurazione dell'ADC
\ 3° Byte è il LSB della Configurazione dell'ADC
\ Ad ogni Byte inviato si effettua il controllo della FIFO assicurandosi che il trasferimento sia ancora attivo e di conseguenza scrivere il Byte
\ successivo pronto per essere inviato

: CONFIG_ADC 
	3 SETUP_I2C SET_WRITE CONFIG_R WRITE_FIFO SEND 
	CHECK_EMPTY MSB_CONFIG WRITE_FIFO 
	CHECK_EMPTY LSB_CONFIG WRITE_FIFO ;

\ ACCESS_ADC prepara ed inizializza il secondo trasferimento per la scrittura da parte del Master di 1 Byte necessario per accedere al
\ CONVERT_REGISTER del ADS1115 che conterrà il valore della conversione effettuata. Il Byte è l'indirizzo del CONVERT_REGISTER

: ACCESS_ADC 
	1 SETUP_I2C 
	SET_WRITE 
	CONVERT_R WRITE_FIFO SEND ;

\ READ_ADC prepara ed inizializza il terzo trasferimento per la lettura dello Slave da parte del Master necessario per la lettura
\ della conversione. In questo caso le letture saranno 2 poichè ADS1115 trasferisce 1 Byte alla volta dei 16bit generati dalla conversione.

: READ_ADC 
	2 SETUP_I2C 
	SET_READ SEND ;

\ ADC_SETUP Word di alto livello che :
\ Abilità I2C con I2C_ON ;
\ Configura ADS1115 con CONFIG_ADC ;
\ Richiede l'accesso al CONVERT_REGISTER di ADS1115 ;
\ Per ogni trasferimento effettua il controllo del trasferimento completato con COMPLETE . 


: ADC_SETUP 
	I2C_ON 
	CONFIG_ADC COMPLETE 
	ACCESS_ADC COMPLETE ;

\ READ Word di alto livello per effettuare la lettura della FIFO durante il trasferimento che con un apposito Delay che permette di temporizzare le fasi di
\ riempimento della FIFO per la ricezione dei 16 bit della conversione in 2 step di lettura della FIFO da 1 Byte ciascuno.

: READ 
	READ_ADC 100 DELAY READ_FIFO 100 DELAY READ_FIFO ;

\ VALUE_ADC Word che unisce i due Byte ricevuti in un unico Valore a 16 bit

: VALUE_ADC 
	SWAP 8 LSHIFT SWAP OR ;
