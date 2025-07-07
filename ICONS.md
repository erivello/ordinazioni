# Personalizzazione delle icone

Questa guida spiega come personalizzare le icone dell'applicazione.

## Requisiti

- Un'immagine quadrata con dimensioni minime di 1024x1024 pixel
- Flutter SDK installato
- Pacchetto `flutter_launcher_icons` (già incluso nel progetto)

## Passaggi per generare le icone

1. **Prepara l'immagine**
   - Assicurati che l'immagine sia in formato PNG con sfondo trasparente
   - L'immagine dovrebbe essere quadrata (1:1 aspect ratio)
   - Dimensioni consigliate: 1024x1024px

2. **Posiziona l'immagine**
   - Crea una cartella `assets/icon/` nella radice del progetto (se non esiste già)
   - Copia il tuo file immagine in questa cartella con il nome `icon.png`

3. **Genera le icone**
   Esegui i seguenti comandi nel terminale:
   ```bash
   # Installa le dipendenze (se non già fatto)
   flutter pub get

   # Genera le icone per tutte le piattaforme
   flutter pub run flutter_launcher_icons
   ```

4. **Ricompila l'app**
   - Per Android: `flutter clean && flutter build apk`
   - Per iOS: `flutter clean && flutter build ios`

## Note importanti

- Le icone generate non sono incluse nel repository Git (vedi `.gitignore`)
- Dopo aver generato le icone, verranno create automaticamente le varie dimensioni necessarie
- Su iOS, potrebbe essere necessario pulire la build (`Product > Clean Build Folder` in Xcode) per vedere le modifiche

## Personalizzazione avanzata

Se hai bisogno di personalizzazioni aggiuntive, puoi modificare la sezione `flutter_launcher_icons` nel file `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: "launcher_icon"  # Nome della risorsa Android
  ios: true                 # Genera icone per iOS
  remove_alpha_ios: true    # Rimuovi canale alfa per iOS
  image_path: "assets/icon/icon.png"  # Percorso dell'immagine sorgente
```

Per ulteriori opzioni, consulta la [documentazione ufficiale](https://pub.dev/packages/flutter_launcher_icons).
