# Plan: geld-tracker met iPhone-widget

Een iPhone-app waarmee je live ziet hoeveel geld je vandaag al verdiend hebt, met een widget op je beginscherm.

**Aanpak:** eerst een simpele versie die werkt. Daarna maken we er een leuke app van.

---

## Basisversie

### Wat de app doet
1. Je opent de app en tikt op **"Start mijn dag"**.
2. Je vult de gegevens van vandaag in:
   - **Loon**: je kiest **dagloon** of **uurloon** en vult het bedrag in
   - **Begintijd** en **eindtijd**
   - **Pauze**: hoeveel minuten (onbetaald), zelf in te vullen
3. Daarna loopt de teller: je ziet je verdiende bedrag live oplopen.
4. Op je beginscherm staat een widget met:
   **"Verdiend tot nu toe: €XX,XX"**

### Berekening
- **Werktijd** = eindtijd − begintijd − pauze
- **Dagloon:** verdiend = dagloon × (gewerkte tijd ÷ totale werktijd)
- **Uurloon:** verdiend = uurloon × gewerkte uren
- Voor de begintijd: €0. Na de eindtijd: het volle bedrag van die dag.
- In de basisversie tellen we de pauze simpel als "de werktijd is korter". We houden niet bij *wanneer* de pauze precies is.

### Taal
- Nederlands en Engels, in te stellen in de app.

### Widget
- Kleine widget, met alleen het bedrag.
- Ververst ongeveer elke minuut. Vaker laat Apple niet toe.

---

## Stappen (afvinken als het af is)

- [x] **Stap 0: voorbereiding**
  - [x] Xcode installeren (Mac App Store)
  - [x] Xcode-project aanmaken: app + widget-extensie (via XcodeGen, zie onder)
  - [x] Lege app draait op de iPhone (+ voorbeeld-widget op het beginscherm)
- [x] **Stap 1: berekening**: code die het verdiende bedrag uitrekent (dag- en uurloon). Zie `Shared/WorkDay.swift`
- [x] **Stap 2: invulscherm**: "Start mijn dag" met loon, tijden en pauze
- [x] **Stap 3: teller-scherm**: bedrag dat live oploopt
- [x] **Stap 4: opslaan**: gegevens van vandaag bewaren, zodat ze er nog zijn als je de app sluit
- [x] **Stap 5: widget**: "Verdiend tot nu toe: €XX,XX" op het beginscherm
- [x] **Stap 6: taal**: Nederlands/Engels instelbaar

---

## Later (de "leuke" versie)
Ideeën, nog niet gekozen:
- Rooster per dag van de week, zodat je niet elke dag opnieuw hoeft in te vullen
- Pauze op een vast tijdstip (de teller staat dan stil tijdens de pauze)
- [x] "Start nu"-knop: dag direct laten beginnen
- [x] Eén "Start mijn dag"-knop die je ingevulde begintijd volgt: start je later (bijv. 7:30 i.p.v. 7:00),
  dan telt de teller terug vanaf 7:00 en loopt hij gelijk met je echte werkdag. "Begin nu" blijft als uitzondering.
- [x] Live Activity op het vergrendelscherm + Dynamic Island (balk en afteller lopen live; bedrag kan niet live)
- [x] Widget met live voortgangsbalk en afteller, ook in middelgroot formaat
- [x] Reizen: kilometervergoeding (km × tarief, standaard €0,23) en betaalde reistijd (eigen uurtarief, of je uurloon).
  Staat in één keer op de teller zodra je dag begint; wordt onthouden voor de volgende dag.
- [x] Reistijd instellen met een tijdwiel (uren + minuten) i.p.v. +/- per 5 minuten
- [x] Voor zzp'ers: tarief is ex BTW, kies 21% / 9% / 0%. Teller toont groot ex BTW en klein incl BTW
  (BTW over loon én reisvergoeding). Levels en streak tellen met ex BTW.
- [x] Onbetaalde reistijd: bijv. het eerste uur reistijd per dag wordt niet betaald
- Geschiedenis: verdiend per week of maand
- Netto in plaats van bruto
- [x] Money game-ontwerp: donker/goud thema, muntenstapels (1 munt = 1% van je dag) met vallende munten,
  mijlpalen (25/50/75/100%) met confetti, levels op basis van totaal verdiend, streak 🔥
- [x] App-icoon (gemaakt met `tools/make_icon.swift`) + widget en Live Activity in dezelfde goud/groen-stijl

---

## Techniek
- **Taal:** Swift + SwiftUI
- **Widget:** WidgetKit
- **Gegevens delen tussen app en widget:** App Group (gedeelde opslag)
- **Vertalingen:** String Catalog (`Localizable.xcstrings`)
- **Project:** gemaakt met [XcodeGen](https://github.com/yonaskolb/XcodeGen) uit `project.yml`.
  Nieuwe bestanden of targets toegevoegd? Pas `project.yml` aan en draai `xcodegen generate`.
  Installeren: `brew install xcodegen`
- **Op je iPhone zetten:** gratis met je Apple ID (opnieuw installeren na 7 dagen), of €99 per jaar voor een developer-account
