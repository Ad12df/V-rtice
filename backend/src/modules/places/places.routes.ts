import { FastifyPluginAsync } from "fastify";
import { nearbyPlacesQuerySchema } from "./places.schema.js";
import { supabaseAdmin } from "../../config/supabase.js";

export const placesRoutes: FastifyPluginAsync = async (fastify) => {
  /**
   * GET /api/v1/places/nearby
   * Devuelve lugares turísticos / puntos de interés cercanos a la coordenada dada usando PostGIS ST_DWithin.
   */
  fastify.get("/nearby", async (request, reply) => {
    const parseResult = nearbyPlacesQuerySchema.safeParse(request.query);

    if (!parseResult.success) {
      return reply.status(400).send({
        error: "Bad Request",
        message: "Parámetros de consulta inválidos",
        issues: parseResult.error.format(),
      });
    }

    const { lat, lng, radius } = parseResult.data;

    try {
      // Invocación de la función RPC PostGIS nearby_locations
      const { data, error } = await supabaseAdmin.rpc("nearby_locations", {
        user_lat: lat,
        user_lng: lng,
        radius_meters: radius,
      });

      if (error) {
        fastify.log.error(error);
        return reply.status(500).send({
          error: "PostGIS Query Error",
          message: "Error al consultar lugares cercanos en Supabase",
          details: error.message,
        });
      }

      return reply.status(200).send({
        success: true,
        meta: {
          center: { lat, lng },
          radiusInMeters: radius,
          count: data ? data.length : 0,
        },
        data: data ?? [],
      });
    } catch (err) {
      fastify.log.error(err);
      return reply.status(500).send({
        error: "Internal Server Error",
        message: "Error inesperado al calcular lugares cercanos",
      });
    }
  });
};
