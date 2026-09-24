-- ====================================================================
-- PROYECTO: GEOTURISMO (Plataforma de Turismo Táctico en El Salvador)
-- ESQUEMA DE BASE DE DATOS SUPABASE / POSTGRESQL + POSTGIS (RBAC)
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. HABILITAR EXTENSIONES REQUERIDAS: POSTGIS Y PGCRYPTO
-- --------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- --------------------------------------------------------------------
-- 2. TABLA: PROFILES (Perfiles de Usuarios con RBAC y Control de Suspensión)
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
    is_banned BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Asegurar columnas si la tabla ya existía previamente en la instancia de Supabase
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'role') THEN
        ALTER TABLE public.profiles ADD COLUMN role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'full_name') THEN
        ALTER TABLE public.profiles ADD COLUMN full_name TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'username') THEN
        ALTER TABLE public.profiles ADD COLUMN username TEXT UNIQUE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'birthdate') THEN
        ALTER TABLE public.profiles ADD COLUMN birthdate DATE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'email') THEN
        ALTER TABLE public.profiles ADD COLUMN email TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'avatar_url') THEN
        ALTER TABLE public.profiles ADD COLUMN avatar_url TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'is_banned') THEN
        ALTER TABLE public.profiles ADD COLUMN is_banned BOOLEAN NOT NULL DEFAULT false;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'updated_at') THEN
        ALTER TABLE public.profiles ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'exp') THEN
        ALTER TABLE public.profiles DROP COLUMN exp;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'level') THEN
        ALTER TABLE public.profiles DROP COLUMN level;
    END IF;
END $$;

-- Índices para optimización de consultas en perfiles
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_is_banned ON public.profiles(is_banned);

-- --------------------------------------------------------------------
-- 3. TABLA: LOCATIONS (Atalayas y Puntos Turísticos en El Salvador)
-- División territorial real por departamentos, zonas geográficas y costos
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    category TEXT NOT NULL,
    difficulty TEXT NOT NULL DEFAULT 'MEDIA',
    department TEXT NOT NULL DEFAULT 'San Salvador',
    zone TEXT NOT NULL DEFAULT 'Zona Central',
    price_category TEXT NOT NULL DEFAULT 'GRATUITO' CHECK (price_category IN ('GRATUITO', 'ECONÓMICO', 'MODERADO', 'EXCLUSIVO')),
    entry_fee NUMERIC(10,2) DEFAULT 0.00,
    location GEOGRAPHY(Point, 4326) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Asegurar columnas para división territorial y costos si la tabla ya existía
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'locations' AND column_name = 'department') THEN
        ALTER TABLE public.locations ADD COLUMN department TEXT NOT NULL DEFAULT 'San Salvador';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'locations' AND column_name = 'zone') THEN
        ALTER TABLE public.locations ADD COLUMN zone TEXT NOT NULL DEFAULT 'Zona Central';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'locations' AND column_name = 'price_category') THEN
        ALTER TABLE public.locations ADD COLUMN price_category TEXT NOT NULL DEFAULT 'GRATUITO' CHECK (price_category IN ('GRATUITO', 'ECONÓMICO', 'MODERADO', 'EXCLUSIVO'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'locations' AND column_name = 'entry_fee') THEN
        ALTER TABLE public.locations ADD COLUMN entry_fee NUMERIC(10,2) DEFAULT 0.00;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'locations' AND column_name = 'exp_reward') THEN
        ALTER TABLE public.locations DROP COLUMN exp_reward;
    END IF;
END $$;

-- Índices espaciales y de filtrado para locations
CREATE INDEX IF NOT EXISTS idx_locations_location ON public.locations USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_locations_department ON public.locations(department);
CREATE INDEX IF NOT EXISTS idx_locations_zone ON public.locations(zone);
CREATE INDEX IF NOT EXISTS idx_locations_price_category ON public.locations(price_category);

