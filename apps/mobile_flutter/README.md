# Flutter Frontend za HealthTrackMe

Responsive Flutter frontend za HealthTrackMe. Deluje v brskalniku, na Android emulatorju in na fizičnem telefonu, ko je pravilno nastavljen API URL.

## 📱 Zasloni aplikacije

1. **Domov (Dashboard)** - zdravstveni indeks, dnevni stats, zdravila, opozorila in stanje sinhronizacije
2. **Dnevnik** - vnos razpoloženja, energije, simptomov, stresa in opomb
3. **Zdravila** - seznam terapije
4. **Poročila** - mesečni povzetek s trendi
5. **Nastavitve** - nastavitev backend URL-ja in test povezave

## 🎨 Design

Aplikacija je oblikovana na podlagi mockupa s sledeči barvnega shemo:
- **Navy**: #1A3A5C (glavni)
- **Blue**: #4A90D9 (akcije)
- **Teal**: #2EC4B6 (akcenti)
- **Pisava**: DM Sans

## 📦 Setup in Installation

### Predpogoji
- Flutter SDK 3.0+
- Android Studio ali vsaj Android platform tools, če boš uporabljal emulator/telefon
- Chrome ali Edge za web testiranje

### Če platforme še niso generirane

Če v mapi še nimaš `android/`, `web/` ali drugih platformskih map, enkrat zaženi:

```bash
flutter create .
```

To ustvari manjkajoči Flutter scaffold. Potem lahko normalno uporabljaš `flutter run`, `flutter build apk` in `flutter build web`.

### Installation

```bash
# Instaliraj odvisnosti
flutter pub get

# Zaženi na računalniku v brskalniku (Chrome ali Edge)
flutter run -d chrome

# Zaženi na Android emulatorju ali telefonu
flutter run

# Build APK za Android
flutter build apk --release

# Build web verzije
flutter build web --release
```

## 🔧 Arhitektura

```
lib/
├── main.dart                 # Glavna aplikacija
├── config/
│   └── theme.dart           # Tema, barve in stili
├── screens/
│   ├── dashboard_screen.dart # Domov
│   ├── diary_screen.dart     # Dnevnik
│   └── reports_screen.dart   # Poročila
├── widgets/
│   └── widgets.dart          # Prilagojeni UI komponente
├── models/
│   └── models.dart           # Podatkovni modeli
├── services/
│   └── api_service.dart      # API integracijo s backendo
└── utils/
    └── ...                    # Pomožne funkcije
```

## 🔗 API Integracija

Aplikacija uporablja `ApiService`, ki si zapomni backend URL.

### Privzete vrednosti
- **Brskalnik / računalnik:** `http://localhost:8080/api`
- **Android emulator:** `http://10.0.2.2:8080/api`
- **Fizični telefon:** nastavi LAN IP računalnika v zavihku **Nastavitve**

Če backend teče na istem računalniku, lahko URL spremeniš v aplikaciji v zavihku **Nastavitve**.

### Uporabljeni endpoints
- `GET /api/health-entries` - Pridobi vnose o zdravju
- `POST /api/health-entries` - Ustvari nov vnos
- `GET /api/medicines` - Pridobi seznam zdravil
- `GET /api/health-alerts` - Pridobi opozorila
- `GET /api/reports/monthly` - Pridobi mesečno poročilo

Če backend trenutno ni dosegljiv, frontend uporablja demo podatke, da lahko UI še vedno preizkušaš.

## 📚 State Management

Trenutno: enostaven `ApiService` singleton + `StatefulWidget`

Priporočilo za kasnejšo nadgradnjo: Provider ali Riverpod

## 🚀 Naslednji koraki

1. [x] Implementacija osnovnih zaslonov
2. [x] Nastavitve za API URL
3. [x] Demo fallback podatki
4. [ ] Dodajanje animacij in transitions
5. [ ] Offline mode / caching za shranjene vnose
6. [ ] Unit in widget testi
7. [ ] CI/CD pipeline

## ▶️ Hiter zagon

```bash
cd apps/mobile_flutter
flutter pub get
flutter run -d chrome
```

### Na fizičnem telefonu

1. Zaženi backend na računalniku.
2. Preveri IP računalnika v lokalnem omrežju.
3. V aplikaciji odpri **Nastavitve** in vpiši URL npr. `http://192.168.1.20:8080`.
4. Shrani in klikni **Test povezave**.

### Na emulatorju

1. Android emulator naj bo zagnan.
2. Zaženi `flutter run`.
3. Če je potrebno, v **Nastavitvah** uporabi `http://10.0.2.2:8080`.

## 📝 Licence

Projekt je del praktikuma na FERI

