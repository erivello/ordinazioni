# Food Order App

Un'applicazione Flutter per la gestione degli ordini in un ristorante o sagra. L'app permette ai clienti di sfogliare il menù, selezionare i piatti desiderati e visualizzare il totale dell'ordine.

## Funzionalità

- Visualizzazione del menù organizzato per categorie
- Aggiunta/rimozione di piatti dall'ordine
- Calcolo automatico del totale
- Interfaccia utente intuitiva
- Integrazione con Supabase per il backend

## Prerequisiti

- Flutter SDK (versione >=3.0.0)
- Dart SDK (versione >=2.17.0 <4.0.0)
- Un account Supabase

## Configurazione

1. Clona il repository:
   ```bash
   git clone [URL_DEL_REPOSITORY]
   cd food_order_app
   ```

2. Installa le dipendenze:
   ```bash
   flutter pub get
   ```

3. Crea un file `.env` nella cartella principale del progetto e aggiungi le tue credenziali Supabase:
   ```
   SUPABASE_URL=your_supabase_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```

4. Assicurati che il tuo database Supabase abbia una tabella `dishes` con la seguente struttura:
   ```sql
   create table public.dishes (
     id uuid default gen_random_uuid() primary key,
     name text not null,
     price numeric not null,
     category text not null check (category in ('primi', 'secondi', 'contorni', 'bevande', 'dessert')),
     description text,
     image_url text,
     created_at timestamp with time zone default now()
   );
   
   -- Abilita RLS (Row Level Security)
   alter table public.dishes enable row level security;
   
   -- Crea policy per permettere le query pubbliche
   create policy "Public dishes are viewable by everyone"
     on public.dishes for select
     using (true);
   ```

## Esecuzione

1. Assicurati di avere un emulatore in esecuzione o un dispositivo connesso
2. Esegui l'applicazione:
   ```bash
   flutter run
   ```

## Struttura del progetto

- `lib/`
  - `models/` - Modelli dei dati
    - `dish.dart` - Modello del piatto
    - `dish_category.dart` - Enumerazione delle categorie di piatti
  - `providers/` - Gestione dello stato con Provider
    - `order_provider.dart` - Gestisce lo stato dell'ordine
  - `screens/` - Schermate dell'applicazione
    - `order_screen.dart` - Schermata principale dell'ordinazione
  - `services/` - Servizi per la gestione dei dati
    - `menu_service.dart` - Servizio per il recupero dei piatti da Supabase
  - `main.dart` - Punto di ingresso dell'applicazione

## Dipendenze principali

- `provider`: Per la gestione dello stato
- `supabase_flutter`: Per l'integrazione con Supabase
- `flutter_dotenv`: Per la gestione delle variabili d'ambiente
- `uuid`: Per la generazione di ID univoci
- `intl`: Per la formattazione di numeri e date

## Licenza

Questo progetto è concesso in licenza con la licenza MIT - vedi il file [LICENSE](LICENSE) per i dettagli.
