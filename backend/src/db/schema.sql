-- ====================================================================
-- PROYECTO: VÉRTICE (Turismo en El Salvador con Niebla de Guerra)
-- ESQUEMA DE BASE DE DATOS SUPABASE / POSTGRESQL + POSTGIS (RBAC)
-- ====================================================================

-- 1. Habilitar extensión espacial PostGIS
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- --------------------------------------------------------------------
-- 2. TABLA: PROFILES (Perfiles de Usuarios con RBAC)
-- Vinculada directamente con auth.users de Supabase
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
    full_name TEXT,
    username TEXT UNIQUE,
    email TEXT,
    birthdate DATE,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Asegurar columnas si la tabla ya existía previamente en la instancia de Supabase
DO $$ 
BEGIN
    -- Agregar columnas nuevas si no existen
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'role') THEN
        ALTER TABLE public.profiles ADD COLUMN role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'full_name') THEN
        ALTER TABLE public.profiles ADD COLUMN full_name TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'birthdate') THEN
        ALTER TABLE public.profiles ADD COLUMN birthdate DATE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'email') THEN
        ALTER TABLE public.profiles ADD COLUMN email TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'updated_at') THEN
        ALTER TABLE public.profiles ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());
    END IF;

    -- Eliminar columnas de gamificación si existían previamente
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'exp') THEN
        ALTER TABLE public.profiles DROP COLUMN exp;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'level') THEN
        ALTER TABLE public.profiles DROP COLUMN level;
    END IF;
END $$;

-- Índices para optimización de consultas
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- --------------------------------------------------------------------
-- 3. TABLA: LOCATIONS (Puntos de Interés / Atalayas en El Salvador)
-- Coordenadas espaciales utilizando GEOGRAPHY(Point, 4326)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    category TEXT NOT NULL,
    difficulty TEXT NOT NULL DEFAULT 'MEDIA',
    location GEOGRAPHY(Point, 4326) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Asegurar eliminación de exp_reward si existía previamente en locations
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'locations' AND column_name = 'exp_reward') THEN
        ALTER TABLE public.locations DROP COLUMN exp_reward;
    END IF;
END $$;

-- Índice espacial GIST para consultas geográficas ultrarrápidas
CREATE INDEX IF NOT EXISTS idx_locations_location 
ON public.locations USING GIST (location);

-- --------------------------------------------------------------------
-- 4. TABLA: USER_EXPLORATIONS (Registro de Exploración / Niebla disipada)
-- Registra qué usuario ha visitado / desbloqueado cada punto
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_explorations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    location_id UUID REFERENCES public.locations(id) ON DELETE CASCADE NOT NULL,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_user_location UNIQUE (user_id, location_id)
);

CREATE INDEX IF NOT EXISTS idx_user_explorations_user_id 
ON public.user_explorations (user_id);

CREATE INDEX IF NOT EXISTS idx_user_explorations_location_id 
ON public.user_explorations (location_id);

-- --------------------------------------------------------------------
-- 5. FUNCIONES AUXILIARES DE SEGURIDAD (RBAC)
-- --------------------------------------------------------------------

-- Eliminar funciones existentes previamente para evitar conflictos de tipo de retorno (42P13)
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin CASCADE;

-- Función para verificar si el usuario que invoca tiene rol 'admin'
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.profiles 
    WHERE id = auth.uid() 
      AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Trigger para auto-actualizar updated_at en profiles
DROP FUNCTION IF EXISTS public.handle_updated_at() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_profiles_updated_at ON public.profiles;
CREATE TRIGGER trigger_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- --------------------------------------------------------------------
-- 6. TRIGGER: AUTO-CREACIÓN Y SINCRONIZACIÓN DE PERFIL CON AUTH.USERS
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  extracted_role TEXT;
  extracted_birthdate DATE;
BEGIN
  -- Extraer rol de la metadata si viene especificado y es válido ('admin'/'user'), sino default 'user'
  extracted_role := COALESCE(NEW.raw_user_meta_data->>'role', 'user');
  IF extracted_role NOT IN ('admin', 'user') THEN
    extracted_role := 'user';
  END IF;

  -- Intentar parsear fecha de nacimiento si viene provista
  IF (NEW.raw_user_meta_data->>'birthdate') IS NOT NULL AND (NEW.raw_user_meta_data->>'birthdate') <> '' THEN
    BEGIN
      extracted_birthdate := (NEW.raw_user_meta_data->>'birthdate')::DATE;
    EXCEPTION WHEN OTHERS THEN
      extracted_birthdate := NULL;
    END;
  ELSE
    extracted_birthdate := NULL;
  END IF;

  INSERT INTO public.profiles (
    id,
    role,
    full_name,
    username,
    email,
    birthdate,
    avatar_url
  )
  VALUES (
    NEW.id,
    extracted_role,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      NEW.raw_user_meta_data->>'display_name'
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'username',
      NEW.raw_user_meta_data->>'alias',
      split_part(NEW.email, '@', 1)
    ),
    NEW.email,
    extracted_birthdate,
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
    avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
    updated_at = timezone('utc'::text, now());

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Sincronizar cambios de correo si auth.users se actualiza
DROP FUNCTION IF EXISTS public.handle_user_email_sync() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_user_email_sync()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    UPDATE public.profiles
    SET email = NEW.email,
        updated_at = timezone('utc'::text, now())
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_email_updated ON auth.users;
CREATE TRIGGER on_auth_user_email_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_email_sync();

