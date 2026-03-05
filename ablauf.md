# Was wir gemacht haben

## 1. Schritte
Wir haben uns entschieden ASCON zu nutzen mit einem HMAC für Encryption

## Erste Coding Versuche
Permutationen für ASCON umgesetzt, dann entschieden dass wir ein fertiges Projekt von ASCON nutzen und den Rest umsetzen. Ziel dabei war es, die Permutationen besser zu verinnerlichen, da wir dies als den schwierigsten Teil für uns von ASCON identifiziert hatten.

## Testen eines Chips
Wir haben einen Counter für 5 LED's geschrieben. Diese Blinken (siehe Counter.sv). Dann haben wir ein Yosys pcf-file geschrieben mit den Befehlen zum Ausführen von Yosys. Anschließend haben wir ein weiteres file geschrieben, wo wir festlegen, welche Ports am Chip zu welchen Inputs/Outputs im Code-Modul gehören. Yosys-file wurde ausgeführt.

## Erstellen von HMAC
- Angucken des Algorithmus ASCON + Verstehen
- Angucken des Algorithmus HMAC + Verstehen (siehe Bilder in Discord)
- Definieren von Zustandsautomaten (siehe Bilder in Discord)
- Verstehen des Ablaufes zwischen Alice und Bob/Challenge-Response-System in Verbindung mit der Nutzung von ASCON-HMAC zur Verifizierung der Message (siehe Bilder in Discord)

## Umsetzung im Code für HMAC
Es folgt eine Beschreibung der Umsetzung.
### Random Number Generator

- Ausprobieren kreativer Ansätze für einen True Number Generator

#### Idee für Pseudozufallszahlengenerator
- Speicherchip, welcher jeweils die letzte generierte Zufallszahl speichert.
- unsicher, da nicht im Chip integriert

#### Stattdessen möglicher Pseudozufallszahlengenerator
- einfacher Ring-Oszillator

### Zustandsautomat

### HMAC-Umsetzung mit allen Teilen zusammen

### Testbench für ASCON

### Software-Implementierung für Challenge-Response-System

## Weitere Inhalte für Paper
- Unterschiede bei ASCON-Versionen
- Erklärung von ASCON/HMAC/Random Number Generator
- Warum ASCON? Warum ist das gut für Kryptografie?
- Was ist LAYR?
- Was ist Open-Road
- Eigenes Vorgehen?

