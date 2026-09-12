# PraxisPlan

PraxisPlan ist eine kleine Lamdera-Anwendung zur gemeinsamen Terminplanung für
einen Praxisbericht. Ereignisse besitzen ein konkretes Zeitfenster, können
einmalig oder jährlich stattfinden und sind eindeutig Antonia, Theresa oder
beiden Personen gemeinsam zugeordnet. Frei vergebbare Tags ordnen Termine
zusätzlich nach Themen.

## Lokal starten

```sh
lamdera live
```

Danach ist die Anwendung unter <http://localhost:8000> erreichbar.

## Datenmodell

Das Domänenmodell liegt in `src/Domain.elm`. Statt generischer `Dict`-Strukturen
verwendet es fachliche Typen:

- `EventId` für stabile Identitäten
- `Person` mit den stabilen Varianten `PersonA` (Antonia) und `PersonB` (Theresa)
- `Assignment` für A, B oder eine gemeinsame Zuständigkeit
- `Recurrence` mit `OneTime` und `EveryYear`
- `MonthOfYear` als geschlossener Typ für die zwölf Kalendermonate
- `OccurrenceIndex` für den Erledigt-Status einer einzelnen Serieninstanz
- `CalendarDate`, `ClockTime`, `Moment` und `TimeWindow` für validierte Zeiträume
- `Comment` für explizit vorhandene oder fehlende Kommentare
- `Tag` und `List Tag` für normalisierte, mehrfach vergebbare Schlagwörter
- `TodoId`, `TodoText` und `TodoStatus` für stabile, einzeln abhakbare Aufgaben
- `EventDraft` für noch nicht persistierte und `Event` für gespeicherte Termine

Datums-, Uhrzeit- und Zeitfenster-Konstruktoren validieren ihre Eingaben. So
kann die Oberfläche kein ungültiges Datum und kein Zeitfenster speichern, dessen
Ende vor seinem Beginn liegt. Jahrestermine werden als Regel
persistiert; konkrete Folgetermine werden daraus berechnet. Erledigte
Vorbereitungen werden als Liste von `OccurrenceIndex`-Werten am Event geführt.
Dadurch kann eine einzelne Instanz abgehakt werden, ohne die ganze Serie zu
erledigen.

Das Lamdera-Backend in `src/Backend.elm` vergibt IDs, hält die Terminliste und
synchronisiert jede Änderung an alle verbundenen Clients. Die Oberfläche in
`src/Frontend.elm` bietet Erstellen, Kopieren, Bearbeiten, Löschen, Suche,
Filter und eine Vorschau wiederkehrender Termine mit einzeln abhakbaren
Instanzen. Pro Termin lassen sich außerdem mehrere Todo-Einträge anlegen und
direkt auf der Terminkarte einzeln abhaken. Beim Kopieren werden die
Termindetails in einen neuen Entwurf übernommen; Erledigt-Zustände bleiben
bewusst beim Original. Tags werden im Editor kommasepariert gepflegt, auf den
Terminkarten angezeigt und stehen als Filter zur Verfügung.

Die Terminliste kann zusätzlich entweder nach einem Kalendermonat unabhängig
vom Jahr oder nach einem frei gewählten, inklusiven Datumsbereich gefiltert
werden. Auch monatsübergreifende Termine und berechnete Instanzen einer
Jahresserie werden berücksichtigt.

## Prüfen

```sh
elm-format src --validate
lamdera check
```

Ohne konfiguriertes Lamdera-Remote kompiliert `lamdera check` die Anwendung
erfolgreich und meldet anschließend erwartungsgemäß `UNKNOWN APP`.
