# Vintage Lab

Marketplace de reventa de ropa vintage, sneakers y streetwear, con pagos reales por Stripe y un panel de vendedor con estadísticas de ventas.

Cualquier usuario puede comprar artículos de otros vendedores, y cualquier vendedor puede registrar su tienda, subir productos y llevar su propio inventario. Está construido con Next.js 16, React 19 y Supabase como backend (base de datos, autenticación y almacenamiento de imágenes).

## Por qué lo hice

Quería salir del típico proyecto de portfolio con un CRUD y un carrito de "comprar" que no llega a ningún sitio. Un marketplace de segunda mano me parecía un reto más honesto: hay dos roles con intereses distintos (el que compra y el que vende), hay dinero real de por medio, y hay que resolver cosas que un CRUD no te obliga a pensar, como quién puede editar qué producto, qué pasa cuando dos personas quieren el mismo artículo, o cómo le muestro a un vendedor si le está yendo bien sin que tenga que adivinarlo.

También quería currarme la parte de pagos en serio. No un botón que simula un pago y redirige a una pantalla de "gracias por tu compra": una sesión de Stripe Checkout de verdad, con sus line items, sus cupones de descuento generados al vuelo y sus redirecciones de éxito y cancelación. Es la parte del proyecto que más veces reescribí, y la que más se parece a lo que haría en un trabajo real.

## Qué hace

- **Catálogo y ficha de producto**: listado de artículos en `/tienda` y página individual por producto, con datos de talla, precio y vendedor.
- **Compra con Stripe real**: la cesta genera una sesión de Stripe Checkout con los artículos elegidos. Si el comprador añade un "legit check" (verificación física del artículo), se suma como línea extra; si hay un código de descuento válido, se crea un cupón de Stripe al vuelo antes de redirigir al pago.
- **Registro de vendedor**: un formulario separado del registro normal crea una fila en la tabla de vendedores ligada al usuario autenticado, para poder publicar productos.
- **Panel de vendedor**: alta y edición de productos, y un dashboard con ingresos totales, número de ventas y un gráfico (Recharts) de ingresos y pedidos por día, calculado a partir de las ventas reales guardadas en Supabase.
- **Favoritos**: guardar artículos para verlos más tarde, asociados al usuario logueado.
- **Chat comprador-vendedor**: mensajería en tiempo real sobre un producto concreto usando los canales de Supabase Realtime.
- **Notificaciones**: avisos cuando alguien comenta o interactúa con tu contenido.
- **Showcase**: feed vertical de vídeos donde los usuarios suben clips de sus artículos, con likes y comentarios.
- **Comunidad**: espacio para subir fotos de outfits, con las imágenes almacenadas en Supabase Storage.
- **Calendario de drops**: lista los próximos lanzamientos consultando los productos que tienen fecha de salida futura en la base de datos.
- **Factura en PDF**: desde el historial de compras se puede generar y descargar un justificante en PDF (html2canvas + jsPDF).
- **Modo claro/oscuro** con `next-themes`, persistente entre visitas.

Lo que no está: un sistema de pagos recurrente real para la suscripción PRO (usa un pago único de Stripe en vez de una suscripción con producto/precio configurado) y el etiquetado automático de productos por IA, que en el código es un endpoint que devuelve una respuesta simulada a modo de prueba de concepto, no una llamada real a un modelo de visión.

## Decisiones técnicas

