# PraxisPlan

PraxisPlan ist eine kleine Lamdera-Anwendung zur gemeinsamen Terminplanung für
einen Praxisbericht. Ereignisse besitzen ein konkretes Zeitfenster, können
einmalig, semesterweise oder jährlich stattfinden und sind eindeutig Person A,
Person B oder beiden Personen gemeinsam zugeordnet.

## Lokal starten

```sh
lamdera live
```

Danach ist die Anwendung unter <http://localhost:8000> erreichbar.

## Datenmodell

Das Domänenmodell liegt in `src/Domain.elm`. Statt generischer `Dict`-Strukturen
verwendet es fachliche Typen:

- `EventId` für stabile Identitäten
- `Person` mit genau den Varianten `PersonA` und `PersonB`
- `Assignment` für A, B oder eine gemeinsame Zuständigkeit
- `Recurrence` mit `OneTime`, `EverySemester` und `EveryYear`
- `OccurrenceIndex` für den Erledigt-Status einer einzelnen Serieninstanz
- `CalendarDate`, `ClockTime`, `Moment` und `TimeWindow` für validierte Zeiträume
- `Comment` für explizit vorhandene oder fehlende Kommentare
- `EventDraft` für noch nicht persistierte und `Event` für gespeicherte Termine

Datums-, Uhrzeit- und Zeitfenster-Konstruktoren validieren ihre Eingaben. So
kann die Oberfläche kein ungültiges Datum und kein Zeitfenster speichern, dessen
Ende vor seinem Beginn liegt. Semester- und Jahrestermine werden als Regel
persistiert; konkrete Folgetermine werden daraus berechnet. Erledigte
Vorbereitungen werden als Liste von `OccurrenceIndex`-Werten am Event geführt.
Dadurch kann eine einzelne Instanz abgehakt werden, ohne die ganze Serie zu
erledigen.

Das Lamdera-Backend in `src/Backend.elm` vergibt IDs, hält die Terminliste und
synchronisiert jede Änderung an alle verbundenen Clients. Die Oberfläche in
`src/Frontend.elm` bietet Erstellen, Bearbeiten, Löschen, Suche, Filter und eine
Vorschau wiederkehrender Termine mit einzeln abhakbaren Instanzen.

## Prüfen

```sh
elm-format src --validate
lamdera check
```

Ohne konfiguriertes Lamdera-Remote kompiliert `lamdera check` die Anwendung
erfolgreich und meldet anschließend erwartungsgemäß `UNKNOWN APP`.
