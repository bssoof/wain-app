"use client";

import { forwardRef } from "react";
import type { ButtonHTMLAttributes } from "react";
import { Loader2 } from "lucide-react";
import type { LucideIcon } from "lucide-react";

export interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  icon: LucideIcon;
  label: string;
  variant?: "ghost" | "primary" | "danger";
  size?: "sm" | "md";
  loading?: boolean;
}

function joinClassNames(...classNames: Array<string | false | null | undefined>): string {
  return classNames.filter(Boolean).join(" ");
}

export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(
  (
    {
      icon: Icon,
      label,
      variant = "ghost",
      size = "md",
      loading = false,
      disabled = false,
      className,
      type = "button",
      ...buttonProps
    },
    ref,
  ) => {
    const iconSize = size === "sm" ? 16 : 18;
    const isDisabled = loading || disabled;

    return (
      <button
        {...buttonProps}
        ref={ref}
        type={type}
        aria-busy={loading}
        aria-label={label}
        className={joinClassNames(
          "icon-button",
          `icon-button--${variant}`,
          `icon-button--${size}`,
          className,
        )}
        disabled={isDisabled}
      >
        {loading ? (
          <Loader2
            aria-hidden="true"
            className="icon-button__spinner"
            size={iconSize}
            strokeWidth={2}
          />
        ) : (
          <Icon
            aria-hidden="true"
            className="icon-button__icon"
            size={iconSize}
            strokeWidth={2}
          />
        )}
      </button>
    );
  },
);

IconButton.displayName = "IconButton";
