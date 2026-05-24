import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";
import path from "node:path";

// Vite config — supports a dev proxy so the admin dashboard can call /api/admin/*
// without CORS hassles in development.
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  const apiTarget = env.VITE_API_PROXY || "http://localhost:5000";

  return {
    plugins: [react()],
    resolve: {
      alias: {
        "@": path.resolve(process.cwd(), "src"),
      },
    },
    server: {
      port: Number(env.VITE_DEV_PORT || 5174),
      proxy: {
        "/api": {
          target: apiTarget,
          changeOrigin: true,
          // Cookies are httpOnly + same-site=lax → the proxy keeps the auth flow seamless.
          cookieDomainRewrite: "",
        },
      },
    },
  };
});
