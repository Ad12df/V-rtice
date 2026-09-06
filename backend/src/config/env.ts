import "dotenv/config";
import { z } from "zod";

const baseEnvSchema = z
  .object({
    PORT: z.coerce.number().default(3000),
    HOST: z.string().default("0.0.0.0"),
    NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
    SUPABASE_URL: z.string().url("SUPABASE_URL debe ser una URL válida"),
    SUPABASE_ANON_KEY: z.string().min(1).optional(),
    SUPABASE_SERVICE_ROLE_KEY: z.string().min(1).optional(),
    SUPABASE_PUBLISHABLE_KEY: z.string().min(1).optional(),
    SUPABASE_SECRET_KEY: z.string().min(1).optional(),
  })
  .refine(
    (data) => data.SUPABASE_ANON_KEY || data.SUPABASE_PUBLISHABLE_KEY,
    {
      message: "Se requiere SUPABASE_ANON_KEY (o SUPABASE_PUBLISHABLE_KEY)",
      path: ["SUPABASE_ANON_KEY"],
    }
  )
  .refine(
    (data) => data.SUPABASE_SERVICE_ROLE_KEY || data.SUPABASE_SECRET_KEY,
    {
      message: "Se requiere SUPABASE_SERVICE_ROLE_KEY (o SUPABASE_SECRET_KEY)",
      path: ["SUPABASE_SERVICE_ROLE_KEY"],
    }
  )
  .transform((data) => {
    const anonKey = (data.SUPABASE_ANON_KEY || data.SUPABASE_PUBLISHABLE_KEY)!;
    const serviceRoleKey = (data.SUPABASE_SERVICE_ROLE_KEY || data.SUPABASE_SECRET_KEY)!;

    return {
      PORT: data.PORT,
      HOST: data.HOST,
      NODE_ENV: data.NODE_ENV,
      SUPABASE_URL: data.SUPABASE_URL,
      SUPABASE_ANON_KEY: anonKey,
      SUPABASE_SERVICE_ROLE_KEY: serviceRoleKey,
      SUPABASE_PUBLISHABLE_KEY: anonKey,
      SUPABASE_SECRET_KEY: serviceRoleKey,
    };
  });

const parseEnv = () => {
  const result = baseEnvSchema.safeParse(process.env);

  if (!result.success) {
    console.error("❌ Error de validación en variables de entorno:");
    console.error(JSON.stringify(result.error.format(), null, 2));
    process.exit(1);
  }

  return result.data;
};

export const env = parseEnv();
export type Env = z.infer<typeof baseEnvSchema>;
