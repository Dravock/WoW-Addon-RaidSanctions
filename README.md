# RaidSanctions - World of Warcraft Addon

Ein professionelles World of Warcraft Addon zur Verwaltung von Raid-Sanktionen und Geldstrafen für Gilden und Raid-Gruppen.

## 📋 Übersicht

RaidSanctions ist ein umfassendes Addon, das Raid-Leitern und Gilden-Offizieren dabei hilft, Strafen für verschiedene Raid-Vergehen zu verwalten. Das Addon bietet eine benutzerfreundliche Oberfläche zur Verfolgung von Penalties, automatische Berechnung von Geldstrafen und persistente Datenspeicherung über Sessions hinweg.

## ✨ Features

### 🎯 Kernfunktionen
- **Automatische Spielererkennung**: Erkennt automatisch alle Raid- und Gruppenmitglieder
- **Vordefinierte Strafen**: Verschiedene Penalty-Kategorien mit konfigurierbaren Beträgen
- **Echtzeit-Tracking**: Live-Aktualisierung der Penalty-Zähler
- **Persistente Daten**: Speichert alle Daten zwischen Sessions
- **Intuitive UI**: Moderne, übersichtliche Benutzeroberfläche

### 💰 Penalty-System
Das Addon kommt mit vordefinierten Strafen-Kategorien:

| Kategorie | Betrag | Beschreibung |
|-----------|--------|--------------|
| **Falsche Taktik** | 30s | Für taktische Fehler |
| **Falsches Gear** | 75s | Für ungeeignete Ausrüstung |
| **Zu spät** | 1g | Für Verspätungen |
| **AFK** | 50s | Für unangekündigte Abwesenheit |
| **Störung** | 25s | Für störendes Verhalten |

### 🖥️ Benutzeroberfläche
- **Übersichtliche Tabelle**: Zeigt alle Spieler mit ihren Penalty-Zählern
- **Farbkodierung**: Visuelle Unterscheidung nach Penalty-Anzahl
- **Klassenfarben**: Spielernamen in ihrer jeweiligen Klassenfarbe
- **Aktions-Panel**: Schneller Zugriff auf alle Penalty-Kategorien
- **Auswahlsystem**: Klick-basierte Spielerauswahl für Strafen

## 🚀 Installation

### Automatische Installation (Empfohlen)
1. Lade das Addon über den CurseForge Client oder WoWUp herunter
2. Starte World of Warcraft neu
3. Aktiviere das Addon im Addon-Menü

### Manuelle Installation
1. Lade die neueste Version von GitHub herunter
2. Entpacke den Ordner nach:
   ```
   World of Warcraft\_retail_\Interface\AddOns\RaidSanctions\
   ```
3. Starte World of Warcraft neu
4. Aktiviere "RaidSanctions" in der Addon-Liste

## 🎮 Verwendung

### Grundlegende Bedienung

#### Addon öffnen
```
/rs
/sanktions
```

#### Debug-Modus (für Entwickler)
```
/rs debug
```

### Schritt-für-Schritt Anleitung

1. **Raid beitreten**: Das Addon erkennt automatisch alle Raid-/Gruppenmitglieder
2. **Addon öffnen**: Verwende `/rs` um die Hauptoberfläche zu öffnen
3. **Spieler auswählen**: Klicke auf einen Spieler in der Liste
4. **Strafe anwenden**: Klicke auf den entsprechenden Penalty-Button unten
5. **Übersicht behalten**: Verfolge alle Strafen in Echtzeit

### UI-Elemente

#### Hauptfenster
- **Spielerliste**: Zeigt alle Raid-Mitglieder mit Penalty-Zählern
- **Counter-System**: Numerische Anzeige für jede Penalty-Kategorie
- **Gesamtsumme**: Automatische Berechnung aller Strafen pro Spieler

#### Aktions-Panel
- **Penalty-Buttons**: Direkte Anwendung von Strafen auf ausgewählte Spieler
- **Tooltips**: Detaillierte Informationen zu jeder Strafe
- **Visual Feedback**: Bestätigung bei erfolgreicher Anwendung

