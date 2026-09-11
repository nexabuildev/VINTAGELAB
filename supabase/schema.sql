-- ============================================================
-- VINTAGE LAB — Esquema completo de Supabase
--
-- Reconstruido a partir de cómo el código de src/ usa cada tabla,
-- porque el proyecto original de Supabase se creó a mano en el
-- dashboard y nunca se versionó. Pégalo entero en el SQL Editor
-- de un proyecto Supabase nuevo y ejecútalo una sola vez.
--
-- Es seguro volver a ejecutarlo si una vez falló a medias: primero
-- limpia cualquier resto de una ejecución anterior y luego crea todo
-- de nuevo dentro de una única transacción (si algo falla, no se
-- aplica nada).
-- ============================================================

-- ------------------------------------------------------------
-- LIMPIEZA (por si una ejecución anterior falló a medias)
-- ------------------------------------------------------------
drop table if exists public.comentarios_showcase cascade;
drop table if exists public.videos_showcase cascade;
drop table if exists public.outfits cascade;
drop table if exists public.favoritos cascade;
drop table if exists public.pujas cascade;
drop table if exists public.raffles cascade;
drop table if exists public.cupones cascade;
drop table if exists public.ofertas cascade;
drop table if exists public.mensajes cascade;
drop table if exists public.notificaciones cascade;
drop table if exists public.armario_virtual cascade;
drop table if exists public.seguidores cascade;
drop table if exists public.resenas cascade;
drop table if exists public.pedido_items cascade;
drop table if exists public.pedidos cascade;
drop table if exists public.historial_precios cascade;
drop table if exists public.productos cascade;
drop table if exists public.vendedores cascade;

drop policy if exists "fotos_lectura_publica" on storage.objects;
drop policy if exists "fotos_subida_autenticados" on storage.objects;
drop policy if exists "tienda_media_lectura_publica" on storage.objects;
drop policy if exists "tienda_media_subida_autenticados" on storage.objects;

begin;

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- TABLAS
-- ------------------------------------------------------------

create table public.vendedores (
  id uuid primary key default gen_random_uuid(),
  id_usuario uuid not null unique references auth.users(id) on delete cascade,
  nombre_tienda text not null,
  razon_registro text,
  metas text,
  descripcion text,
  avatar_url text,
  banner_url text,
  color_fondo text,
  layout_id int default 1,
  comision_actual numeric default 15.0,
  ventas_totales numeric default 0,
  esta_verificado boolean default false,
  creado_el timestamptz default now()
);

create table public.productos (
  id uuid primary key default gen_random_uuid(),
  id_vendedor uuid not null references public.vendedores(id) on delete cascade,
  nombre text not null,
  descripcion text,
  precio numeric not null,
  precio_inicial numeric,
  categoria text,
  talla text,
  imagen_url text,
  imagenes_extra jsonb,
  destacado boolean default false,
  ventas_count int default 0,
  es_subasta boolean default false,
  fecha_fin_subasta timestamptz,
  fecha_lanzamiento timestamptz,
  creado_el timestamptz default now()
);
create index on public.productos (id_vendedor);

create table public.historial_precios (
  id uuid primary key default gen_random_uuid(),
  id_producto uuid not null references public.productos(id) on delete cascade,
  precio numeric not null,
  fecha timestamptz default now()
);
create index on public.historial_precios (id_producto);

create table public.pedidos (
  id uuid primary key default gen_random_uuid(),
  id_usuario uuid not null references auth.users(id) on delete cascade,
  total numeric not null,
  estado text default 'Preparando',
  legit_check boolean default false,
  tracking_url text,
  nombre_cliente text,
  direccion text,
  creado_el timestamptz default now()
);
create index on public.pedidos (id_usuario);

create table public.pedido_items (
  id uuid primary key default gen_random_uuid(),
  id_pedido uuid not null references public.pedidos(id) on delete cascade,
  id_producto uuid not null references public.productos(id) on delete cascade,
  precio numeric not null
);
create index on public.pedido_items (id_pedido);
create index on public.pedido_items (id_producto);

create table public.resenas (
  id uuid primary key default gen_random_uuid(),
  id_comprador uuid not null references auth.users(id) on delete cascade,
  id_vendedor uuid not null references public.vendedores(id) on delete cascade,
  id_pedido uuid not null references public.pedidos(id) on delete cascade,
  puntuacion smallint not null check (puntuacion between 1 and 5),
  comentario text,
  creado_el timestamptz default now()
);
create index on public.resenas (id_vendedor);