-- --------------------------------------------------------------------
-- 4. TABLA: EVENTS (Agenda de Eventos Tácticos, Culturales y Expediciones)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organizer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE DEFAULT auth.uid(),
    title TEXT NOT NULL UNIQUE,
    description TEXT,
    category TEXT NOT NULL,
    department TEXT NOT NULL DEFAULT 'San Salvador',
    location_name TEXT,
    status TEXT NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'live', 'completed')),
    price_category TEXT NOT NULL DEFAULT 'GRATUITO' CHECK (price_category IN ('GRATUITO', 'ECONÓMICO', 'MODERADO', 'EXCLUSIVO')),
    price_amount NUMERIC(10,2) DEFAULT 0.00,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    location GEOGRAPHY(Point, 4326) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Asegurar columnas si la tabla ya existía
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'organizer_id') THEN
        ALTER TABLE public.events ADD COLUMN organizer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE DEFAULT auth.uid();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'department') THEN
        ALTER TABLE public.events ADD COLUMN department TEXT NOT NULL DEFAULT 'San Salvador';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'location_name') THEN
        ALTER TABLE public.events ADD COLUMN location_name TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'price_category') THEN
        ALTER TABLE public.events ADD COLUMN price_category TEXT NOT NULL DEFAULT 'GRATUITO' CHECK (price_category IN ('GRATUITO', 'ECONÓMICO', 'MODERADO', 'EXCLUSIVO'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'price_amount') THEN
        ALTER TABLE public.events ADD COLUMN price_amount NUMERIC(10,2) DEFAULT 0.00;
    END IF;
END $$;

-- Índices de consulta para events
CREATE INDEX IF NOT EXISTS idx_events_organizer_id ON public.events(organizer_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON public.events(status);
CREATE INDEX IF NOT EXISTS idx_events_department ON public.events(department);
CREATE INDEX IF NOT EXISTS idx_events_location ON public.events USING GIST (location);

-- --------------------------------------------------------------------
-- 5. TABLA: USER_EXPLORATIONS (Registro de Exploración / Niebla disipada)
-- Registra qué usuario ha visitado / desbloqueado cada punto
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_explorations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    location_id UUID REFERENCES public.locations(id) ON DELETE CASCADE NOT NULL,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_user_location UNIQUE (user_id, location_id)
);

CREATE INDEX IF NOT EXISTS idx_user_explorations_user_id ON public.user_explorations (user_id);
CREATE INDEX IF NOT EXISTS idx_user_explorations_location_id ON public.user_explorations (location_id);

-- --------------------------------------------------------------------
-- 6. FUNCIONES AUXILIARES DE SEGURIDAD (RBAC & BAN)
-- --------------------------------------------------------------------

-- Eliminar funciones existentes previamente para evitar conflictos de firma
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin CASCADE;

-- Función para verificar si el usuario que invoca tiene rol 'admin' y no está suspendido
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.profiles 
    WHERE id = auth.uid() 
      AND role = 'admin'
      AND is_banned = false
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Función para verificar si el usuario que invoca está suspendido / baneado
DROP FUNCTION IF EXISTS public.is_banned() CASCADE;
DROP FUNCTION IF EXISTS public.is_banned CASCADE;

CREATE OR REPLACE FUNCTION public.is_banned()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.profiles 
    WHERE id = auth.uid() 
      AND is_banned = true
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
-- 7. TRIGGER: AUTO-CREACIÓN Y SINCRONIZACIÓN DE PERFIL CON AUTH.USERS
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  extracted_role TEXT;
  extracted_birthdate DATE;
BEGIN
  -- Asignar admin si es el correo reservado admin@vertice.app o si viene en raw_user_meta_data
  IF LOWER(NEW.email) = 'admin@vertice.app' OR LOWER(COALESCE(NEW.raw_user_meta_data->>'role', '')) = 'admin' THEN
    extracted_role := 'admin';
  ELSE
    extracted_role := COALESCE(NEW.raw_user_meta_data->>'role', 'user');
    IF extracted_role NOT IN ('admin', 'user') THEN
      extracted_role := 'user';
    END IF;
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
    avatar_url,
    is_banned
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
    NEW.raw_user_meta_data->>'avatar_url',
    false
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    role = CASE WHEN LOWER(NEW.email) = 'admin@vertice.app' THEN 'admin' ELSE public.profiles.role END,
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
-- 8. SEGURIDAD: POLÍTICAS ROW LEVEL SECURITY (RLS)
-- --------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_explorations ENABLE ROW LEVEL SECURITY;

-- --- Políticas de PROFILES ---
DROP POLICY IF EXISTS "Perfiles son visibles para todos" ON public.profiles;
CREATE POLICY "Perfiles son visibles para todos"
ON public.profiles FOR SELECT USING (
  (NOT public.is_banned()) OR auth.uid() = id OR public.is_admin()
);

DROP POLICY IF EXISTS "Usuarios pueden actualizar su propio perfil o administradores" ON public.profiles;
CREATE POLICY "Usuarios pueden actualizar su propio perfil o administradores"
ON public.profiles FOR UPDATE USING (
  (auth.uid() = id AND NOT public.is_banned()) OR public.is_admin()
) WITH CHECK (
  (auth.uid() = id AND NOT public.is_banned()) OR public.is_admin()
);

DROP POLICY IF EXISTS "Usuarios pueden insertar su propio perfil o administradores" ON public.profiles;
CREATE POLICY "Usuarios pueden insertar su propio perfil o administradores"
ON public.profiles FOR INSERT WITH CHECK (
  (auth.uid() = id AND NOT public.is_banned()) OR public.is_admin()
);

DROP POLICY IF EXISTS "Administradores pueden eliminar perfiles" ON public.profiles;
CREATE POLICY "Administradores pueden eliminar perfiles"
ON public.profiles FOR DELETE USING (
  public.is_admin()
);

-- --- Políticas de LOCATIONS ---
DROP POLICY IF EXISTS "Lugares son públicos para lectura" ON public.locations;
CREATE POLICY "Lugares son públicos para lectura"
ON public.locations FOR SELECT USING (
  NOT public.is_banned()
);

DROP POLICY IF EXISTS "Solo administradores pueden insertar lugares" ON public.locations;
CREATE POLICY "Solo administradores pueden insertar lugares"
ON public.locations FOR INSERT WITH CHECK (
  public.is_admin() AND NOT public.is_banned()
);

DROP POLICY IF EXISTS "Solo administradores pueden modificar lugares" ON public.locations;
CREATE POLICY "Solo administradores pueden modificar lugares"
ON public.locations FOR UPDATE USING (
  public.is_admin() AND NOT public.is_banned()
) WITH CHECK (
  public.is_admin() AND NOT public.is_banned()
);

DROP POLICY IF EXISTS "Solo administradores pueden eliminar lugares" ON public.locations;
CREATE POLICY "Solo administradores pueden eliminar lugares"
ON public.locations FOR DELETE USING (
  public.is_admin() AND NOT public.is_banned()
);

-- --- Políticas de EVENTS ---
DROP POLICY IF EXISTS "Eventos son públicos para lectura" ON public.events;
CREATE POLICY "Eventos son públicos para lectura"
ON public.events FOR SELECT USING (
  NOT public.is_banned()
);

DROP POLICY IF EXISTS "Solo administradores pueden insertar eventos" ON public.events;
DROP POLICY IF EXISTS "Usuarios autenticados pueden insertar eventos" ON public.events;
CREATE POLICY "Usuarios autenticados pueden insertar eventos"
ON public.events FOR INSERT
TO authenticated
WITH CHECK (
  NOT public.is_banned() AND (organizer_id = auth.uid() OR organizer_id IS NULL OR public.is_admin())
);

DROP POLICY IF EXISTS "Solo administradores pueden modificar eventos" ON public.events;
DROP POLICY IF EXISTS "Usuarios pueden modificar sus propios eventos o administradores" ON public.events;
CREATE POLICY "Usuarios pueden modificar sus propios eventos o administradores"
ON public.events FOR UPDATE
TO authenticated
USING (
  NOT public.is_banned() AND (organizer_id = auth.uid() OR public.is_admin())
) WITH CHECK (
  NOT public.is_banned() AND (organizer_id = auth.uid() OR public.is_admin())
);

DROP POLICY IF EXISTS "Solo administradores pueden eliminar eventos" ON public.events;
DROP POLICY IF EXISTS "Usuarios pueden eliminar sus propios eventos o administradores" ON public.events;
CREATE POLICY "Usuarios pueden eliminar sus propios eventos o administradores"
ON public.events FOR DELETE
TO authenticated
USING (
  NOT public.is_banned() AND (organizer_id = auth.uid() OR public.is_admin())
);

-- --- Políticas de USER_EXPLORATIONS ---
DROP POLICY IF EXISTS "Usuarios pueden ver sus propias exploraciones o administradores" ON public.user_explorations;
CREATE POLICY "Usuarios pueden ver sus propias exploraciones o administradores"
ON public.user_explorations FOR SELECT USING (
  (auth.uid() = user_id OR public.is_admin()) AND NOT public.is_banned()
);

DROP POLICY IF EXISTS "Usuarios pueden registrar nuevas exploraciones" ON public.user_explorations;
CREATE POLICY "Usuarios pueden registrar nuevas exploraciones"
ON public.user_explorations FOR INSERT WITH CHECK (
  auth.uid() = user_id AND NOT public.is_banned()
);

DROP POLICY IF EXISTS "Usuarios o administradores pueden eliminar exploraciones" ON public.user_explorations;
CREATE POLICY "Usuarios o administradores pueden eliminar exploraciones"
ON public.user_explorations FOR DELETE USING (
  (auth.uid() = user_id OR public.is_admin()) AND NOT public.is_banned()
);

-- --------------------------------------------------------------------
-- 9. STORAGE BUCKET: AVATARS Y POLÍTICAS RLS
-- --------------------------------------------------------------------
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

DROP POLICY IF EXISTS "Avatares son de lectura pública" ON storage.objects;
CREATE POLICY "Avatares son de lectura pública"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Usuarios pueden subir su propio avatar o administradores" ON storage.objects;
CREATE POLICY "Usuarios pueden subir su propio avatar o administradores"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND NOT public.is_banned()
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
  AND NOT public.is_banned()
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
  AND NOT public.is_banned()
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR auth.uid()::text = split_part(name, '/', 1)
    OR auth.uid()::text = split_part(name, '.', 1)
    OR public.is_admin()
  )
);