-- --------------------------------------------------------------------
-- 7. SEGURIDAD: POLÍTICAS DE ACCESO ROW LEVEL SECURITY (RLS)
-- --------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_explorations ENABLE ROW LEVEL SECURITY;

-- --- Políticas de PROFILES ---
DROP POLICY IF EXISTS "Perfiles son visibles para todos" ON public.profiles;
CREATE POLICY "Perfiles son visibles para todos"
ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Usuarios pueden actualizar su propio perfil o administradores" ON public.profiles;
CREATE POLICY "Usuarios pueden actualizar su propio perfil o administradores"
ON public.profiles FOR UPDATE USING (
  auth.uid() = id OR public.is_admin()
) WITH CHECK (
  auth.uid() = id OR public.is_admin()
);

DROP POLICY IF EXISTS "Usuarios pueden insertar su propio perfil o administradores" ON public.profiles;
CREATE POLICY "Usuarios pueden insertar su propio perfil o administradores"
ON public.profiles FOR INSERT WITH CHECK (
  auth.uid() = id OR public.is_admin()
);

DROP POLICY IF EXISTS "Administradores pueden eliminar perfiles" ON public.profiles;
CREATE POLICY "Administradores pueden eliminar perfiles"
ON public.profiles FOR DELETE USING (
  public.is_admin()
);

-- --- Políticas de LOCATIONS ---
DROP POLICY IF EXISTS "Lugares son públicos para lectura" ON public.locations;
CREATE POLICY "Lugares son públicos para lectura"
ON public.locations FOR SELECT USING (true);

DROP POLICY IF EXISTS "Solo administradores pueden insertar lugares" ON public.locations;
CREATE POLICY "Solo administradores pueden insertar lugares"
ON public.locations FOR INSERT WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Solo administradores pueden modificar lugares" ON public.locations;
CREATE POLICY "Solo administradores pueden modificar lugares"
ON public.locations FOR UPDATE USING (
  public.is_admin()
) WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Solo administradores pueden eliminar lugares" ON public.locations;
CREATE POLICY "Solo administradores pueden eliminar lugares"
ON public.locations FOR DELETE USING (
  public.is_admin()
);

-- --- Políticas de USER_EXPLORATIONS ---
DROP POLICY IF EXISTS "Usuarios pueden ver sus propias exploraciones o administradores" ON public.user_explorations;
CREATE POLICY "Usuarios pueden ver sus propias exploraciones o administradores"
ON public.user_explorations FOR SELECT USING (
  auth.uid() = user_id OR public.is_admin()
);

DROP POLICY IF EXISTS "Usuarios pueden registrar nuevas exploraciones" ON public.user_explorations;
CREATE POLICY "Usuarios pueden registrar nuevas exploraciones"
ON public.user_explorations FOR INSERT WITH CHECK (
  auth.uid() = user_id
);

DROP POLICY IF EXISTS "Usuarios o administradores pueden eliminar exploraciones" ON public.user_explorations;
CREATE POLICY "Usuarios o administradores pueden eliminar exploraciones"
ON public.user_explorations FOR DELETE USING (
  auth.uid() = user_id OR public.is_admin()
);

-- --------------------------------------------------------------------
-- 8. STORAGE BUCKET: AVATARS Y POLÍTICAS RLS
-- --------------------------------------------------------------------
-- Creación del Bucket 'avatars' como público si no existe
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Políticas de Storage para 'avatars'
DROP POLICY IF EXISTS "Avatares son de lectura pública" ON storage.objects;
CREATE POLICY "Avatares son de lectura pública"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Usuarios pueden subir su propio avatar o administradores" ON storage.objects;
CREATE POLICY "Usuarios pueden subir su propio avatar o administradores"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR auth.uid()::text = split_part(name, '/', 1)
    OR auth.uid()::text = split_part(name, '.', 1)
    OR public.is_admin()
  )
);

DROP POLICY IF EXISTS "Usuarios pueden modificar su propio avatar o administradores" ON storage.objects;
CREATE POLICY "Usuarios pueden modificar su propio avatar o administradores"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' 
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR auth.uid()::text = split_part(name, '/', 1)
    OR auth.uid()::text = split_part(name, '.', 1)
    OR public.is_admin()
  )
);