create table public.seguidores (
  id uuid primary key default gen_random_uuid(),
  id_seguidor uuid not null references auth.users(id) on delete cascade,
  id_vendedor uuid not null references public.vendedores(id) on delete cascade,
  unique (id_seguidor, id_vendedor)
);
create index on public.seguidores (id_vendedor);

create table public.armario_virtual (
  id uuid primary key default gen_random_uuid(),
  id_usuario uuid not null references auth.users(id) on delete cascade,
  nombre_prenda text not null,
  valor_estimado numeric,
  imagen_url text,
  creado_el timestamptz default now()
);

create table public.notificaciones (
  id uuid primary key default gen_random_uuid(),
  id_usuario uuid not null references auth.users(id) on delete cascade,
  tipo text not null,
  titulo text,
  mensaje text,
  enlace text,
  leido boolean default false,
  creado_el timestamptz default now()
);
create index on public.notificaciones (id_usuario);

create table public.mensajes (
  id uuid primary key default gen_random_uuid(),
  id_emisor uuid not null references auth.users(id) on delete cascade,
  id_receptor uuid not null references auth.users(id) on delete cascade,
  id_producto uuid references public.productos(id) on delete set null,
  contenido text not null,
  leido boolean default false,
  creado_el timestamptz default now()
);
create index on public.mensajes (id_emisor, id_receptor);

create table public.ofertas (
  id uuid primary key default gen_random_uuid(),
  id_comprador uuid not null references auth.users(id) on delete cascade,
  id_producto uuid not null references public.productos(id) on delete cascade,
  id_vendedor uuid not null references public.vendedores(id) on delete cascade,
  precio_oferta numeric not null,
  estado text default 'pendiente',
  creado_el timestamptz default now()
);
create index on public.ofertas (id_vendedor);

create table public.cupones (
  id uuid primary key default gen_random_uuid(),
  id_vendedor uuid not null references public.vendedores(id) on delete cascade,
  codigo text not null unique,
  descuento numeric not null,
  activo boolean default true,
  usos int default 0,
  max_usos int default 100,
  creado_el timestamptz default now()
);

create table public.raffles (
  id uuid primary key default gen_random_uuid(),
  id_producto uuid not null references public.productos(id) on delete cascade,
  id_usuario uuid not null references auth.users(id) on delete cascade,
  creado_el timestamptz default now(),
  unique (id_producto, id_usuario)
);

create table public.pujas (
  id uuid primary key default gen_random_uuid(),
  id_producto uuid not null references public.productos(id) on delete cascade,
  id_usuario uuid not null references auth.users(id) on delete cascade,
  cantidad numeric not null,
  creado_el timestamptz default now()
);
create index on public.pujas (id_producto);

create table public.favoritos (
  id uuid primary key default gen_random_uuid(),
  id_usuario uuid not null references auth.users(id) on delete cascade,
  id_producto uuid not null references public.productos(id) on delete cascade,
  unique (id_usuario, id_producto)
);

create table public.outfits (
  id uuid primary key default gen_random_uuid(),
  id_usuario uuid not null references auth.users(id) on delete cascade,
  imagen_url text not null,
  descripcion text,
  creado_el timestamptz default now()
);

create table public.videos_showcase (
  id uuid primary key default gen_random_uuid(),
  id_usuario uuid not null references auth.users(id) on delete cascade,
  video_url text not null,
  descripcion text,
  likes int default 0,
  creado_el timestamptz default now()
);

create table public.comentarios_showcase (
  id uuid primary key default gen_random_uuid(),
  id_video uuid not null references public.videos_showcase(id) on delete cascade,
  id_usuario uuid not null references auth.users(id) on delete cascade,
  texto text not null,
  creado_el timestamptz default now()
);
create index on public.comentarios_showcase (id_video);

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ------------------------------------------------------------

alter table public.vendedores enable row level security;
alter table public.productos enable row level security;
alter table public.historial_precios enable row level security;
alter table public.pedidos enable row level security;
alter table public.pedido_items enable row level security;
alter table public.resenas enable row level security;
alter table public.seguidores enable row level security;
alter table public.armario_virtual enable row level security;
alter table public.notificaciones enable row level security;
alter table public.mensajes enable row level security;
alter table public.ofertas enable row level security;
alter table public.cupones enable row level security;
alter table public.raffles enable row level security;
alter table public.pujas enable row level security;
alter table public.favoritos enable row level security;
alter table public.outfits enable row level security;
alter table public.videos_showcase enable row level security;
alter table public.comentarios_showcase enable row level security;

