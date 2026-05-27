import { NavLink } from "react-router-dom";
import {
  LayoutDashboard,
  Users,
  Wrench,
  ClipboardList,
  Star,
  Bell,
  Settings,
} from "lucide-react";

import { cn } from "../../lib/cn.js";

const NAV = [
  { to: "/admin/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/admin/users", label: "Users", icon: Users },
  { to: "/admin/workers", label: "Workers", icon: Wrench },
  { to: "/admin/requests", label: "Service Requests", icon: ClipboardList },
  { to: "/admin/feedback", label: "Feedback", icon: Star },
  { to: "/admin/notifications", label: "Notifications & Reports", icon: Bell },
  { to: "/admin/settings", label: "Settings", icon: Settings },
];

export const Sidebar = () => (
  <aside className="hidden w-60 shrink-0 flex-col border-r border-slate-200 bg-white lg:flex">
    <div className="flex h-16 items-center gap-2 border-b border-slate-200 px-5">
      <div className="grid h-8 w-8 place-items-center rounded-md bg-brand-600 text-sm font-bold text-white">
        S
      </div>
      <div className="leading-tight">
        <p className="text-sm font-semibold text-slate-900">Servify</p>
        <p className="text-[10px] uppercase tracking-wider text-slate-400">
          Admin Panel
        </p>
      </div>
    </div>

    <nav className="flex-1 space-y-1 px-3 py-4">
      {NAV.map(({ to, label, icon: Icon }) => (
        <NavLink
          key={to}
          to={to}
          end={to === "/admin/dashboard"}
          className={({ isActive }) =>
            cn(
              "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition",
              isActive
                ? "bg-brand-50 text-brand-700"
                : "text-slate-600 hover:bg-slate-50 hover:text-slate-900",
            )
          }
        >
          <Icon className="h-4 w-4" />
          {label}
        </NavLink>
      ))}
    </nav>

    <div className="border-t border-slate-200 p-4 text-[11px] text-slate-400">
      v1.0 · Servify Admin
    </div>
  </aside>
);