-- --------------------------------------------------------------------
-- 10. FUNCIONES RPC POSTGIS PARA CONSULTAS DEL BACKEND Y FLUTTER
-- --------------------------------------------------------------------

-- DROP explícito de las funciones anteriores para evitar conflicto de tipo de retorno (42P13)
DROP FUNCTION IF EXISTS public.get_all_locations() CASCADE;
DROP FUNCTION IF EXISTS public.nearby_locations(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) CASCADE;
DROP FUNCTION IF EXISTS public.nearby_locations CASCADE;
DROP FUNCTION IF EXISTS public.get_all_events() CASCADE;

-- Retorna todos los lugares turísticos con datos territoriales y coordenadas listas para Flutter
CREATE OR REPLACE FUNCTION public.get_all_locations()
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    category TEXT,
    difficulty TEXT,
    department TEXT,
    zone TEXT,
    price_category TEXT,
    entry_fee NUMERIC(10,2),
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    IF public.is_banned() THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.description,
        l.category,
        l.difficulty,
        l.department,
        l.zone,
        l.price_category,
        l.entry_fee,
        ST_Y(l.location::geometry) AS lat,
        ST_X(l.location::geometry) AS lng,
        l.created_at
    FROM public.locations l
    ORDER BY l.name ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Retorna lugares cercanos ordenados por distancia exacta en metros
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
    department TEXT,
    zone TEXT,
    price_category TEXT,
    entry_fee NUMERIC(10,2),
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION
) AS $$
BEGIN
    IF public.is_banned() THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.description,
        l.category,
        l.difficulty,
        l.department,
        l.zone,
        l.price_category,
        l.entry_fee,
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

