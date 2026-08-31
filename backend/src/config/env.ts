import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default("0.0.0.0"),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  SUPABASE_URL: z.string().url("SUPABASE_URL debe ser una URL válida"),
  SUPABASE_ANON_KEY: z.string().min(1, "SUPABASE_ANON_KEY es requerido"),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1, "SUPABASE_SERVICE_ROLE_KEY es requerido"),
});

const parseEnv = () => {
  const result = envSchema.safeParse(process.env);

  if (!result.success) {
    console.error("❌ Error de validación en variables de entorno:");
    console.error(JSON.stringify(result.error.format(), null, 2));
    process.exit(1);
  }

  return result.data;
};

export const env = parseEnv();
export type Env = z.infer<typeof envSchema>;