- **Supabase en vez de montar Postgres + Auth + almacenamiento por separado**: para un proyecto en solitario, tener base de datos, autenticación y storage de imágenes bajo el mismo cliente y las mismas políticas de seguridad (RLS) me ahorraba una integración entera y me dejaba centrarme en la lógica de negocio, que es donde realmente se nota el trabajo.
- **Stripe Checkout en vez de un flujo de pago propio**: manejar tarjetas, PCI compliance y cupones a mano no aporta nada a un portfolio salvo riesgo. Delegar el cobro en Stripe y quedarme con la parte interesante (qué se cobra, cuándo se aplica un descuento, qué pasa después del pago) es lo que haría en un entorno profesional.
- **Dashboard de vendedor calculado en cliente a partir de datos reales**: en vez de guardar métricas precalculadas, las estadísticas del panel (ingresos, ventas, gráfico por día) se derivan de las filas de ventas tal cual están en Supabase. Es más simple de mantener y evita que el dashboard se desincronice de la realidad.
- **Chat y notificaciones con Supabase Realtime en vez de un servidor de sockets propio**: necesitaba mensajería en vivo sin montar infraestructura extra; suscribirse a un canal de Postgres me daba eso mismo sin salir del mismo proveedor que ya usaba para todo lo demás.
- **`next-themes` para modo claro/oscuro**: parece un detalle menor, pero en un catálogo de fotos de producto el contraste importa para ver bien colores y estados del artículo, y es algo que cualquier usuario espera hoy en día en una tienda online.

## Stack

- **Framework**: Next.js 16 (App Router) con React 19 y TypeScript.
- **Backend**: Supabase (Postgres, Auth, Storage, Realtime).
- **Pagos**: Stripe (Checkout Sessions).
- **Estilos**: Tailwind CSS 4, con `next-themes` para el tema claro/oscuro.
- **Datos y reportes**: Recharts para las gráficas del dashboard, `html2canvas` + `jsPDF` para exportar facturas.

## Qué mejoraría con más tiempo

- Pasar la suscripción PRO a un modelo de suscripción real de Stripe (`mode: 'subscription'` con un producto y precio creados en el dashboard), en vez del pago único actual.
- Mover la creación de la sesión de Stripe y la validación del descuento a una capa con más control de errores y logs, pensando en qué pasa si Stripe responde con un fallo a mitad de checkout.
- Sustituir el endpoint de etiquetado automático (hoy simulado) por una llamada real a un modelo de visión, o quitarlo si no aporta valor real al usuario.
- Añadir tests automatizados; ahora mismo la validación es manual, probando cada flujo a mano.

## Estructura del proyecto

```text
src/
├── app/          # Rutas y páginas (App Router), incluidas las API routes de Stripe
│   ├── api/          # checkout, stripe-pro, ai-tagging
│   ├── dashboard/    # panel de vendedor: productos, mensajes, notificaciones
│   ├── tienda/       # catálogo y ficha de producto
│   └── ...           # cesta, checkout, favoritos, chat, comunidad, calendario, showcase
├── componentes/  # componentes de UI reutilizables
├── bibliotecas/  # clientes de Supabase y providers de contexto
└── tipos/        # tipos e interfaces compartidos
```

## Cómo ejecutarlo en local

Requisitos: Node.js 18 o superior, una cuenta de Supabase y una cuenta de Stripe (modo test es suficiente).

1. Clona el repositorio:
   ```bash
   git clone https://github.com/nexabuildev/VINTAGELAB.git
   cd VINTAGELAB
   ```

2. Instala las dependencias:
   ```bash
   npm install
   ```

3. Crea un archivo `.env.local` en la raíz con tus credenciales:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=tu_url_de_supabase
   NEXT_PUBLIC_SUPABASE_ANON_KEY=tu_clave_anonima_de_supabase
   STRIPE_SECRET_KEY=tu_clave_secreta_de_stripe
   ```

4. Levanta el servidor de desarrollo:
   ```bash
   npm run dev
   ```

5. Abre [http://localhost:3000](http://localhost:3000).

Necesitarás tener en tu proyecto de Supabase las tablas que usa la app (productos, vendedores, mensajes, favoritos, videos_showcase, comentarios_showcase, outfits, notificaciones) y los buckets de Storage correspondientes para que las subidas de imágenes y vídeos funcionen.

---

Proyecto personal de Rubén Simón ([@nexabuildev](https://github.com/nexabuildev)), hecho para aprender a construir un e-commerce con pagos y roles reales, no una demo.
