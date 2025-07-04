-- Elimina le tabelle se esistono già (attenzione: cancellerà tutti i dati esistenti)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;

-- Crea la tabella degli ordini
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  total DECIMAL(10, 2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_by UUID REFERENCES auth.users(id) DEFAULT auth.uid()
);

-- Crea la tabella degli articoli dell'ordine
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  dish_id UUID NOT NULL,
  dish_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crea una funzione per creare un ordine con i relativi articoli
CREATE OR REPLACE FUNCTION create_order_with_items(
  p_order_id UUID,
  p_total DECIMAL(10, 2),
  p_status TEXT,
  p_items JSONB
) RETURNS JSONB AS $$
DECLARE
  item JSONB;
  order_item JSONB;
  order_items JSONB[];
BEGIN
  -- Inserisci l'ordine
  INSERT INTO orders (id, total, status)
  VALUES (p_order_id, p_total, p_status)
  RETURNING jsonb_build_object(
    'id', id,
    'total', total,
    'status', status,
    'created_at', created_at
  ) INTO order_item;
  
  -- Debug: stampa i dati ricevuti
  RAISE NOTICE 'Ordine % inserito con totale %', p_order_id, p_total;
  
  -- Inserisci gli articoli dell'ordine
  FOR item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    RAISE NOTICE 'Inserimento articolo: %', item;
    
    INSERT INTO order_items (order_id, dish_id, dish_name, quantity, price, notes)
    VALUES (
      p_order_id,
      (item->>'dishId')::UUID,
      item->>'dishName',
      (item->>'quantity')::INTEGER,
      (item->>'price')::DECIMAL(10, 2),
      item->>'notes'
    );
  END LOOP;
  
  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'items_count', jsonb_array_length(p_items)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crea un policy per consentire la lettura/scrittura solo ai propri ordini
CREATE POLICY "Users can view their own orders" 
ON orders FOR SELECT 
USING (auth.uid() = created_by);

CREATE POLICY "Users can insert their own orders" 
ON orders FOR INSERT 
WITH CHECK (auth.uid() = created_by);

-- Abilita RLS sulla tabella orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;