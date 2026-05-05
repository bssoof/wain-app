"use client";

import {
  cloneElement,
  isValidElement,
  useEffect,
  useId,
  useRef,
  useState,
} from "react";
import type { ReactElement } from "react";

export interface TooltipProps {
  content: string;
  children: ReactElement;
  side?: "top" | "bottom" | "left" | "right";
  delayMs?: number;
}

type TooltipChildProps = {
  "aria-describedby"?: string;
};

function mergeDescribedBy(current: string | undefined, tooltipId: string): string {
  if (!current) {
    return tooltipId;
  }

  return current.split(/\s+/).includes(tooltipId) ? current : `${current} ${tooltipId}`;
}

export function Tooltip({
  content,
  children,
  side = "top",
  delayMs = 400,
}: TooltipProps): JSX.Element {
  const reactId = useId();
  const tooltipId = `tooltip-${reactId.replace(/:/g, "")}`;
  const [visible, setVisible] = useState(false);
  const delayRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const clearDelay = () => {
    if (delayRef.current) {
      clearTimeout(delayRef.current);
      delayRef.current = null;
    }
  };

  const showWithDelay = () => {
    clearDelay();
    delayRef.current = setTimeout(() => {
      setVisible(true);
      delayRef.current = null;
    }, delayMs);
  };

  const showImmediately = () => {
    clearDelay();
    setVisible(true);
  };

  const hide = () => {
    clearDelay();
    setVisible(false);
  };

  useEffect(() => clearDelay, []);

  if (!isValidElement<TooltipChildProps>(children)) {
    return children;
  }

  const describedBy = mergeDescribedBy(children.props["aria-describedby"], tooltipId);
  const describedChild = cloneElement(children, {
    "aria-describedby": describedBy,
  });

  return (
    <span
      className="tooltip-wrapper"
      onBlur={hide}
      onFocus={showImmediately}
      onMouseEnter={showWithDelay}
      onMouseLeave={hide}
    >
      {describedChild}
      <span
        id={tooltipId}
        className="tooltip"
        data-side={side}
        data-visible={visible}
        role="tooltip"
      >
        {content}
      </span>
    </span>
  );
}
