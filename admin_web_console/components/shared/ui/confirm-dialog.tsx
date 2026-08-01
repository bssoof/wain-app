"use client";

import type { ReactNode } from "react";
import { useEffect, useId, useRef, useState } from "react";
import { createPortal } from "react-dom";

type ClassValue = string | false | null | undefined;

export interface ConfirmDialogProps {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void | Promise<void>;
  title: string;
  description?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: "default" | "danger";
  loading?: boolean;
  children?: ReactNode;
}

export function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  description,
  confirmLabel = "تأكيد",
  cancelLabel = "إلغاء",
  variant = "default",
  loading = false,
  children,
}: ConfirmDialogProps): JSX.Element | null {
  const titleId = useId();
  const descriptionId = useId();
  const dialogRef = useRef<HTMLDivElement | null>(null);
  const confirmButtonRef = useRef<HTMLButtonElement | null>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);
  const blockingRef = useRef(false);
  const [pending, setPending] = useState(false);

  const isBlocking = loading || pending;
  blockingRef.current = isBlocking;

  useEffect(() => {
    if (!open) {
      setPending(false);
      return;
    }

    const activeElement = document.activeElement;
    previousFocusRef.current =
      activeElement instanceof HTMLElement &&
      activeElement !== document.body &&
      activeElement !== document.documentElement
        ? activeElement
        : null;

    const handleKeydown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        if (!blockingRef.current) {
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
      const active = document.activeElement;

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
    window.setTimeout(() => {
      confirmButtonRef.current?.focus();
    }, 0);

    return () => {
      document.removeEventListener("keydown", handleKeydown);
      const previousFocus = previousFocusRef.current;
      if (previousFocus && document.contains(previousFocus)) {
        previousFocus.focus();
      }
    };
  }, [onClose, open]);

  if (!open || typeof document === "undefined") {
    return null;
  }

  const handleConfirm = async () => {
    if (isBlocking) {
      return;
    }

    try {
      const result = onConfirm();
      if (result instanceof Promise) {
        setPending(true);
        await result;
      }
    } finally {
      setPending(false);
    }
  };

  const dialog = (
    <div
      className="confirm-dialog__backdrop"
      role="presentation"
      data-testid="confirm-dialog-backdrop"
      onClick={(event) => {
        if (!isBlocking && event.target === event.currentTarget) {
          onClose();
        }
      }}
    >
      <div
        className="confirm-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={description ? descriptionId : undefined}
        ref={dialogRef}
      >
        <h2 className="confirm-dialog__title" id={titleId}>
          {title}
        </h2>
        {description ? (
          <p className="confirm-dialog__description" id={descriptionId}>
            {description}
          </p>
        ) : null}
        {children ? <div className="confirm-dialog__body">{children}</div> : null}

        <div className="confirm-dialog__actions">
          <button
            type="button"
            className="confirm-dialog__btn confirm-dialog__btn--cancel"
            onClick={onClose}
            disabled={isBlocking}
          >
            {cancelLabel}
          </button>
          <button
            type="button"
            className={classNames(
              "confirm-dialog__btn",
              "confirm-dialog__btn--confirm",
              variant === "danger" && "confirm-dialog__btn--danger",
            )}
            onClick={() => void handleConfirm()}
            disabled={isBlocking}
            ref={confirmButtonRef}
          >
            {isBlocking ? "جارٍ التنفيذ..." : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );

  return createPortal(dialog, document.body);
}

function classNames(...values: ClassValue[]) {
  return values.filter(Boolean).join(" ");
}