DROP POLICY IF EXISTS "Usuarios pueden eliminar su propio avatar o administradores" ON storage.objects;
CREATE POLICY "Usuarios pueden eliminar su propio avatar o administradores"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' 
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR auth.uid()::text = split_part(name, '/', 1)
    OR auth.uid()::text = split_part(name, '.', 1)
    OR public.is_admin()
  )
);

-- --------------------------------------------------------------------
-- 9. FUNCIONES RPC POSTGIS PARA CONSULTAS DEL BACKEND
-- --------------------------------------------------------------------

-- IMPORTANTE: DROP explícito de las funciones anteriores para evitar error 42P13
-- (PostgreSQL prohíbe cambiar el tipo de retorno con CREATE OR REPLACE FUNCTION)
DROP FUNCTION IF EXISTS public.get_all_locations() CASCADE;
DROP FUNCTION IF EXISTS public.nearby_locations(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) CASCADE;
DROP FUNCTION IF EXISTS public.nearby_locations CASCADE;

-- Retorna todos los lugares con coordenadas lat y lng listas para JSON (sin gamificación)
CREATE OR REPLACE FUNCTION public.get_all_locations()
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    category TEXT,
    difficulty TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.description,
        l.category,
        l.difficulty,
        ST_Y(l.location::geometry) AS lat,
        ST_X(l.location::geometry) AS lng,
        l.created_at
    FROM public.locations l
    ORDER BY l.name ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Retorna lugares cercanos ordenados por distancia exacta en metros (sin gamificación)
CREATE OR REPLACE FUNCTION public.nearby_locations(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION DEFAULT 50000
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    category TEXT,
    difficulty TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.description,
        l.category,
        l.difficulty,
        ST_Y(l.location::geometry) AS lat,
        ST_X(l.location::geometry) AS lng,
        ST_Distance(
            l.location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        ) AS distance_meters
    FROM public.locations l
    WHERE ST_DWithin(
        l.location,
        ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
        radius_meters
    )
    ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- --------------------------------------------------------------------
-- 10. DATOS SEMILLA (SEEDS): ATALAYAS Y PUNTOS CLAVE EN EL SALVADOR
-- --------------------------------------------------------------------
INSERT INTO public.locations (name, description, category, difficulty, location)
VALUES
  (
    'Volcán de Santa Ana (Ilamatepec)',
    'Cráter activo a 2,381 msnm con laguna esmeralda. Punto estratégico para disipar niebla en el occidente.',
    'ATALAYA NATURAL',
    'ALTA',
    ST_SetSRID(ST_MakePoint(-89.6300, 13.8533), 4326)::geography
  ),
  (
    'Ruinas de Tazumal',
    'Complejo ceremonial maya con pirámide escalonada de 24 metros y reliquias de jade.',
    'ZONA ARQUEOLÓGICA',
    'MEDIA',
    ST_SetSRID(ST_MakePoint(-89.6744, 13.9794), 4326)::geography
  ),
  (
    'Centro Histórico de San Salvador',
    'Epicentro cultural: Palacio Nacional, Teatro Nacional y Catedral Metropolitana.',
    'NÚCLEO URBANO',
    'BAJA',
    ST_SetSRID(ST_MakePoint(-89.1914, 13.6983), 4326)::geography
  ),
  (
    'Playa El Tunco (Surf City)',
    'Costa del Pacífico reconocida mundialmente por sus olas clase élite y atardeceres volcánicos.',
    'SECTOR COSTERO',
    'BAJA',
    ST_SetSRID(ST_MakePoint(-89.3853, 13.4939), 4326)::geography
  ),
  (
    'Parque Nacional El Imposible',
    'Bosque tropical primario con desfiladeros escarpados, cascadas ocultas y biodiversidad endémica.',
    'RESERVA DE SELVA',
    'ÉPICA',
    ST_SetSRID(ST_MakePoint(-89.9392, 13.8292), 4326)::geography
  ),
  (
    'Lago de Coatepeque',
    'Lago de origen volcánico con aguas turquesas rodeado de miradores y senderos náuticos.',
    'CRÁTER ACUÁTICO',
    'MEDIA',
    ST_SetSRID(ST_MakePoint(-89.5517, 13.8697), 4326)::geography
  ),
  (
    'Suchitoto (Ciudad Colonial)',
    'Joyel histórico con calles empedradas, arquitectura colonial y vistas panorámicas al Lago Suchitlán.',
    'PATRIMONIO HISTÓRICO',
    'BAJA',
    ST_SetSRID(ST_MakePoint(-89.0278, 13.9378), 4326)::geography
  ),
  (
    'La Puerta del Diablo',
    'Formación rocosa legendaria en Panchimalco con mirador de 360 grados hacia la costa y volcanes.',
    'MIRADOR TÁCTICO',
    'MEDIA',
    ST_SetSRID(ST_MakePoint(-89.1906, 13.6214), 4326)::geography
  )
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    difficulty = EXCLUDED.difficulty,
    location = EXCLUDED.location;
