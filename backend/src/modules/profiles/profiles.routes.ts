import { FastifyPluginAsync } from "fastify";
import { supabaseAdmin, supabaseClient } from "../../config/supabase.js";

export const profilesRoutes: FastifyPluginAsync = async (fastify) => {
  /**
   * GET /api/v1/profiles/me
   * Retorna el perfil y rol del usuario autenticado vía Bearer Token
   */
  fastify.get("/me", async (request, reply) => {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return reply.status(401).send({
        error: "Unauthorized",
        message: "Cabecera de autorización Bearer requerida",
      });
    }

    const token = authHeader.substring(7);

    try {
      const { data: userData, error: userError } = await supabaseClient.auth.getUser(token);
      if (userError || !userData?.user) {
        return reply.status(401).send({
          error: "Unauthorized",
          message: "Token inválido o expirado",
          details: userError?.message,
        });
      }

      const { data: profile, error: profileError } = await supabaseAdmin
        .from("profiles")
        .select("id, role, full_name, username, email, birthdate, avatar_url, created_at, updated_at")
        .eq("id", userData.user.id)
        .single();

      if (profileError || !profile) {
        return reply.status(404).send({
          error: "Not Found",
          message: "Perfil de usuario no encontrado en base de datos",
        });
      }

      return reply.status(200).send({
        success: true,
        data: profile,
      });
    } catch (err) {
      fastify.log.error(err);
      return reply.status(500).send({
        error: "Internal Server Error",
        message: "Error al consultar perfil del usuario",
      });
    }
  });

  /**
   * GET /api/v1/profiles/:id
   * Retorna el perfil público de un usuario por su UUID
   */
  fastify.get("/:id", async (request, reply) => {
    const { id } = request.params as { id: string };

    try {
      const { data, error } = await supabaseAdmin
        .from("profiles")
        .select("id, role, full_name, username, avatar_url, created_at")
        .eq("id", id)
        .single();

      if (error || !data) {
        return reply.status(404).send({
          error: "Not Found",
          message: `No se encontró el perfil con id ${id}`,
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
        message: "Error al consultar el perfil",
      });
    }
  });
};
