import { z } from "zod";

export const nearbyPlacesQuerySchema = z.object({
  lat: z.coerce
    .number({ invalid_type_error: "lat debe ser un número" })
    .min(-90, "latitud mínima es -90")
    .max(90, "latitud máxima es 90"),
  lng: z.coerce
    .number({ invalid_type_error: "lng debe ser un número" })
    .min(-180, "longitud mínima es -180")
    .max(180, "longitud máxima es 180"),
  radius: z.coerce
    .number({ invalid_type_error: "radius debe ser un número" })
    .positive("radius debe ser mayor a 0")
    .max(50000, "el radio máximo de búsqueda es 50000 metros (50km)")
    .default(5000),
});

export type NearbyPlacesQuery = z.infer<typeof nearbyPlacesQuerySchema>;