-- VENDEDORES
create policy "vendedores_select_public" on public.vendedores for select using (true);
create policy "vendedores_insert_propio" on public.vendedores for insert with check (id_usuario = auth.uid());
create policy "vendedores_update_propio" on public.vendedores for update using (id_usuario = auth.uid());

-- PRODUCTOS
create policy "productos_select_public" on public.productos for select using (true);
create policy "productos_insert_propio" on public.productos for insert with check (
  exists (select 1 from public.vendedores v where v.id = id_vendedor and v.id_usuario = auth.uid())
);
create policy "productos_update_propio" on public.productos for update using (
  exists (select 1 from public.vendedores v where v.id = id_vendedor and v.id_usuario = auth.uid())
);
create policy "productos_delete_propio" on public.productos for delete using (
  exists (select 1 from public.vendedores v where v.id = id_vendedor and v.id_usuario = auth.uid())
);

-- HISTORIAL_PRECIOS
create policy "historial_precios_select_public" on public.historial_precios for select using (true);
create policy "historial_precios_insert_propio" on public.historial_precios for insert with check (
  exists (
    select 1 from public.productos p
    join public.vendedores v on v.id = p.id_vendedor
    where p.id = id_producto and v.id_usuario = auth.uid()
  )
);

-- PEDIDOS (comprador dueño, o vendedor con productos dentro del pedido)
create policy "pedidos_select_comprador_o_vendedor" on public.pedidos for select using (
  id_usuario = auth.uid()
  or exists (
    select 1 from public.pedido_items pi
    join public.productos p on p.id = pi.id_producto
    join public.vendedores v on v.id = p.id_vendedor
    where pi.id_pedido = public.pedidos.id and v.id_usuario = auth.uid()
  )
);
create policy "pedidos_insert_propio" on public.pedidos for insert with check (id_usuario = auth.uid());
create policy "pedidos_update_vendedor" on public.pedidos for update using (
  exists (
    select 1 from public.pedido_items pi
    join public.productos p on p.id = pi.id_producto
    join public.vendedores v on v.id = p.id_vendedor
    where pi.id_pedido = public.pedidos.id and v.id_usuario = auth.uid()
  )
);

-- PEDIDO_ITEMS
create policy "pedido_items_select_comprador_o_vendedor" on public.pedido_items for select using (
  exists (select 1 from public.pedidos pe where pe.id = id_pedido and pe.id_usuario = auth.uid())
  or exists (
    select 1 from public.productos p
    join public.vendedores v on v.id = p.id_vendedor
    where p.id = id_producto and v.id_usuario = auth.uid()
  )
);
create policy "pedido_items_insert_comprador" on public.pedido_items for insert with check (
  exists (select 1 from public.pedidos pe where pe.id = id_pedido and pe.id_usuario = auth.uid())
);

-- RESENAS
create policy "resenas_select_public" on public.resenas for select using (true);
create policy "resenas_insert_propio" on public.resenas for insert with check (
  id_comprador = auth.uid()
  and exists (select 1 from public.pedidos pe where pe.id = id_pedido and pe.id_usuario = auth.uid())
);

-- SEGUIDORES
create policy "seguidores_select_public" on public.seguidores for select using (true);
create policy "seguidores_insert_propio" on public.seguidores for insert with check (id_seguidor = auth.uid());
create policy "seguidores_delete_propio" on public.seguidores for delete using (id_seguidor = auth.uid());

-- ARMARIO_VIRTUAL
create policy "armario_virtual_select_public" on public.armario_virtual for select using (true);
create policy "armario_virtual_insert_propio" on public.armario_virtual for insert with check (id_usuario = auth.uid());
create policy "armario_virtual_delete_propio" on public.armario_virtual for delete using (id_usuario = auth.uid());

-- NOTIFICACIONES (solo el destinatario lee/marca leído; cualquier autenticado puede crear una para otro usuario)
create policy "notificaciones_select_propio" on public.notificaciones for select using (id_usuario = auth.uid());
create policy "notificaciones_update_propio" on public.notificaciones for update using (id_usuario = auth.uid());
create policy "notificaciones_insert_autenticado" on public.notificaciones for insert with check (auth.role() = 'authenticated');

