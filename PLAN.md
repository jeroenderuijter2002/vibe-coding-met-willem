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
- [ ] **Stap 1: berekening**: code die het verdiende bedrag uitrekent (dag- en uurloon)
- [ ] **Stap 2: invulscherm**: "Start mijn dag" met loon, tijden en pauze
- [ ] **Stap 3: teller-scherm**: bedrag dat live oploopt
- [ ] **Stap 4: opslaan**: gegevens van vandaag bewaren, zodat ze er nog zijn als je de app sluit
- [ ] **Stap 5: widget**: "Verdiend tot nu toe: €XX,XX" op het beginscherm
- [ ] **Stap 6: taal**: Nederlands/Engels instelbaar

---

## Later (de "leuke" versie)
Ideeën, nog niet gekozen:
- Rooster per dag van de week, zodat je niet elke dag opnieuw hoeft in te vullen
- Pauze op een vast tijdstip (de teller staat dan stil tijdens de pauze)
- Live Activity op het vergrendelscherm, met een teller die per seconde meeloopt
- Grotere widget met voortgang en resterende tijd
- Geschiedenis: verdiend per week of maand
- Netto in plaats van bruto
- Mooi ontwerp, animaties en een app-icoon

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
