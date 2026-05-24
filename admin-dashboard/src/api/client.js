import axios from "axios";

// In dev we let Vite proxy /api/* → backend, so baseURL stays empty.
// In prod we point at the deployed API.
const baseURL = import.meta.env.VITE_API_BASE_URL || "";

export const api = axios.create({
  baseURL,
  withCredentials: true, // critical — sends the httpOnly token cookie
  headers: { "Content-Type": "application/json" },
});

/**
 * Global response interceptor. Surfaces the backend's normalized error shape:
 *   { success: false, data: null, error: { code, message, details } }
 *
 * Throws an Error with .status, .code, .details, and .message so callers
 * (React Query, mutations) can render precise messages without each call
 * re-implementing the same parsing logic.
 */
api.interceptors.response.use(
  (res) => res,
  (err) => {
    const status = err.response?.status ?? 0;
    const payload = err.response?.data;
    const code = payload?.error?.code || err.code || "NETWORK_ERROR";
    const message =
      payload?.error?.message ||
      err.message ||
      "Something went wrong. Please try again.";

    const wrapped = new Error(message);
    wrapped.status = status;
    wrapped.code = code;
    wrapped.details = payload?.error?.details ?? null;
    return Promise.reject(wrapped);
  },
);
