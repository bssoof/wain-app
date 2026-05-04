import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { VenueCreateDialog } from "./venue-create-dialog";

function fillRequiredFields(): void {
  fireEvent.change(screen.getByLabelText("الاسم بالعربي"), {
    target: { value: "قهوة تجريبية" },
  });
  fireEvent.change(screen.getByLabelText("المدينة"), {
    target: { value: "رام الله" },
  });
  fireEvent.change(screen.getByLabelText("التصنيفات"), {
    target: { value: "cafe" },
  });
  fireEvent.change(screen.getByLabelText("خط العرض"), {
    target: { value: "31.9516" },
  });
  fireEvent.change(screen.getByLabelText("خط الطول"), {
    target: { value: "35.9239" },
  });
}

describe("venue create dialog", () => {
  it("includes selected direct-upload files in submit payload", () => {
    const onSubmit = vi.fn();

    render(
      <VenueCreateDialog
        open={true}
        pending={false}
        onCancel={() => {
          // no-op
        }}
        onSubmit={onSubmit}
      />,
    );

    fillRequiredFields();

    const venueImage = new File(["venue"], "venue.jpg", {
      type: "image/jpeg",
    });
    const menuImage = new File(["menu"], "menu.jpg", {
      type: "image/jpeg",
    });

    fireEvent.change(screen.getByTestId("venue-create-photo-files-input"), {
      target: { files: [venueImage] },
    });
    fireEvent.change(screen.getByTestId("venue-create-menu-files-input"), {
      target: { files: [menuImage] },
    });

    fireEvent.click(screen.getByRole("button", { name: "إنشاء الجهة" }));

    expect(onSubmit).toHaveBeenCalledTimes(1);
    const payload = onSubmit.mock.calls[0][0];
    expect(payload.nameAr).toBe("قهوة تجريبية");
    expect(payload.city).toBe("رام الله");
    expect(payload.photoFiles).toHaveLength(1);
    expect(payload.menuImageFiles).toHaveLength(1);
    expect(payload.photoFiles[0].name).toBe("venue.jpg");
    expect(payload.menuImageFiles[0].name).toBe("menu.jpg");
  });

  it("builds structured hours payload from daily schedule controls", () => {
    const onSubmit = vi.fn();

    render(
      <VenueCreateDialog
        open={true}
        pending={false}
        onCancel={() => {
          // no-op
        }}
        onSubmit={onSubmit}
      />,
    );

    fillRequiredFields();

    fireEvent.click(screen.getByTestId("venue-create-hours-open-monday"));
    fireEvent.change(screen.getByTestId("venue-create-hours-from-monday"), {
      target: { value: "08:30" },
    });
    fireEvent.change(screen.getByTestId("venue-create-hours-to-monday"), {
      target: { value: "18:15" },
    });
    fireEvent.click(screen.getByTestId("venue-create-hours-spans-midnight-monday"));

    fireEvent.click(screen.getByRole("button", { name: "إنشاء الجهة" }));

    expect(onSubmit).toHaveBeenCalledTimes(1);
    const payload = onSubmit.mock.calls[0][0];
    expect(payload.hours?.monday).toEqual([
      {
        open: "08:30",
        close: "18:15",
        spansMidnight: true,
      },
    ]);
  });

  it("combines selected mood presets with additional mood tags", () => {
    const onSubmit = vi.fn();

    render(
      <VenueCreateDialog
        open={true}
        pending={false}
        onCancel={() => {
          // no-op
        }}
        onSubmit={onSubmit}
      />,
    );

    fillRequiredFields();

    fireEvent.click(screen.getByTestId("venue-create-mood-tag-romantic"));
    fireEvent.click(screen.getByTestId("venue-create-mood-tag-cozy"));
    fireEvent.change(screen.getByLabelText("وسوم أجواء إضافية (اختياري)"), {
      target: { value: "reading_friendly" },
    });

    fireEvent.click(screen.getByRole("button", { name: "إنشاء الجهة" }));

    expect(onSubmit).toHaveBeenCalledTimes(1);
    const payload = onSubmit.mock.calls[0][0];
    expect(payload.tags?.mood).toEqual(["romantic", "cozy", "reading_friendly"]);
  });
});
