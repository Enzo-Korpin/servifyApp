import { AlertCircle } from "lucide-react";

export const ErrorState = ({
  title = "Something went wrong",
  message = "Please try again.",
  onRetry,
}) => (
  <div className="flex flex-col items-center justify-center gap-2 py-10 text-center text-red-600">
    <div className="rounded-full bg-red-50 p-3">
      <AlertCircle className="h-6 w-6 text-red-500" />
    </div>
    <p className="text-sm font-medium">{title}</p>
    <p className="max-w-sm text-xs text-red-500">{message}</p>
    {onRetry && (
      <button
        type="button"
        onClick={onRetry}
        className="mt-1 rounded-md border border-red-200 px-3 py-1 text-xs font-medium text-red-700 hover:bg-red-50"
      >
        Retry
      </button>
    )}
  </div>
);