#### Zusätzliche Features
- **Add Player**: Manuelle Hinzufügung von Spielern
- **Reset**: Zurücksetzen aller Session-Daten
- **ESC-Taste**: Schnelles Schließen des Fensters

## 🔧 Konfiguration

### Penalty-Anpassung
Die Strafen können in der `logic.lua` angepasst werden:

```lua
local penalties = {
    ["Falsche Taktik"] = 30,  -- 30 Silber
    ["Falsches Gear"] = 75,   -- 75 Silber
    ["Zu spät"] = 100,        -- 1 Gold
    ["AFK"] = 50,             -- 50 Silber
    ["Störung"] = 25,         -- 25 Silber
}
```

### Datenspeicherung
Das Addon speichert Daten in:
- **RaidSanctionsDB**: Globale Addon-Daten
- **RaidSanctionsCharDB**: Charakterspezifische Daten

## 📊 Technische Details

### Architektur
- **Modularer Aufbau**: Getrennte Module für Logic, UI und Events
- **Event-System**: Reagiert auf WoW-Events wie Gruppenwechsel
- **Persistenz**: Automatisches Speichern bei Änderungen

### Dateien
```
RaidSanctions/
├── RaidSanctions.toc     # Addon-Manifest
├── RaidSanctions.lua     # Hauptkoordinator
├── logic.lua             # Geschäftslogik
├── ui.lua               # Benutzeroberfläche
├── RaidSanctions.xml    # UI-Definitionen
└── README.md            # Diese Dokumentation
```

### Kompatibilität
- **WoW Version**: Retail (aktuelle Version)
- **Gruppengröße**: Unterstützt Solo, Gruppe (5) und Raid (40)
- **Lokalisierung**: Vorbereitet für mehrere Sprachen

## 🐛 Fehlerbehebung

### Häufige Probleme

**Problem**: Spieler werden nicht angezeigt
- **Lösung**: Verwende `/rs debug` um die Gruppenerkennung zu testen

**Problem**: Daten gehen verloren
- **Lösung**: Überprüfe ob SavedVariables korrekt geladen werden

**Problem**: UI wird nicht angezeigt
- **Lösung**: Stelle sicher, dass das Addon aktiviert ist (`/reload`)

### Debug-Kommandos
```
/rs debug          # Zeigt aktuelle Gruppenmitglieder
/reload             # Lädt alle Addons neu
```

## 🤝 Mitwirken

Beiträge sind willkommen! Bitte beachte:

1. Fork das Repository
2. Erstelle einen Feature-Branch
3. Committe deine Änderungen
4. Erstelle einen Pull Request

### Entwicklung
```bash
git clone https://github.com/Dravock/RaidSanctions.git
cd RaidSanctions
# Bearbeite die Dateien in deinem WoW AddOns Ordner
```

## 📝 Changelog

### Version 1.1
- ✅ Verbesserte UI mit Counter-System
- ✅ Bottom-Panel für Aktionen
- ✅ Automatische Listenaktualisierung
- ✅ Bessere Farbkodierung
- ✅ Optimierte Penalty-Anwendung

### Version 1.0
- 🎉 Erste Veröffentlichung
- ⚡ Grundlegende Penalty-Verwaltung
- 💾 Persistente Datenspeicherung
- 🎨 Moderne UI

## 📄 Lizenz

Dieses Projekt steht unter der MIT-Lizenz - siehe [LICENSE](LICENSE) für Details.

## 👤 Autor

**Dravock**
- GitHub: [@Dravock](https://github.com/Dravock)

## 🙏 Danksagungen

- World of Warcraft Community für Feedback und Testing
- Blizzard Entertainment für die umfangreichen Addon-APIs
- Alle Beta-Tester und Mitwirkenden

---

**⚡ Für optimale Raid-Disziplin und faire Strafen-Verwaltung!**