## Was wir weiter gemacht haben, 19.02 SPI!!!!!!!!
1. Anschließen an Device an Laptop + Raspberry
-> Analyzer testen, da darf Ground nicht ausgewählt sein, sonst wird alles falsch angezeigt
2. SPI Python Schnittstelle geschrieben
Slave und Master, Ascon und Kmasc implementierungen besorgt und zu gemeinesamen Script vereint
3. SPI Schnittstelle in SystemVerilog
Über Bitübertragungsschickt problem wegen Geschwindigkeit -> SPI zu langsam darum counter
4. SPF datei geschrieben mit makefile um leds leuchten zu lassen bei knopfdruck
Versionsprobleme von nextpnr, fpga trellis, yosys und cmake -> alles von scratch installieren aus repos auf github
5. Pins/Constraints festlegen
Nimm dir ein bekanntes Pin-Set und lege in deiner LPF vier Ports an: `spi_sck`, `spi_csn`, `spi_mosi`, `spi_miso` (und optional `clk_25mhz` fürs restliche Design). In der ULX3S-v20-LPF siehst du das Muster: `LOCATE COMP "<portname>" SITE "<pin>";` plus `IOBUF PORT "<portname>" ... IO_TYPE=LVCMOS33;` und außerdem den Clock-Constraint `FREQUENCY PORT "clk_25mhz" 25 MHZ;` als Referenz. [github](https://github.com/emard/ulx3s/blob/master/doc/constraints/ulx3s_v20.lpf)

Wichtig für den Testaufbau: Logic Analyzer GND an ULX3S GND, und die vier SPI-Signale sauber (kurze Leitungen) abgreifen; /CS brauchst du wirklich, damit der Decoder Byte-Grenzen korrekt findet. Saleae erklärt auch explizit, dass der SPI-Analyzer stark vom Enable/CS-Signal für die Ausrichtung abhängt (sonst „Alignment Issues“). [support.saleae](https://support.saleae.com/protocol-analyzers/analyzer-user-guides/using-spi)
6. Logic Analyzer richtig einstellen
In Saleae Logic 2: SPI-Analyzer hinzufügen und `Enable`=/CS, `Clock`=SCK, `MOSI`=MOSI, `MISO`=MISO zuordnen; das ist genau das Standard-Setup, das Saleae in Doku/Guides beschreibt (Enable/Clock/MOSI/MISO). [support.saleae](https://support.saleae.com/protocol-analyzers/analyzer-user-guides/using-spi)

Falls du „Müll“ dekodiert bekommst: als erstes prüfen, ob /CS wirklich während der 8 Bits low ist; ohne /CS oder mit falscher Polarität verschiebt sich die Byte-Grenze typischerweise. (Saleae nennt das als häufige Ursache für Alignment-Probleme.) [support.saleae](https://support.saleae.com/protocol-analyzers/analyzer-user-guides/using-spi)
7. Test-Skript von Python aus schreiben
Sende mit einem SPI-Master (z. B. USB‑SPI Adapter, Raspi, Arduino etc.) irgendein Byte auf MOSI (z. B. `0x00`) bei aktivem /CS und lies gleichzeitig ein Byte zurück; du solltest **immer** `0x41` sehen. Wenn du mehrere Bytes in einem /CS‑Low Burst sendest, solltest du `0x41 0x41 0x41 ...` zurückbekommen.

Welche Pins (PMOD/JPx) willst du konkret für SCK/MOSI/MISO/CS verwenden (ULX3S v2.0/v3.0, und welcher Stecker J1/J2/J3/J4)? Dann kann ich dir eine passende LPF-Minimaldatei (nur diese 4 Signale + 25 MHz clock) skizzieren.

Das haben wir geschrieben: wir senden 5x 01350 als bit mit python-skript als spi-master. der slave ist das was wir über spi implementieren folgend

## Schritt 2: Minimaler SPI-Slave „immer A“
Das folgende SystemVerilog ist absichtlich simpel: SPI Mode 0 (CPOL=0, CPHA=0), d. h. MOSI wird am steigenden SCK eingetaktet und MISO am fallenden SCK umgeschaltet, damit der Master es zum nächsten steigenden Takt stabil sieht. Wir haben daraufhin erstmal ein bereits existierendes Systemverilog SPI Skript genommen und das durchlaufen lassen. Das Skript ist von fpga4fun.com 

So sieht es aus:
"""
PI slave - HDL FPGA code
Now for the SPI slave in the FPGA.

Since the SPI bus is typically much slower than the FPGA operating clock speed, we choose to over-sample the SPI bus using the FPGA clock. That makes the slave code slightly more complicated, but has the advantage of having the SPI logic run in the FPGA clock domain, which will make things easier afterwards.

First the module declaration.

module SPI_slave(clk, SCK, MOSI, MISO, SSEL, LED);
input clk;

input SCK, SSEL, MOSI;
output MISO;

output LED;
Note that we have "clk" (the FPGA clock) and an LED output... a nice little debug tool. "clk" needs to be faster than the SPI bus. Saxo-L has a default clock of 24MHz, which works fine here.



We sample/synchronize the SPI signals (SCK, SSEL and MOSI) using the FPGA clock and shift registers.

// sync SCK to the FPGA clock using a 3-bit shift register
reg [2:0] SCKr;  always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

// same thing for SSEL
reg [2:0] SSELr;  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
wire SSEL_active = ~SSELr[1];  // SSEL is active low
wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge

// and for MOSI
reg [1:0] MOSIr;  always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
wire MOSI_data = MOSIr[1];
Now receiving data from the SPI bus is easy.

// we handle SPI in 8-bit format, so we need a 3 bits counter to count the bits as they come in
reg [2:0] bitcnt;

reg byte_received;  // high when a byte has been received
reg [7:0] byte_data_received;

always @(posedge clk)
begin
  if(~SSEL_active)
    bitcnt <= 3'b000;
  else
  if(SCK_risingedge)
  begin
    bitcnt <= bitcnt + 3'b001;

    // implement a shift-left register (since we receive the data MSB first)
    byte_data_received <= {byte_data_received[6:0], MOSI_data};
  end
end

always @(posedge clk) byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);

// we use the LSB of the data received to control an LED
reg LED;
always @(posedge clk) if(byte_received) LED <= byte_data_received[0];
Finally the transmission part.

reg [7:0] byte_data_sent;

reg [7:0] cnt;
always @(posedge clk) if(SSEL_startmessage) cnt<=cnt+8'h1;  // count the messages

always @(posedge clk)
if(SSEL_active)
begin
  if(SSEL_startmessage)
    byte_data_sent <= cnt;  // first byte sent in a message is the message count
  else
  if(SCK_fallingedge)
  begin
    if(bitcnt==3'b000)
      byte_data_sent <= 8'h00;  // after that, we send 0s
    else
      byte_data_sent <= {byte_data_sent[6:0], 1'b0};
  end
end

assign MISO = byte_data_sent[7];  // send MSB first
// we assume that there is only one slave on the SPI bus
// so we don't bother with a tri-state buffer for MISO
// otherwise we would need to tri-state MISO when SSEL is inactive

endmodule
"""

## Vorgehen wie wir es gemacht haben
zuerst senden wir mit SPI nur einen counter mit MISO zurückfließen, der zeigt dann beim ersten mal pro python sript schleife immer den counter an

als dass dann geklappt hat haben wir das abgeändert: byte_data_sent <= 1'b101; sodass immer eine 5 zurückgesendet wurde
und den counter auskommentiert: //reg [7:0] cnt;
//always @(posedge clk) if(SSEL_startmessage) cnt<=cnt+8'h1;  // count the messages

als wir dann immer eine 5 erhalten haben wollten wir einen roundtripp implementieren und immer dass mit MISO zurücksenden was wir mit MOSI erhalten haben (immer um ein byte versetzt), das hat dann auch geklappt und zwar so:
always @(posedge clk)
if(SSEL_active)
begin
  if(SSEL_startmessage)
    byte_data_sent <= 8'h05;  // first byte sent in a message is the message count
  else
  if(SCK_fallingedge)
      byte_data_sent <= 8'h00;  // after that, we send 0s
    else if(byte_data_received == 1'b101 || byte_data_received == 1'b011)begin
        byte_data_sent <= 1'h0A;
    end
    else begin
        byte_data_sent <= byte_data_received;
    end
      //byte_data_sent <= {byte_data_sent[6:0], 1'b0}; // 8'h05;
end

assign MISO = byte_data_sent[7];  // send MSB first

dann versuchen wir die werte zu verarbeiten und dann zurückzuschicken: d.h. gibt a zurück wenn 3 oder 5 gesendet werden, dabei sind wir auf massive probleme gestoßen die unten drunter erkläutert werden. wir mussten hierfür eine statemachine implementieren. welche durch verschiedene states läuft und so die erhaltenen bit die der spi slave über MOSI bekommt checken zu können. (bitte beschreiben wie das funktioniert, code ist unten)

## Was wir gelernt haben während diesem Teil des SPI umsetzen (Statemachine mit Logik von 3/5)
- protokoll begründen -> wir senden am anfang und ende immer eine 0 weil sonst werte die wir schicken verloren gehen
- zeit der clk nciht klar, dass es zwei clks sind nicht kalr -> die sind auch unterschiedlich schnell
- es gibt etwas dass sich bitzeit nennt. ein bit braucht also eine gewisse Zeit bis es übertragen wurde

### Bug 1 — Letztes Bit geht verloren
**Was ist passiert?**
Der Slave hat für jeden empfangenen Byte-Wert immer `0x05` zurückgegeben, egal welchen Wert der Master geschickt hat.

**Was war der Fehler?**
In SystemVerilog werden non-blocking assignments (`<=`) in derselben Taktflanke gleichzeitig ausgewertet. `byte_data_received` und `byte_data_received_backup` wurden beide mit `<=` geschrieben:
```sv
byte_data_received <= {byte_data_received[6:0], MOSI_data}; // letztes Bit rein
byte_data_received_backup <= byte_data_received;            // liest alten Wert!
```
Der Backup bekam deshalb immer den Zustand *vor* dem letzten Bit. Aus `0x01` wurde `0x00` im Backup → Vergleich mit `8'h0` immer wahr → immer `0x05`.

**Lösung:**
Das letzte Bit direkt in den Backup-Ausdruck einbauen:
```sv
byte_data_received_backup <= {byte_data_received[6:0], MOSI_data};
```

---

### Bug 2 — `response_ready` wird nie gecleart (Multi-Driver)

**Was ist passiert?**
Nach dem Fix von Bug 1 kamen nur noch Nullen auf MISO.

**Was war der Fehler?**
Zwei Probleme gleichzeitig: Erstens wurde `response_ready` nach dem Senden nie auf `0` zurückgesetzt, wodurch der FSM beim nächsten Byte sofort von CHECK_BYTE nach SEND_RESPONSE sprang, bevor die neue `response_byte` berechnet werden konnte. Zweitens wurde `response_sent` aus zwei verschiedenen `always`-Blöcken getrieben (Multi-Driver), was in Hardware zu undefiniertem Verhalten führt.

**Lösung:**
`response_ready` und `response_sent` beim Übergang IDLE→CHECK_BYTE zurücksetzen (nicht bei SEND_RESPONSE→IDLE, da der untere Automat zu diesem Zeitpunkt noch `response_ready==1` braucht). `response_sent` nur noch im `always_ff`-Block setzen.

---

### Bug 3 — Antwort kommt eine Byte-Periode zu spät

**Was ist passiert?**
Die Antwort auf Byte N kam nicht beim nächsten Byte N+1 an, sondern erst bei Byte N+2 — also um eine ganze Byte-Periode verschoben.

**Was war der Fehler?**
Der untere Automat lud `byte_data_sent` erst wenn `state == SEND_RESPONSE && bitcnt == 0`. Dieser Zustand trat aber erst beim *übernächsten* Byte ein, weil der State-Übergang CHECK_BYTE→SEND_RESPONSE selbst schon einen Takt kostet:

```
Byte N empfangen   → CHECK_BYTE
bitcnt==0, Byte N+1 startet → response_byte berechnet, aber SEND_RESPONSE noch nicht aktiv
bitcnt==0, Byte N+2 startet → erst jetzt state==SEND_RESPONSE → byte_data_sent geladen ✗
```

**Lösung:**
`byte_data_sent` direkt im Zustand CHECK_BYTE laden (gleiche falling edge wie die `response_byte`-Berechnung). Da non-blocking assignments `response_byte` in derselben Flanke noch nicht aktualisiert haben, wird die if/else-Logik im unteren Automaten dupliziert:
```sv
else if (state == CHECK_BYTE) begin
  if (byte_data_received_backup == 8'h3)
    byte_data_sent <= 8'h2;
  else
    byte_data_sent <= 8'h4;
end
```

---

### Bug 4 — Jedes zweite Byte wird ignoriert

**Was ist passiert?**
Bytes an ungeraden Positionen (`0x01`, `0x05`) wurden ignoriert und lieferten immer `0x00` zurück.

**Was war der Fehler?**
`byte_received` für Byte N+1 feuert am Ende von Byte N+1, also noch während der FSM im Zustand SEND_RESPONSE ist (er schickt gerade die Antwort auf Byte N). Die Bedingung für CHECK_BYTE war aber `state == IDLE && byte_received` — IDLE wurde zu diesem Zeitpunkt nie erreicht. Der erste Versuch zu fixen (`SEND_RESPONSE && response_sent && byte_received`) funktionierte nicht, weil `response_sent` erst beim `bitcnt==0` des *nächsten* Bytes gesetzt wird — also immer *nach* `byte_received`. Die beiden Signale überlappen sich zeitlich nie:

```
Ende Byte N+1:  byte_received=1,  response_sent=0  → Bedingung FALSE, Byte ignoriert
bitcnt==0 Byte N+2: byte_received=0, response_sent=1 → zu spät
```

**Lösung:**
In SEND_RESPONSE bei `byte_received` sofort zu CHECK_BYTE wechseln, **ohne** auf `response_sent` zu warten. Das ist sicher, weil der untere Automat das Ausshiften von `byte_data_sent` über `bitcnt` vollständig unabhängig vom State steuert:
```sv
else if (state == SEND_RESPONSE && byte_received) begin
    next_state <= CHECK_BYTE;
    response_ready <= 1'b0;
    response_sent  <= 1'b0;
end
```

Das war dann erstmal unser Endresultat:
'''
module SPI_slave(clk, SCK, MOSI, MISO, SSEL, LEDS);

input clk, SCK, SSEL, MOSI;
output MISO;

output logic [7 : 0] LEDS;

// slave clock
// sync SCK to the FPGA clock using a 3-bit shift register
reg [2:0] SCKr;  always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

// same thing for SSEL
reg [2:0] SSELr;  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
wire SSEL_active = ~SSELr[1];  // SSEL is active low => start bei 0
/*
wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge
*/

// and for MOSI
reg [1:0] MOSIr;  always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
wire MOSI_data = MOSIr[1];
// we handle SPI in 8-bit format, so we need a 3 bits counter to count the bits as they come in
reg [2:0] bitcnt;

reg byte_received;  // high when a byte has been received
reg [7:0] byte_data_received;
reg [7:0] byte_data_sent;
reg [7:0] byte_data_received_backup;

// oberer automat
localparam IDLE = 8'h00;
localparam CHECK_BYTE = 8'h01;
localparam SEND_RESPONSE = 8'h02;
logic [7:0] state, next_state;
reg [7:0] response_byte;
logic response_ready;
logic response_sent;

always @(posedge clk)
begin
  if(~SSEL_active)
    bitcnt <= 3'b000;
  else
  if(SCK_risingedge)
  begin
    bitcnt <= bitcnt + 3'b001;
    // implement a shift-left register (since we receive the data MSB first)
    byte_data_received <= {byte_data_received[6:0], MOSI_data};

    if (bitcnt == 3'b111) begin
      byte_data_received_backup <= {byte_data_received[6:0], MOSI_data};
      LEDS[4] <= LEDS[5] == 1;
      LEDS[5] <= 1;
    end
  end
end

always @(posedge clk) byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);

initial begin
  LEDS <= 8'b00000000;
  response_byte <= 8'h00;
end

always @(posedge clk) begin
  LEDS[7] <= 1;

  if (byte_received)
    LEDS[6] <= 1;
  
  if (state == SEND_RESPONSE)
    LEDS[2] <= 1;
  
  if (state == CHECK_BYTE)
    LEDS[1] <= 1;

  if (state == IDLE)
    LEDS[0] <= 1;
    
end

always_ff @(posedge clk) begin
    if (!SSEL_active) begin
        state <= IDLE;
        next_state <= IDLE;
        response_ready <= 1'b0;
        response_sent <= 1'b0;
    end
    else
        state <= next_state;

    if (state == IDLE && byte_received) begin
        next_state <= CHECK_BYTE;
        response_ready <= 1'b0;
        response_sent  <= 1'b0;
    end
    else if (state == CHECK_BYTE && response_ready)
        next_state <= SEND_RESPONSE;
    // FIX: In SEND_RESPONSE sofort zu CHECK_BYTE bei byte_received,
    // OHNE auf response_sent zu warten. response_sent kommt erst beim naechsten
    // bitcnt==0, also NACH byte_received – sie ueberlappen sich nie.
    // Der untere Automat shiftet byte_data_sent weiterhin unabhaengig aus.
    else if (state == SEND_RESPONSE && byte_received) begin
        next_state <= CHECK_BYTE;
        response_ready <= 1'b0;
        response_sent  <= 1'b0;
    end
    else if (state == SEND_RESPONSE && response_sent)
        next_state <= IDLE;
    
    if (SCK_fallingedge && state == CHECK_BYTE) begin
        if (byte_data_received_backup == 8'h3)
          response_byte <= 8'h2;
        else
          response_byte <= 8'h4;
        response_ready <= 1'b1;
    end

    if (SCK_fallingedge && state == SEND_RESPONSE && bitcnt == 3'b000 && response_ready)
        response_sent <= 1'b1;
end

// unterer automat
always @(posedge clk) // schnelle clk
  if (!SSEL_active)
      byte_data_sent <= 8'h00;
  else if (SCK_fallingedge) begin
      if (bitcnt != 3'b000) begin // runterrechnen von clk, nur bei langsamer clk machen wir etwas
        byte_data_sent <= {byte_data_sent[6:0], 1'b0};
      end
      // FIX: byte_data_sent direkt in CHECK_BYTE laden (gleiche Flanke wie Berechnung).
      // response_byte ist wegen non-blocking noch nicht aktuell -> Logik dupliziert.
      else if (state == CHECK_BYTE) begin
        if (byte_data_received_backup == 8'h3)
          byte_data_sent <= 8'h2;
        else
          byte_data_sent <= byte_data_received_backup;
      end
  end

assign MISO = byte_data_sent[7];  // send MSB first

endmodule
'''

## Was wir gemacht haben um bis hierher die Probleme zu lösen:
Dokumentation der Fehleranalyse und Qualitätssicherung
Um die Funktionalität des Systems sicherzustellen und Fehler in der Kommunikation sowie im Programmablauf zu isolieren, wurden folgende Maßnahmen ergriffen:

1. Hardware-Analyse via Logic Analyzer
Die primäre Überprüfung der Datenübertragung erfolgte über einen Logic Analyzer, der zwischen dem Python-Interface und dem Lattice-Board geschaltet wurde.
Fokus: Überwachung der SPI-Kommunikation (MISO und MOSI).
Ziel: Verifikation, ob die gesendeten Befehle korrekt ankommen und die erwarteten Antworten zurückgegeben werden. Dies diente als Referenzwert, um den Erfolg oder Misserfolg einzelner Operationen zweifelsfrei festzustellen.

2. Visuelles Debugging über On-Board LEDs
Für die Echtzeit-Überprüfung des Programmflusses auf dem Lattice-Board wurden die integrierten Leuchtdioden (LEDs) als Statusindikatoren genutzt:
Code-Abdeckung: Signalisierung, ob bestimmte Code-Abschnitte (Trigger-Punkte) erreicht wurden.
Logik-Prüfung: Verifikation der „Zeitmaschine“ (Timing-Logik) sowie die Bestätigung, ob Datenregister korrekt befüllt wurden.

3. Datenverwaltung in Registern
Zur strukturierten Verarbeitung der Informationen wurde das System mit mehreren 8-Bit-Registern ausgestattet. Diese dienten als Zwischenspeicher, um die Integrität der Daten während der Verarbeitungsschritte zu wahren und kontrollierbar zu machen.

4. Simulation (Optionaler Ansatz)
Es wurde zusätzlich eine Simulation erstellt, um den Code vorab zu testen.
Ergebnis: Dieser Ansatz lieferte in diesem spezifischen Fall nur begrenzten Mehrwert, da die Komplexität der Handhabung den direkten Test auf der Hardware weniger effektiv unterstützte als die Live-Analyse.
Erweiterte Strategien zur Fehlerbehebung
Wenn die automatisierten oder visuellen Tests (Simulation & LEDs) keine eindeutigen Ergebnisse lieferten, wurde auf eine intensive manuelle Analyse umgestellt:

5. Intensives Team-Review (Code-Walkthrough)
Als finale Instanz der Fehlersuche wurde eine detaillierte Code-Analyse im Drei-Augen-Prinzip durchgeführt.

Methodik: Gemeinsames Durchgehen jeder einzelnen Codezeile im Team.
Zielsetzung: * Logikfehler aufspüren, die in der Simulation nicht offensichtlich waren.
Hypothesen bilden: „Was passiert hier genau?“ vs. „Was sollte hier eigentlich nicht passieren?“
Abgleich der geschriebenen Logik mit den Hardware-Spezifikationen des Lattice-Boards.

Fallbeispiel: Fehler in der „Zeitmaschine“ (FSM)
Ein konkreter Erfolg dieser Methode war die Korrektur der Zustandssteuerung (Finite State Machine).
Das Problem: Ein logischer Fehler in einer if-else-Struktur verhinderte den korrekten Ablauf der Zustände.
Die Ursache: Ein zu breit gefasster else-Zweig führte dazu, dass das System bei jeder kleinsten Nichterfüllung einer Bedingung sofort in den IDLE-State zurücksprang.
Die Folge: Der Übergang von Zustand 2 zu Zustand 3 schlug fehl, da das System „voreilig“ zurückgesetzt wurde, bevor die Sequenz abgeschlossen war.
Die Lösung: Durch das logische „Durchspielen“ der Bedingungen im Team konnten wir diesen strukturellen Fehler identifizieren und die else-Bedingungen präzisieren, sodass die Zustandsübergänge stabil blieben.

Vorteile dieser Arbeitsweise
Schnelle Identifikation: „Einfache“, aber folgenschwere Fehler (wie der Idle-Sprung) wurden sofort sichtbar.
Logik-Check: Komplexe Abhängigkeiten konnten Schritt für Schritt im Kopf (oder am Whiteboard) simuliert werden, was flexibler war als die starre Software-Simulation.
Lerneffekt: Das gesamte Team entwickelte ein einheitliches Verständnis für die Funktionsweise der 8-Bit-Register und der Zeitsteuerung.


## Versuch 256 Bit zu übertragen
Uns war nicht bewusst dass wior 32 mal mit dem master eine 1 schicken müssen, damit alle 256 Bit übertragen werden. Als wir dass dann verstanden hatte, konnten wir alles übertragen, wir haben dafür noch eine statemachine gebaut, die nun das challenge-response-system abbildet. wir sind aber erstmal im ersten übertragungsschritt gewesen wo zuerst die challenge übertragen wird (also die 256 bit). hier haben wir zuerst nur immer eine 0 und dann ein bit des 256 bit bekommen und dann wieder eine 0 mit neuem bit. das lag aber wie gesagt daran dass unser test sktipt bei python auch immer nur 2x pro ablauf eine 1 gesendet hat

dann haben wir versucht als nächstes dass der schlüssel an das schloss den generierten hash senden kann. das hat am anfang nicht geklappt, weil wir die bits in der falschen reihnfolge gespeicht haben (little/big endian). Als wir dass dann umgedreht haben, konnten wir den hash korrekt empfangen. das skript senden dann im ersten schritt ein bit (das gibt an welchen schritt man gerade durchführt) und dann die 256 hash-bits. die kommen auch korrekt an AU?ERDEM haben wir in Zeile 177 && byte_received ergänzt weil: Bug 1 (Hauptursache): is_receiving_payload nicht mit byte_received getaktet
verilog// FALSCH – läuft jeden FPGA-Clock-Zyklus!
if (is_receiving_payload) begin
    input_payload[7 + input_payload_index * 8 : ...] <= byte_data_received_backup;
    input_payload_index <= input_payload_index + 1;
Sobald is_receiving_payload auf 1 gesetzt wird (wenn 0x03 empfangen wird), läuft dieser Block jeden FPGA-Takt durch – nicht nur wenn ein neues SPI-Byte fertig ist. Das FPGA läuft z.B. bei 50 MHz, der SPI-Takt bei 250 kHz → 200 FPGA-Zyklen pro SPI-Bit, 1600 pro Byte. In diesen 1600 Zyklen wird byte_data_received_backup (noch = 0x03, der Command-Byte) zigfach in aufeinanderfolgende input_payload-Slots geschrieben. Nach nur ~32 FPGA-Zyklen ist der Index bereits überlaufen (7 + index*8 >= 256), received_payload wird auf 1 gesetzt — aber input_payload ist komplett mit 0x03 gefüllt statt mit dem echten Payload.