"use client";

import {
  FormEvent,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from "react";

import { localizeAdminLabel } from "@/lib/admin/admin-localization";

type StepUpModalProps = {
  open: boolean;
  command?: string;
  pending: boolean;
  error?: string;
  lockoutExpiresAt?: string;
  returnFocusTo?: HTMLElement | null;
  onSubmit: (password: string) => Promise<void>;
  onClose: () => void;
};

export function StepUpModal({
  open,
  command,
  pending,
  error,
  lockoutExpiresAt,
  returnFocusTo,
  onSubmit,
  onClose,
}: StepUpModalProps) {
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [remainingLockoutSeconds, setRemainingLockoutSeconds] = useState(0);
  const dialogRef = useRef<HTMLDivElement | null>(null);
  const passwordInputRef = useRef<HTMLInputElement | null>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);
  const pendingRef = useRef(pending);

  useEffect(() => {
    pendingRef.current = pending;
  }, [pending]);

  useEffect(() => {
    if (!open) {
      setPassword("");
      setShowPassword(false);
    }
  }, [open]);

  useEffect(() => {
    if (!open || !lockoutExpiresAt) {
      setRemainingLockoutSeconds(0);
      return;
    }

    const lockoutMs = Date.parse(lockoutExpiresAt);
    if (!Number.isFinite(lockoutMs)) {
      setRemainingLockoutSeconds(0);
      return;
    }

    const updateCountdown = () => {
      const nextValue = Math.max(0, Math.ceil((lockoutMs - Date.now()) / 1000));
      setRemainingLockoutSeconds(nextValue);
    };

    updateCountdown();
    const intervalId = window.setInterval(updateCountdown, 1_000);
    return () => {
      window.clearInterval(intervalId);
    };
  }, [lockoutExpiresAt, open]);

  useEffect(() => {
    if (open) {
      return;
    }

    const handleFocusIn = (event: FocusEvent) => {
      if (event.target instanceof HTMLElement) {
        previousFocusRef.current = event.target;
      }
    };

    document.addEventListener("focusin", handleFocusIn);
    return () => {
      document.removeEventListener("focusin", handleFocusIn);
    };
  }, [open]);

  useLayoutEffect(() => {
    if (!open) {
      return;
    }

    if (returnFocusTo && document.contains(returnFocusTo)) {
      previousFocusRef.current = returnFocusTo;
    } else {
      const activeElement = document.activeElement;
      if (
        activeElement instanceof HTMLElement &&
        activeElement !== document.body &&
        activeElement !== document.documentElement
      ) {
        previousFocusRef.current = activeElement;
      }
    }

    const handleKeydown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        if (!pendingRef.current) {
          event.preventDefault();
          onClose();
        }
        return;
      }

      if (event.key !== "Tab") {
        return;
      }

      const dialogElement = dialogRef.current;
      if (!dialogElement) {
        return;
      }

      const focusableElements = dialogElement.querySelectorAll<HTMLElement>(
        'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
      );
      if (focusableElements.length === 0) {
        event.preventDefault();
        return;
      }

      const firstFocusable = focusableElements[0];
      const lastFocusable = focusableElements[focusableElements.length - 1];
      const active = document.activeElement as HTMLElement | null;

      if (event.shiftKey) {
        if (active === firstFocusable || !dialogElement.contains(active)) {
          event.preventDefault();
          lastFocusable.focus();
        }
      } else if (active === lastFocusable) {
        event.preventDefault();
        firstFocusable.focus();
      }
    };

    document.addEventListener("keydown", handleKeydown);
    return () => {
      document.removeEventListener("keydown", handleKeydown);
      const previousFocus = previousFocusRef.current;
      if (previousFocus && document.contains(previousFocus)) {
        previousFocus.focus();
      }
    };
  }, [onClose, open, returnFocusTo]);

  useEffect(() => {
    if (!open || pending) {
      return;
    }
    passwordInputRef.current?.focus();
  }, [open, pending]);

  if (!open) {
    return null;
  }

  const commandLabel = command ? localizeAdminLabel(command) : "إجراء مالي حساس";
  const lockoutActive = remainingLockoutSeconds > 0;
  const lockoutCountdown = formatLockoutCountdown(remainingLockoutSeconds);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await onSubmit(password);
  };

  return (
    <div
      className="step-up-dialog-backdrop"
      role="presentation"
      onClick={(event) => {
        if (!pending && event.target === event.currentTarget) {
          onClose();
        }
      }}
      data-testid="step-up-backdrop"
    >
      <div
        className="card step-up-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="step-up-dialog-title"
        data-testid="step-up-dialog"
        ref={dialogRef}
      >
        <div className="step-up-dialog__header">
          <div>
            <h2 id="step-up-dialog-title">تأكيد الهوية قبل التنفيذ</h2>
            <p className="muted-text">
              لحماية الأوامر المالية الحساسة، أدخل كلمة المرور لتأكيد أنك أنت من ينفذ
              هذا الإجراء.
            </p>
          </div>
          <button
            type="button"
            className="action-button action-button-secondary"
            onClick={onClose}
            disabled={pending}
          >
            إغلاق
          </button>
        </div>

        <form className="step-up-dialog__form" onSubmit={(event) => void handleSubmit(event)}>
          <div className="step-up-dialog__command">
            <span className="muted-text">الإجراء المطلوب</span>
            <strong>{commandLabel}</strong>
          </div>

          {error ? (
            <p
              className="finance-read-inline-unavailable"
              role="alert"
              data-testid="step-up-error"
            >
              {error}
            </p>
          ) : null}
          {lockoutActive ? (
            <p className="muted-text" data-testid="step-up-lockout-countdown">
              يمكن إعادة المحاولة بعد: {lockoutCountdown}
            </p>
          ) : null}

          <label className="auth-field" htmlFor="step-up-password-input">
            <span>كلمة المرور</span>
            <input
              id="step-up-password-input"
              className="auth-input"
              type={showPassword ? "text" : "password"}
              autoComplete="current-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="أدخل كلمة المرور"
              disabled={pending || lockoutActive}
              autoFocus
              ref={passwordInputRef}
            />
          </label>
          <button
            type="button"
            className="action-button action-button-secondary"
            aria-label={showPassword ? "إخفاء كلمة المرور" : "إظهار كلمة المرور"}
            onClick={() => setShowPassword((current) => !current)}
            disabled={pending || lockoutActive}
          >
            {showPassword ? "إخفاء كلمة المرور" : "إظهار كلمة المرور"}
          </button>

          <div className="step-up-dialog__actions">
            <button
              type="button"
              className="action-button action-button-secondary"
              onClick={onClose}
              disabled={pending}
            >
              إلغاء
            </button>
            <button
              type="submit"
              className="action-button"
              disabled={pending || lockoutActive}
            >
              {pending ? "جارٍ التحقق..." : "تأكيد ومتابعة"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function formatLockoutCountdown(totalSeconds: number): string {
  if (totalSeconds <= 0) {
    return "00:00";
  }

  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}
