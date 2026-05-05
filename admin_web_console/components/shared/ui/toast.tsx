"use client";

import { useCallback, useEffect, useMemo, useRef, useSyncExternalStore } from "react";

export interface Toast {
  id: string;
  title: string;
  description?: string;
  severity?: "info" | "success" | "warning" | "danger";
  durationMs?: number;
}

type ToastInput = Omit<Toast, "id">;
type ToastSeverity = NonNullable<Toast["severity"]>;
type ToastListener = () => void;

const DEFAULT_DURATION_MS = 4_000;
const MAX_VISIBLE_TOASTS = 3;

let toasts: Toast[] = [];
const listeners = new Set<ToastListener>();

function subscribe(listener: ToastListener) {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}

function getSnapshot() {
  return toasts;
}

function emitChange() {
  listeners.forEach((listener) => listener());
}

function showToast(toast: ToastInput) {
  const normalizedToast: Toast = {
    ...toast,
    id: crypto.randomUUID(),
    severity: toast.severity ?? "info",
    durationMs: Math.max(0, toast.durationMs ?? DEFAULT_DURATION_MS),
  };

  toasts = [normalizedToast, ...toasts].slice(0, MAX_VISIBLE_TOASTS);
  emitChange();

  return normalizedToast.id;
}

function dismissToast(id: string) {
  const nextToasts = toasts.filter((toast) => toast.id !== id);
  if (nextToasts.length === toasts.length) {
    return;
  }

  toasts = nextToasts;
  emitChange();
}

export function useToast(): {
  show: (toast: ToastInput) => string;
  dismiss: (id: string) => void;
} {
  useSyncExternalStore(subscribe, getSnapshot, getSnapshot);

  const show = useCallback((toast: ToastInput) => showToast(toast), []);
  const dismiss = useCallback((id: string) => dismissToast(id), []);

  return useMemo(
    () => ({
      show,
      dismiss,
    }),
    [dismiss, show],
  );
}

export function ToastViewport(): JSX.Element {
  const visibleToasts = useSyncExternalStore(subscribe, getSnapshot, getSnapshot);

  return (
    <div className="toast-viewport" role="region" aria-label="إشعارات">
      {visibleToasts.map((toast) => (
        <ToastItem key={toast.id} toast={toast} />
      ))}
    </div>
  );
}

function ToastItem({ toast }: { toast: Toast }) {
  const severity = toast.severity ?? "info";
  const role = isAlertSeverity(severity) ? "alert" : "status";
  const durationMs = toast.durationMs ?? DEFAULT_DURATION_MS;
  const timerIdRef = useRef<number | null>(null);
  const timerStartedAtRef = useRef(0);
  const remainingMsRef = useRef(durationMs);

  const clearTimer = useCallback(() => {
    if (timerIdRef.current === null) {
      return;
    }

    window.clearTimeout(timerIdRef.current);
    timerIdRef.current = null;
  }, []);

  const startTimer = useCallback(
    (timeoutMs: number) => {
      if (durationMs === 0 || timeoutMs <= 0) {
        return;
      }

      timerStartedAtRef.current = Date.now();
      timerIdRef.current = window.setTimeout(() => {
        dismissToast(toast.id);
      }, timeoutMs);
    },
    [durationMs, toast.id],
  );

  useEffect(() => {
    remainingMsRef.current = durationMs;
    startTimer(durationMs);

    return () => {
      clearTimer();
    };
  }, [clearTimer, durationMs, startTimer]);

  const pauseTimer = () => {
    if (durationMs === 0 || timerIdRef.current === null) {
      return;
    }

    const elapsedMs = Date.now() - timerStartedAtRef.current;
    remainingMsRef.current = Math.max(0, remainingMsRef.current - elapsedMs);
    clearTimer();
  };

  const resumeTimer = () => {
    if (durationMs === 0 || timerIdRef.current !== null) {
      return;
    }

    if (remainingMsRef.current <= 0) {
      dismissToast(toast.id);
      return;
    }

    startTimer(remainingMsRef.current);
  };

  return (
    <div
      role={role}
      className={`toast toast--${severity}`}
      onMouseEnter={pauseTimer}
      onMouseLeave={resumeTimer}
    >
      <p className="toast__title">{toast.title}</p>
      {toast.description ? (
        <p className="toast__description">{toast.description}</p>
      ) : null}
    </div>
  );
}

function isAlertSeverity(severity: ToastSeverity) {
  return severity === "warning" || severity === "danger";
}
