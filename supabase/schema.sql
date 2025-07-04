-- Crea la tabella dei piatti
create table public.dishes (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  price numeric(10, 2) not null,
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

-- Inserisci alcuni piatti di esempio
insert into public.dishes (name, price, category, description) values
  ('Pasta al pomodoro', 8.50, 'primi', 'Pasta con salsa di pomodoro fresco e basilico'),
  ('Risotto ai funghi', 10.00, 'primi', 'Risotto cremoso con funghi misti'),
  ('Cotoletta alla milanese', 12.50, 'secondi', 'Cotoletta di vitello impanata con patatine fritte'),
  ('Insalata mista', 6.50, 'contorni', 'Insalata fresca con pomodori, cetrioli e carote'),
  ('Acqua naturale 1L', 2.00, 'bevande', 'Acqua minerale naturale in bottiglia da 1 litro'),
  ('Coca Cola', 3.00, 'bevande', 'Lattina da 33cl'),
  ('Tiramisù', 5.00, 'dessert', 'Dolce al cucchiaio con savoiardi, caffè e mascarpone'),
  ('Panna cotta', 4.50, 'dessert', 'Panna cotta con salsa ai frutti di bosco');

-- Crea una vista per contare i piatti per categoria
create or replace view public.dishes_by_category as
select 
  category,
  count(*) as count
from public.dishes
group by category
order by 
  case category
    when 'primi' then 1
    when 'secondi' then 2
    when 'contorni' then 3
    when 'bevande' then 4
    when 'dessert' then 5
    else 6
  end;
