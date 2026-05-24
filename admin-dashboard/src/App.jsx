import { lazy, Suspense } from "react";
import { Navigate, Route, Routes } from "react-router-dom";

import { ProtectedRoute } from "./routes/ProtectedRoute.jsx";
import { AdminLayout } from "./components/layout/AdminLayout.jsx";
import { FullPageSpinner } from "./components/ui/FullPageSpinner.jsx";

// Code-split every page — keeps the initial bundle tiny.
const LoginPage = lazy(() => import("./pages/LoginPage.jsx"));
const DashboardPage = lazy(() => import("./pages/DashboardPage.jsx"));
const UsersPage = lazy(() => import("./pages/UsersPage.jsx"));
const UserDetailPage = lazy(() => import("./pages/UserDetailPage.jsx"));
const WorkersPage = lazy(() => import("./pages/WorkersPage.jsx"));
const WorkerDetailPage = lazy(() => import("./pages/WorkerDetailPage.jsx"));
const RequestsPage = lazy(() => import("./pages/RequestsPage.jsx"));
const RequestDetailPage = lazy(() => import("./pages/RequestDetailPage.jsx"));
const FeedbackPage = lazy(() => import("./pages/FeedbackPage.jsx"));
const NotificationsPage = lazy(() => import("./pages/NotificationsPage.jsx"));
const SettingsPage = lazy(() => import("./pages/SettingsPage.jsx"));
const NotFoundPage = lazy(() => import("./pages/NotFoundPage.jsx"));

export default function App() {
  return (
    <Suspense fallback={<FullPageSpinner />}>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route
          path="/admin"
          element={
            <ProtectedRoute>
              <AdminLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="users" element={<UsersPage />} />
          <Route path="users/:id" element={<UserDetailPage />} />
          <Route path="workers" element={<WorkersPage />} />
          <Route path="workers/:id" element={<WorkerDetailPage />} />
          <Route path="requests" element={<RequestsPage />} />
          <Route path="requests/:id" element={<RequestDetailPage />} />
          <Route path="feedback" element={<FeedbackPage />} />
          <Route path="notifications" element={<NotificationsPage />} />
          <Route path="settings" element={<SettingsPage />} />
        </Route>

        <Route path="/" element={<Navigate to="/admin/dashboard" replace />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </Suspense>
  );
}
