import { useEffect } from "react";
import { AlertTriangle, X } from "lucide-react";

import { Button } from "./Button.jsx";

/**
 * Modal for irreversible actions (delete, block, etc.).
 *
 * Props:
 *  - open
 *  - onClose
 *  - onConfirm
 *  - title, message
 *  - confirmText, cancelText
 *  - variant: "danger" | "primary"
 *  - loading: disables buttons + shows spinner on confirm
 */
export const ConfirmDialog = ({
  open,
  onClose,
  onConfirm,
  title = "Are you sure?",
  message,
  confirmText = "Confirm",
  cancelText = "Cancel",
  variant = "danger",
  loading = false,
}) => {
  // ESC to close (when not loading).
  useEffect(() => {
    if (!open) return;
    const onKey = (e) => {
      if (e.key === "Escape" && !loading) onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose, loading]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 p-4"
      onClick={loading ? undefined : onClose}
    >
      <div
        className="w-full max-w-md rounded-xl bg-white p-5 shadow-xl"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        <div className="flex items-start gap-3">
          {variant === "danger" && (
            <div className="rounded-full bg-red-50 p-2 text-red-600">
              <AlertTriangle className="h-5 w-5" />
            </div>
          )}
          <div className="flex-1">
            <h2 className="text-base font-semibold text-slate-900">{title}</h2>
            {message && (
              <p className="mt-1 text-sm text-slate-600">{message}</p>
            )}
          </div>
          <button
            type="button"
            disabled={loading}
            onClick={onClose}
            className="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 disabled:opacity-50"
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="mt-5 flex justify-end gap-2">
          <Button variant="secondary" onClick={onClose} disabled={loading}>
            {cancelText}
          </Button>
          <Button
            variant={variant === "danger" ? "danger" : "primary"}
            onClick={onConfirm}
            loading={loading}
          >
            {confirmText}
          </Button>
        </div>
      </div>
    </div>
  );
};
