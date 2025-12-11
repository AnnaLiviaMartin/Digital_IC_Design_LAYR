# Was wir gemacht haben

## 1. Schritte
Wir haben uns entschieden ASCON zu nutzen mit einem HMAC für Encryption

## Erste Coding Versuche
Permutationen für ASCON umgesetzt, dann entschieden dass wir ein fertiges Projekt von ASCON nutzen und den Rest umsetzen.

## Testen eines Chips
Wir haben einen Counter für 5 LED's geschrieben. Diese Blinken (siehe Counter.sv). Dann haben wir ein Yosys pcf-file geschrieben mit den Befehlen zum Ausführen von Yosys. Anschließend haben wir ein weiteres file geschrieben, wo wir festlegen, welche Ports am Chip zu welchen Inputs/Outputs im Code-Modul gehören. Wir führen das yosys-file aus.