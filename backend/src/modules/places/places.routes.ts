import { FastifyPluginAsync } from "fastify";
import { nearbyPlacesQuerySchema } from "./places.schema.js";

export const placesRoutes: FastifyPluginAsync = async (fastify) => {
  /**
   * GET /api/v1/places/nearby
   * Devuelve lugares turísticos / puntos de interés cercanos a la coordenada dada.
   * Listo para integración con PostGIS / Supabase RPC.
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

    // Stub inicial de respuesta
    return reply.status(200).send({
      success: true,
      meta: {
        center: { lat, lng },
        radiusInMeters: radius,
        count: 0,
      },
      data: [],
      message: "Endpoint stub listo para conexión con PostGIS / Supabase",
    });
  });
};
