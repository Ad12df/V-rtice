import { buildApp } from "./app.js";
import { env } from "./config/env.js";

const startServer = async () => {
  const app = await buildApp();

  try {
    const address = await app.listen({
      port: env.PORT,
      host: env.HOST,
    });

    app.log.info(`🚀 Servidor Vértice Backend ejecutándose en ${address}`);
    app.log.info(`📡 Healthcheck disponible en ${address}/health`);
    app.log.info(`📍 API Places disponible en ${address}/api/v1/places/nearby`);
  } catch (error) {
    app.log.error(error);
    process.exit(1);
  }

  // Graceful shutdown
  const signals: NodeJS.Signals[] = ["SIGINT", "SIGTERM"];
  for (const signal of signals) {
    process.on(signal, async () => {
      app.log.info(`Cierre recibido (${signal}). Cerrando servidor de forma segura...`);
      try {
        await app.close();
        app.log.info("Servidor cerrado exitosamente.");
        process.exit(0);
      } catch (err) {
        app.log.error(`Error durante el cierre del servidor: ${err}`);
        process.exit(1);
      }
    });
  }
};

startServer();
