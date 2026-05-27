import { useState } from "react";
import { LogOut, ChevronDown } from "lucide-react";
import toast from "react-hot-toast";

import { useAuth } from "../../context/AuthContext.jsx";
import { Avatar } from "../ui/Avatar.jsx";

export const Topbar = () => {
  const { user, logout } = useAuth();
  const [menu, setMenu] = useState(false);

  const handleLogout = async () => {
    try {
      await logout();
      toast.success("Signed out");
    } catch (err) {
      toast.error(err.message || "Failed to sign out");
    }
  };

  return (
    <header className="flex h-16 shrink-0 items-center justify-between border-b border-slate-200 bg-white px-6">
      <div>
        <p className="text-xs uppercase tracking-wide text-slate-400">
          Welcome back
        </p>
        <p className="text-sm font-medium text-slate-700">
          {user?.fullName ?? "Admin"}
        </p>
      </div>

      <div className="relative">
        <button
          type="button"
          onClick={() => setMenu((v) => !v)}
          className="flex items-center gap-2 rounded-md border border-slate-200 bg-white px-2 py-1.5 text-sm hover:bg-slate-50"
        >
          <Avatar src={user?.image} name={user?.fullName} size="sm" />
          <span className="hidden text-slate-700 sm:inline">{user?.email}</span>
          <ChevronDown className="h-4 w-4 text-slate-500" />
        </button>

        {menu && (
          <div
            className="absolute right-0 mt-2 w-44 overflow-hidden rounded-md border border-slate-200 bg-white shadow-lg"
            onMouseLeave={() => setMenu(false)}
          >
            <button
              type="button"
              onClick={handleLogout}
              className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-slate-700 hover:bg-slate-50"
            >
              <LogOut className="h-4 w-4" /> Sign out
            </button>
          </div>
        )}
      </div>
    </header>
  );
};
