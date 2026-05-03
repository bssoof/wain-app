"use client";

import React, { useState, useEffect } from "react";



export interface ReviewAffordanceDialogProps {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  summaryContent: React.ReactNode;
  onConfirm: () => Promise<void>;
  confirmLabel?: string;
  cancelLabel?: string;
  requiresStepUp?: boolean;
  isConfirmDisabled?: boolean;
}

export function ReviewAffordanceDialog({
  isOpen,
  onOpenChange,
  title,
  summaryContent,
  onConfirm,
  confirmLabel = "Confirm",
  cancelLabel = "Cancel",
  requiresStepUp = false,
  isConfirmDisabled = false,
}: ReviewAffordanceDialogProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSuccess, setIsSuccess] = useState(false);

  const handleConfirm = async () => {
    setIsSubmitting(true);
    setError(null);
    
    try {
      // In a real integration, Step-Up hook logic (e.g. useStepUp()) 
      // would be awaited here if requiresStepUp is true.
      await onConfirm();
      setIsSuccess(true);
      
      // Auto close on success after a short delay to show success state
      setTimeout(() => {
        setIsSuccess(false);
        onOpenChange(false);
      }, 1500);
    } catch (err: any) {
      setError(err.message || "An unexpected error occurred. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleOpenChange = (open: boolean) => {
    if (isSubmitting) return; // Prevent closing while inflight
    onOpenChange(open);
    if (!open) {
      // Reset state on close
      setError(null);
      setIsSuccess(false);
    }
  };

  // Handle Escape key to close
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen) {
        handleOpenChange(false);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, isSubmitting]);

    if (!isOpen) return null;

  return (
    <div className="review-dialog-overlay">
      <div 
        className="review-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="review-dialog-title"
      >
        <div className="review-dialog__header">
          <h2 id="review-dialog-title" className="review-dialog__title">{title}</h2>
        </div>
        
        <div className="review-dialog__content">
          {/* Pre-action Summary */}
          <div className="review-dialog__summary">
            {summaryContent}
          </div>

          {/* Error State */}
          {error && (
            <div className="review-dialog__error" role="alert" aria-live="assertive">
              <span className="review-dialog__icon-error">[!]</span>
              <span data-testid="review-error">{error}</span>
            </div>
          )}

          {/* Success State */}
          {isSuccess && (
            <div className="review-dialog__success" role="status" aria-live="polite">
              <span className="review-dialog__icon-success">[✓]</span>
              <span data-testid="review-success">Action completed successfully.</span>
            </div>
          )}
        </div>

        <div className="review-dialog__footer">
          <button 
            className="review-dialog__btn review-dialog__btn--cancel"
            onClick={() => handleOpenChange(false)}
            disabled={isSubmitting || isSuccess}
          >
            {cancelLabel}
          </button>
          <button 
            className="review-dialog__btn review-dialog__btn--confirm"
            onClick={handleConfirm}
            disabled={isSubmitting || isSuccess || isConfirmDisabled}
            data-testid="review-confirm-button"
          >
            {isSubmitting && <span className="review-dialog__spinner">[⏳]</span>}
            {isSubmitting 
              ? (requiresStepUp ? "Verifying..." : "Processing...") 
              : isSuccess 
                ? "Done" 
                : confirmLabel
            }
          </button>
        </div>
      </div>
    </div>
  );
}
