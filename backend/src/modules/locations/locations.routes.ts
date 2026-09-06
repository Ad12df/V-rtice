import { FastifyPluginAsync } from "fastify";
import { supabaseAdmin } from "../../config/supabase.js";

export const locationsRoutes: FastifyPluginAsync = async (fastify) => {
  /**
   * GET /api/locations y GET /api/v1/locations
   * Retorna todos los puntos de interés y atalayas turísticas de El Salvador desde Supabase.
   */
  fastify.get("/", async (_request, reply) => {
    try {
      // Intentar primero con la función RPC de PostGIS que ya desempaqueta lat y lng
      const { data: rpcData, error: rpcError } = await supabaseAdmin.rpc("get_all_locations");

      if (!rpcError && rpcData) {
        return reply.status(200).send({
          success: true,
          count: rpcData.length,
          data: rpcData,
        });
      }

      // Si aún no se ha ejecutado el RPC en Supabase, consultar la tabla directamente
      const { data, error } = await supabaseAdmin
        .from("locations")
        .select("id, name, description, category, difficulty, created_at");

      if (error) {
        fastify.log.error(error);
        return reply.status(500).send({
          error: "Database Error",
          message: "Error al consultar las ubicaciones en Supabase",
          details: error.message,
        });
      }

      return reply.status(200).send({
        success: true,
        count: data?.length ?? 0,
        data: data ?? [],
      });
    } catch (err) {
      fastify.log.error(err);
      return reply.status(500).send({
        error: "Internal Server Error",
        message: "Ocurrió un error inesperado al consultar ubicaciones",
      });
    }
  });

  /**
   * GET /api/v1/locations/:id
   * Retorna un punto específico por su UUID
   */
  fastify.get("/:id", async (request, reply) => {
    const { id } = request.params as { id: string };

    try {
      const { data, error } = await supabaseAdmin
        .from("locations")
        .select("*")
        .eq("id", id)
        .single();

      if (error || !data) {
        return reply.status(404).send({
          error: "Not Found",
          message: `No se encontró la ubicación con id ${id}`,
        });
      }

      return reply.status(200).send({
        success: true,
        data,
      });
    } catch (err) {
      fastify.log.error(err);
      return reply.status(500).send({
        error: "Internal Server Error",
        message: "Error al consultar la ubicación",
      });
    }
  });
};
