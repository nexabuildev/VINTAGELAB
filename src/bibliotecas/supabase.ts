import { createClient } from '@supabase/supabase-js';

// Leemos las variables o asignamos un placeholder si no existen. createClient()
// exige una URL válida, así que un string vacío hace explotar el build cuando
// estas variables no llegan a tiempo (p. ej. durante el prerender estático).
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://placeholder.supabase.co';
const supabaseAnonKey =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  'placeholder-key';

if (!process.env.NEXT_PUBLIC_SUPABASE_URL) {
  console.warn('⚠️ Configuración de Supabase incompleta. Revisa tus variables de entorno.');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);