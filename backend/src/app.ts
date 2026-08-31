import fastify, { FastifyError, FastifyInstance } from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import { env } from "./config/env.js";
import { healthRoutes } from "./modules/health/health.routes.js";
import { placesRoutes } from "./modules/places/places.routes.js";

export const buildApp = async (): Promise<FastifyInstance> => {
  const app = fastify({
    logger: env.NODE_ENV === "test" ? false : true,
  });

  // Plugins de seguridad y cabeceras
  await app.register(helmet, {
    contentSecurityPolicy: env.NODE_ENV === "production",
  });

  await app.register(cors, {
    origin: "*", // En producción puede configurarse con dominios específicos
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  });

  // Rutas base y health check
  await app.register(healthRoutes);

  // Rutas versionadas de la API (/api/v1)
  await app.register(
    async (v1Instance) => {
      await v1Instance.register(placesRoutes, { prefix: "/places" });
    },
    { prefix: "/api/v1" }
  );

  // Manejador 404
  app.setNotFoundHandler((request, reply) => {
    reply.status(404).send({
      error: "Not Found",
      message: `Ruta ${request.method} ${request.url} no encontrada`,
    });
  });

  // Manejador global de errores
  app.setErrorHandler((error: FastifyError, _request, reply) => {
    app.log.error(error);
    const statusCode = error.statusCode ?? 500;
    reply.status(statusCode).send({
      error: error.name || "Internal Server Error",
      message: error.message || "Ocurrió un error inesperado en el servidor",
    });
  });

  return app;
};
