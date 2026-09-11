import { NextResponse } from 'next/server';
import Stripe from 'stripe';

export async function POST(request: Request) {
  try {
    // Inicializamos Stripe con tu clave secreta (en tiempo de petición, no de build).
    // httpClient: fetch es obligatorio en Cloudflare Workers, ver nota en /api/checkout.
    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
      apiVersion: '2023-10-16' as any,
      httpClient: Stripe.createFetchHttpClient(),
    });

    const { email } = await request.json();

    const origin = request.headers.get('origin') || 'http://localhost:3000';

    const sessionConfig: any = {
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'eur',
            product_data: { 
              name: 'Vintage Lab PRO',
              description: 'Suscripción Mensual (Acceso anticipado, Envíos Gratis, Badge VIP)'
            },
            unit_amount: 999, // 9.99€
          },
          quantity: 1,
        }
      ],
      // NOTA: Para recurrente en Stripe real se usa mode: 'subscription' y se necesita crear un "Product / Price" en el dashboard. 
      // Aquí estamos usando 'payment' simulado para MVP como pidió el usuario.
      mode: 'payment',
      success_url: `${origin}/pro/exito`,
      cancel_url: `${origin}/pro`,
    };

    if (email) {
      sessionConfig.customer_email = email;
    }

    const session = await stripe.checkout.sessions.create(sessionConfig);

    return NextResponse.json({ url: session.url });
    
  } catch (error: any) {
    console.error("Error en Stripe PRO:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