-- Retorna la agenda de eventos tácticos ordenados por fecha de inicio con datos de organizador
CREATE OR REPLACE FUNCTION public.get_all_events()
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    category TEXT,
    department TEXT,
    location_name TEXT,
    status TEXT,
    price_category TEXT,
    price_amount NUMERIC(10,2),
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    created_at TIMESTAMPTZ,
    organizer_id UUID,
    organizer_name TEXT,
    organizer_avatar TEXT
) AS $$
BEGIN
    IF public.is_banned() THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        e.id,
        e.title,
        e.description,
        e.category,
        e.department,
        e.location_name,
        e.status,
        e.price_category,
        e.price_amount,
        e.start_date,
        e.end_date,
        ST_Y(e.location::geometry) AS lat,
        ST_X(e.location::geometry) AS lng,
        e.created_at,
        e.organizer_id,
        COALESCE(p.username, p.full_name, 'Organizador') AS organizer_name,
        p.avatar_url AS organizer_avatar
    FROM public.events e
    LEFT JOIN public.profiles p ON e.organizer_id = p.id
    ORDER BY e.start_date ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- --------------------------------------------------------------------
-- 11. DATOS SEMILLA (SEEDS): ATALAYAS Y PUNTOS CLAVE EN EL SALVADOR
-- --------------------------------------------------------------------
INSERT INTO public.locations (
    name, description, category, difficulty, department, zone, price_category, entry_fee, location
)
VALUES
  (
    'Volcán de Santa Ana (Ilamatepec)',
    'Cráter activo a 2,381 msnm con laguna esmeralda. Punto estratégico para disipar niebla en el occidente.',
    'ATALAYA NATURAL',
    'ALTA',
    'Santa Ana',
    'Cadena Volcánica',
    'ECONÓMICO',
    6.00,
    ST_SetSRID(ST_MakePoint(-89.6300, 13.8533), 4326)::geography
  ),
  (
    'Ruinas de Tazumal',
    'Complejo ceremonial maya con pirámide escalonada de 24 metros y reliquias de jade.',
    'ZONA ARQUEOLÓGICA',
    'MEDIA',
    'Santa Ana',
    'Zona Occidental',
    'ECONÓMICO',
    3.00,
    ST_SetSRID(ST_MakePoint(-89.6744, 13.9794), 4326)::geography
  ),
  (
    'Centro Histórico de San Salvador',
    'Epicentro cultural: Palacio Nacional, Teatro Nacional y Catedral Metropolitana.',
    'NÚCLEO URBANO',
    'BAJA',
    'San Salvador',
    'Zona Central',
    'GRATUITO',
    0.00,
    ST_SetSRID(ST_MakePoint(-89.1914, 13.6983), 4326)::geography
  ),
  (
    'Playa El Tunco (Surf City)',
    'Costa del Pacífico reconocida mundialmente por sus olas clase élite y atardeceres volcánicos.',
    'SECTOR COSTERO',
    'BAJA',
    'La Libertad',
    'Sector Costero / Surf City',
    'MODERADO',
    10.00,
    ST_SetSRID(ST_MakePoint(-89.3853, 13.4939), 4326)::geography
  ),
  (
    'Parque Nacional El Imposible',
    'Bosque tropical primario con desfiladeros escarpados, cascadas ocultas y biodiversidad endémica.',
    'RESERVA DE SELVA',
    'ÉPICA',
    'Ahuachapán',
    'Zona Occidental',
    'ECONÓMICO',
    5.00,
    ST_SetSRID(ST_MakePoint(-89.9392, 13.8292), 4326)::geography
  ),
  (
    'Lago de Coatepeque',
    'Lago de origen volcánico con aguas turquesas rodeado de miradores y senderos náuticos.',
    'CRÁTER ACUÁTICO',
    'MEDIA',
    'Santa Ana',
    'Zona Occidental',
    'GRATUITO',
    0.00,
    ST_SetSRID(ST_MakePoint(-89.5517, 13.8697), 4326)::geography
  ),
  (
    'Suchitoto (Ciudad Colonial)',
    'Joyel histórico con calles empedradas, arquitectura colonial y vistas panorámicas al Lago Suchitlán.',
    'PATRIMONIO HISTÓRICO',
    'BAJA',
    'Cuscatlán',
    'Zona Paracentral',
    'GRATUITO',
    0.00,
    ST_SetSRID(ST_MakePoint(-89.0278, 13.9378), 4326)::geography
  ),
  (
    'La Puerta del Diablo',
    'Formación rocosa legendaria en Panchimalco con mirador de 360 grados hacia la costa y volcanes.',
    'MIRADOR TÁCTICO',
    'MEDIA',
    'San Salvador',
    'Zona Central',
    'ECONÓMICO',
    1.50,
    ST_SetSRID(ST_MakePoint(-89.1906, 13.6214), 4326)::geography
  )
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    difficulty = EXCLUDED.difficulty,
    department = EXCLUDED.department,
    zone = EXCLUDED.zone,
    price_category = EXCLUDED.price_category,
    entry_fee = EXCLUDED.entry_fee,
    location = EXCLUDED.location;

