# ⛽ GsoilFlow — Flutter

Application mobile de gestion de ravitaillement en gasoil pour engins de chantier industriel.

---

## 🚀 Compiler via GitHub Actions

### 1. Créer le repo GitHub et pusher

```bash
git init
git add .
git commit -m "feat: GsoilFlow Flutter v1.0"
git branch -M main
git remote add origin https://github.com/TON_USER/gsoilflow.git
git push -u origin main
```

### 2. L'APK se génère automatiquement
- Aller dans **Actions** → dernier workflow → **Artifacts**
- Télécharger **gsoilflow-arm64** (pour la plupart des téléphones Android modernes)

### 3. Lancement manuel
- Onglet **Actions** → **GsoilFlow - Build Android APK** → **Run workflow**

---

## 📱 Fonctionnalités

| Écran | Description |
|---|---|
| LoginScreen | Connexion SHA-256 |
| RegisterScreen | Création de compte |
| WelcomeScreen | Stats shift en cours |
| StartShiftScreen | Index compteur + photo |
| ChooseFamilyScreen | 5 familles d'engins |
| ChooseSubfamilyScreen | 22 sous-familles |
| ChooseMachineScreen | ~350 machines + recherche |
| OperationScreen | Quantité + volucompteur + photo |
| PostOpScreen | Confirmation opération |
| EndShiftScreen | Index final + photo |
| ReportScreen | Rapport complet |
| SettingsScreen | Langue + import Excel |

---

## 🗂 Structure

```
lib/
├── main.dart
├── screens/        ← 12 écrans indépendants
├── services/       ← database, camera, pdf
├── utils/          ← theme, routes, state, language
└── widgets/        ← composants réutilisables
```

---

## 📄 Rapport PDF

- Tableau de toutes les opérations
- Photos compteurs (début/fin)
- Photos volucompteurs par machine
- Partage via WhatsApp / email / tout partage Android

---

## 🌐 Langues

Français · English · Türkçe · العربية
