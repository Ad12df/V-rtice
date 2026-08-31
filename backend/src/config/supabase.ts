import { createClient } from "@supabase/supabase-js";
import { env } from "./env.js";

/**
 * Cliente estándar de Supabase (usando ANON_KEY).
 * Recomendado para operaciones públicas o verificadas con contexto de usuario.
 */
export const supabaseClient = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

/**
 * Cliente administrativo de Supabase (usando SERVICE_ROLE_KEY).
 * Utilizado para tareas de administración de backend, bypass de RLS donde sea estrictamente necesario.
 */
export const supabaseAdmin = createClient(
  env.SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  }
);