-- --------------------------------------------------------------------
-- 12. DATOS SEMILLA (SEEDS): AGENDA DE EVENTOS TÁCTICOS EN EL SALVADOR
-- --------------------------------------------------------------------
INSERT INTO public.events (
    title, description, category, department, location_name, status,
    price_category, price_amount, start_date, end_date, location
)
VALUES
  (
    'Torneo Surf City El Tunco',
    'Competencia internacional con olas clase mundial en el litoral pacífico, exhibiciones nocturnas y música en vivo.',
    'SURF & PLAYA',
    'La Libertad',
    'Playa El Tunco, Tamanique',
    'live',
    'MODERADO',
    15.00,
    timezone('utc'::text, now()) + INTERVAL '2 hours',
    timezone('utc'::text, now()) + INTERVAL '10 hours',
    ST_SetSRID(ST_MakePoint(-89.3853, 13.4939), 4326)::geography
  ),
  (
    'Senderismo Nocturno en Ilamatepec',
    'Ascenso guiado hacia los 2,381 msnm del Volcán de Santa Ana con vista a la laguna esmeralda y el Lago de Coatepeque.',
    'EXPEDICIÓN TÁCTICA',
    'Santa Ana',
    'Parque Nacional Los Volcanes',
    'upcoming',
    'ECONÓMICO',
    6.00,
    timezone('utc'::text, now()) + INTERVAL '5 days',
    timezone('utc'::text, now()) + INTERVAL '5 days 6 hours',
    ST_SetSRID(ST_MakePoint(-89.6300, 13.8533), 4326)::geography
  ),
  (
    'Festival de la Calabaza en Suchitoto',
    'Encuentro cultural en las calles empedradas coloniales con gastronomía típica, artesanías añileras y miradores al lago.',
    'CULTURA & ARTE',
    'Cuscatlán',
    'Plaza Central de Suchitoto',
    'upcoming',
    'GRATUITO',
    0.00,
    timezone('utc'::text, now()) + INTERVAL '3 days',
    timezone('utc'::text, now()) + INTERVAL '3 days 8 hours',
    ST_SetSRID(ST_MakePoint(-89.0278, 13.9378), 4326)::geography
  ),
  (
    'Hackathon Cyberpunk San Salvador',
    'Desafío nacional de desarrollo y cartografía táctica para innovadores tecnológicos en el corazón de la capital.',
    'CONFERENCIA TECNOLÓGICA',
    'San Salvador',
    'Centro Histórico de San Salvador',
    'upcoming',
    'GRATUITO',
    0.00,
    timezone('utc'::text, now()) + INTERVAL '8 days',
    timezone('utc'::text, now()) + INTERVAL '10 days',
    ST_SetSRID(ST_MakePoint(-89.1914, 13.6983), 4326)::geography
  )
