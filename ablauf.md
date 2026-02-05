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
