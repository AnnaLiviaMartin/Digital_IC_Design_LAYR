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

## Was wir weiter gemacht haben, 19.02

1. Anschließen an Device an Laptop + Raspberry
-> Analyzer testen, da darf Ground nicht ausgewählt sein, sonst wird alles falsch angezeigt
2. SPI Python Schnittstelle geschrieben
Slave und Master, Ascon und Kmasc implementierungen besorgt und zu gemeinesamen Script vereint
3. SPI Schnittstelle in SystemVerilog
Über Bitübertragungsschickt problem wegen Geschwindigkeit -> SPI zu langsam darum counter
4. SPF datei geschrieben mit makefile um leds leuchten zu lassen bei knopfdruck
Versionsprobleme von nextpnr, fpga trellis, yosys und cmake -> alles von scratch installieren aus repos auf github
5. Erste Verbindung testen
Mach es so: Implementiere einen minimalen SPI-**Slave**, der bei jedem empfangenen Byte (egal was auf MOSI kommt) auf MISO immer ein festes Byte zurückschiebt – z. B. `8'h41` (ASCII „A“) – und verifiziere das auf dem Logic Analyzer mit SPI-Decode und sauberem /CS-Alignment. Die ULX3S-LPF-Datei zeigt dir u. a. den 25‑MHz-Clock-Port (inkl. Frequenzconstraint) und du kannst dir daran eine eigene Pinbelegung für SCK/MOSI/MISO/CS ableiten. [github](https://github.com/emard/ulx3s/blob/master/doc/constraints/ulx3s_v20.lpf)

## Schritt 1: Pins/Constraints festlegen
Nimm dir ein bekanntes Pin-Set (z. B. PMOD) und lege in deiner LPF vier Ports an: `spi_sck`, `spi_csn`, `spi_mosi`, `spi_miso` (und optional `clk_25mhz` fürs restliche Design). In der ULX3S-v20-LPF siehst du das Muster: `LOCATE COMP "<portname>" SITE "<pin>";` plus `IOBUF PORT "<portname>" ... IO_TYPE=LVCMOS33;` und außerdem den Clock-Constraint `FREQUENCY PORT "clk_25mhz" 25 MHZ;` als Referenz. [github](https://github.com/emard/ulx3s/blob/master/doc/constraints/ulx3s_v20.lpf)

Wichtig für den Testaufbau: Logic Analyzer GND an ULX3S GND, und die vier SPI-Signale sauber (kurze Leitungen) abgreifen; /CS brauchst du wirklich, damit der Decoder Byte-Grenzen korrekt findet. Saleae erklärt auch explizit, dass der SPI-Analyzer stark vom Enable/CS-Signal für die Ausrichtung abhängt (sonst „Alignment Issues“). [support.saleae](https://support.saleae.com/protocol-analyzers/analyzer-user-guides/using-spi)

## Schritt 2: Minimaler SPI-Slave „immer A“
Das folgende SystemVerilog ist absichtlich simpel: SPI Mode 0 (CPOL=0, CPHA=0), d. h. MOSI wird am steigenden SCK eingetaktet und MISO am fallenden SCK umgeschaltet, damit der Master es zum nächsten steigenden Takt stabil sieht.

```systemverilog
module spi_slave_constA (
  input  logic spi_csn,   // active low
  input  logic spi_sck,
  input  logic spi_mosi,
  output logic spi_miso
);

  logic [7:0] sh_out;
  logic [2:0] bitcnt;

  // Wenn CS high: zurücksetzen und erstes Bit vorbereiten
  always_ff @(posedge spi_csn) begin
    sh_out <= 8'h41;      // 'A'
    bitcnt <= 3'd7;
    spi_miso <= 1'b1;     // MSB von 0x41 ist 0
  end

  // Sample MOSI (optional) auf rising edge
  always_ff @(posedge spi_sck) begin
    if (!spi_csn) begin
      // du könntest hier MOSI in ein Shift-Register schieben, für den Test nicht nötig
    end
  end

  // Drive MISO auf falling edge (Mode 0)
  always_ff @(negedge spi_sck) begin
    if (!spi_csn) begin
      spi_miso <= sh_out[bitcnt];
      if (bitcnt == 0) begin
        bitcnt <= 3'd7;
        sh_out <= 8'h41;  // nach jedem Byte wieder 'A'
      end else begin
        bitcnt <= bitcnt - 1;
      end
    end
  end

endmodule
```

Hinweise:
- Das ist „good enough“ für den Logic-Analyzer- und Python-Test, aber nicht der robusteste SPI-Slave (Metastabilität/Timing/Glitches, keine SCK-Domain-Synchronisation etc.).
- Wenn dein Master in einem anderen SPI-Mode sendet (z. B. Mode 3), musst du die Flanken entsprechend tauschen.

## Schritt 3: Logic Analyzer richtig einstellen
In Saleae Logic 2: SPI-Analyzer hinzufügen und `Enable`=/CS, `Clock`=SCK, `MOSI`=MOSI, `MISO`=MISO zuordnen; das ist genau das Standard-Setup, das Saleae in Doku/Guides beschreibt (Enable/Clock/MOSI/MISO). [support.saleae](https://support.saleae.com/protocol-analyzers/analyzer-user-guides/using-spi)

Falls du „Müll“ dekodiert bekommst: als erstes prüfen, ob /CS wirklich während der 8 Bits low ist; ohne /CS oder mit falscher Polarität verschiebt sich die Byte-Grenze typischerweise. (Saleae nennt das als häufige Ursache für Alignment-Probleme.) [support.saleae](https://support.saleae.com/protocol-analyzers/analyzer-user-guides/using-spi)

## Schritt 4: Test von Python aus
Sende mit einem SPI-Master (z. B. USB‑SPI Adapter, Raspi, Arduino etc.) irgendein Byte auf MOSI (z. B. `0x00`) bei aktivem /CS und lies gleichzeitig ein Byte zurück; du solltest **immer** `0x41` sehen. Wenn du mehrere Bytes in einem /CS‑Low Burst sendest, solltest du `0x41 0x41 0x41 ...` zurückbekommen.

Welche Pins (PMOD/JPx) willst du konkret für SCK/MOSI/MISO/CS verwenden (ULX3S v2.0/v3.0, und welcher Stecker J1/J2/J3/J4)? Dann kann ich dir eine passende LPF-Minimaldatei (nur diese 4 Signale + 25 MHz clock) skizzieren.