ON CONFLICT (title) DO UPDATE SET
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    department = EXCLUDED.department,
    location_name = EXCLUDED.location_name,
    status = EXCLUDED.status,
    price_category = EXCLUDED.price_category,
    price_amount = EXCLUDED.price_amount,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    location = EXCLUDED.location;

-- --------------------------------------------------------------------
-- 13. SEMILLA: USUARIO ADMINISTRADOR POR DEFECTO (admin@vertice.app / 123456)
-- --------------------------------------------------------------------
DO $$
DECLARE
  admin_uid UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'admin@vertice.app') THEN
    INSERT INTO auth.users (
      id, instance_id, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      role, aud
    ) VALUES (
      admin_uid, '00000000-0000-0000-0000-000000000000', 'admin@vertice.app',
      extensions.crypt('123456', extensions.gen_salt('bf')), NOW(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Administrador del Sistema","username":"admin_vertice","role":"admin"}',
      NOW(), NOW(), 'authenticated', 'authenticated'
    );
  ELSE
    -- Asegurar que el perfil exista y tenga privilegios admin
    UPDATE public.profiles
    SET role = 'admin', is_banned = false
    WHERE email = 'admin@vertice.app';
  END IF;

  -- Asociar eventos existentes o semillas sin organizador al perfil del administrador
  UPDATE public.events
  SET organizer_id = admin_uid
  WHERE organizer_id IS NULL AND EXISTS (SELECT 1 FROM public.profiles WHERE id = admin_uid);
END $$;
