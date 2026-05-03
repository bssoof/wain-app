"use client";

import React, { useState } from "react";



export interface ReviewAffordanceDialogProps {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  summaryContent: React.ReactNode;
  onConfirm: () => Promise<void>;
  confirmLabel?: string;
  cancelLabel?: string;
  requiresStepUp?: boolean;
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

    if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-white rounded-lg shadow-lg w-full max-w-[425px] overflow-hidden">
        <div className="px-6 py-4 border-b">
          <h2 className="text-lg font-semibold">{title}</h2>
        </div>
        
        <div className="py-4">
          {/* Pre-action Summary */}
          <div className="mb-4 p-4 bg-muted/50 rounded-md text-sm border">
            {summaryContent}
          </div>

          {/* Error State */}
          {error && (
            <div className="mb-4 p-3 rounded bg-red-50 text-red-900 border border-red-200 flex items-center">
              <span className="mr-2 font-bold">[!]</span>
              <span data-testid="review-error">{error}</span>
            </div>
          )}

          {/* Success State */}
          {isSuccess && (
            <div className="mb-4 p-3 rounded bg-green-50 text-green-900 border border-green-200 flex items-center">
              <span className="mr-2 font-bold text-green-600">[✓]</span>
              <span data-testid="review-success">Action completed successfully.</span>
            </div>
          )}
        </div>

        <div className="px-6 py-4 border-t flex justify-end gap-2 bg-gray-50">
          <button 
            className="px-4 py-2 text-sm font-medium border rounded-md hover:bg-gray-100 disabled:opacity-50"
            onClick={() => handleOpenChange(false)}
            disabled={isSubmitting || isSuccess}
          >
            {cancelLabel}
          </button>
          <button 
            className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:opacity-50 flex items-center"
            onClick={handleConfirm}
            disabled={isSubmitting || isSuccess}
            data-testid="review-confirm-button"
          >
            {isSubmitting && <span className="mr-2">[⏳]</span>}
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
