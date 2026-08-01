export interface SkeletonBlockProps {
  width?: string | number;
  height?: string | number;
  variant?: "text" | "rect" | "circle";
  count?: number;
}

function toCssSize(value: string | number): string {
  return typeof value === "number" ? `${value}px` : value;
}

function normalizeCount(count: number | undefined): number {
  if (!count || count < 1) {
    return 1;
  }

  return Math.floor(count);
}

export function SkeletonBlock({
  width = "100%",
  height = "1em",
  variant = "rect",
  count = 1,
}: SkeletonBlockProps): JSX.Element {
  const normalizedCount = normalizeCount(count);
  const style = {
    width: toCssSize(width),
    height: toCssSize(height),
  };

  if (normalizedCount === 1) {
    return (
      <span
        aria-label="جاري التحميل"
        className={`skeleton-block skeleton-block--${variant}`}
        role="status"
        style={style}
      />
    );
  }

  return (
    <div aria-label="جاري التحميل" className="skeleton-block-group" role="status">
      {Array.from({ length: normalizedCount }).map((_, index) => (
        <span
          aria-hidden="true"
          className={`skeleton-block skeleton-block--${variant}`}
          key={index}
          style={style}
        />
      ))}
    </div>
  );
}
