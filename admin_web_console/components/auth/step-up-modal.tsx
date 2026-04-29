"use client";

import { FormEvent, useEffect, useState } from "react";

import { localizeAdminLabel } from "@/lib/admin/admin-localization";

type StepUpModalProps = {
  open: boolean;
  command?: string;
  pending: boolean;
  error?: string;
  onSubmit: (password: string) => Promise<void>;
  onClose: () => void;
};

export function StepUpModal({
  open,
  command,
  pending,
  error,
  onSubmit,
  onClose,
}: StepUpModalProps) {
  const [password, setPassword] = useState("");

  useEffect(() => {
    if (!open) {
      setPassword("");
    }
  }, [open]);

  if (!open) {
    return null;
  }

  const commandLabel = command ? localizeAdminLabel(command) : "إجراء مالي حساس";

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

          <label className="auth-field" htmlFor="step-up-password-input">
            <span>كلمة المرور</span>
            <input
              id="step-up-password-input"
              className="auth-input"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="أدخل كلمة المرور"
              disabled={pending}
              autoFocus
            />
          </label>

          <div className="step-up-dialog__actions">
            <button
              type="button"
              className="action-button action-button-secondary"
              onClick={onClose}
              disabled={pending}
            >
              إلغاء
            </button>
            <button type="submit" className="action-button" disabled={pending}>
              {pending ? "جارٍ التحقق..." : "تأكيد ومتابعة"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