-- MENSAJES (solo los dos participantes de la conversación)
create policy "mensajes_select_participantes" on public.mensajes for select using (
  id_emisor = auth.uid() or id_receptor = auth.uid()
);
create policy "mensajes_insert_propio" on public.mensajes for insert with check (id_emisor = auth.uid());
create policy "mensajes_update_receptor" on public.mensajes for update using (id_receptor = auth.uid());

-- OFERTAS
create policy "ofertas_select_comprador_o_vendedor" on public.ofertas for select using (
  id_comprador = auth.uid()
  or exists (select 1 from public.vendedores v where v.id = id_vendedor and v.id_usuario = auth.uid())
);
create policy "ofertas_insert_comprador" on public.ofertas for insert with check (id_comprador = auth.uid());
create policy "ofertas_update_vendedor" on public.ofertas for update using (
  exists (select 1 from public.vendedores v where v.id = id_vendedor and v.id_usuario = auth.uid())
);

-- CUPONES (lectura pública para validar códigos en el checkout)
create policy "cupones_select_public" on public.cupones for select using (true);
create policy "cupones_insert_propio" on public.cupones for insert with check (
  exists (select 1 from public.vendedores v where v.id = id_vendedor and v.id_usuario = auth.uid())
);
create policy "cupones_update_propio" on public.cupones for update using (
  exists (select 1 from public.vendedores v where v.id = id_vendedor and v.id_usuario = auth.uid())
);

-- RAFFLES
create policy "raffles_select_public" on public.raffles for select using (true);
create policy "raffles_insert_propio" on public.raffles for insert with check (id_usuario = auth.uid());

-- PUJAS
create policy "pujas_select_public" on public.pujas for select using (true);
create policy "pujas_insert_propio" on public.pujas for insert with check (id_usuario = auth.uid());

-- FAVORITOS (100% privado)
create policy "favoritos_all_propio" on public.favoritos for all using (id_usuario = auth.uid()) with check (id_usuario = auth.uid());

-- OUTFITS
create policy "outfits_select_public" on public.outfits for select using (true);
create policy "outfits_insert_propio" on public.outfits for insert with check (id_usuario = auth.uid());
create policy "outfits_delete_propio" on public.outfits for delete using (id_usuario = auth.uid());

-- VIDEOS_SHOWCASE
-- OJO: la app deja que cualquier usuario autenticado le dé "like" a un vídeo con un
-- update directo desde el cliente, así que el update no puede limitarse al dueño.
-- Efecto secundario: cualquier autenticado podría en teoría reescribir la fila entera
-- (no solo "likes"), porque RLS no filtra por columna. Si esto importa, lo correcto es
-- mover el incremento de likes a una función RPC (SECURITY DEFINER) y quitar esta policy.
create policy "videos_showcase_select_public" on public.videos_showcase for select using (true);
create policy "videos_showcase_insert_propio" on public.videos_showcase for insert with check (id_usuario = auth.uid());
create policy "videos_showcase_update_autenticado" on public.videos_showcase for update using (auth.role() = 'authenticated');
create policy "videos_showcase_delete_propio" on public.videos_showcase for delete using (id_usuario = auth.uid());

-- COMENTARIOS_SHOWCASE
create policy "comentarios_showcase_select_public" on public.comentarios_showcase for select using (true);
create policy "comentarios_showcase_insert_propio" on public.comentarios_showcase for insert with check (id_usuario = auth.uid());

-- ------------------------------------------------------------
-- STORAGE (buckets usados por el código: 'fotos' y 'tienda_media')
-- ------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('fotos', 'fotos', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('tienda_media', 'tienda_media', true)
on conflict (id) do nothing;

create policy "fotos_lectura_publica" on storage.objects for select using (bucket_id = 'fotos');
create policy "fotos_subida_autenticados" on storage.objects for insert with check (bucket_id = 'fotos' and auth.role() = 'authenticated');

create policy "tienda_media_lectura_publica" on storage.objects for select using (bucket_id = 'tienda_media');
create policy "tienda_media_subida_autenticados" on storage.objects for insert with check (bucket_id = 'tienda_media' and auth.role() = 'authenticated');

-- ------------------------------------------------------------
-- REALTIME (sustituye a batch10_chat_fix.sql, ya no hace falta ejecutarlo aparte)
-- ------------------------------------------------------------

alter publication supabase_realtime add table public.mensajes;
alter publication supabase_realtime add table public.notificaciones;

commit;
