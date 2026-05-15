import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const { getCurrentAdminSessionMock, fileMock, bucketMock } = vi.hoisted(() => {
  const fileMock = {
    exists: vi.fn(),
    download: vi.fn(),
    getMetadata: vi.fn(),
  };
  return {
    getCurrentAdminSessionMock: vi.fn(),
    fileMock,
    bucketMock: {
      file: vi.fn(() => fileMock),
    },
  };
});

vi.mock("@/lib/auth/session-server", () => ({
  getCurrentAdminSession: getCurrentAdminSessionMock,
}));

vi.mock("@/lib/firebase/server", () => ({
  getAdminApp: () => ({
    options: {
      storageBucket: "test-bucket",
    },
  }),
}));

vi.mock("firebase-admin/storage", () => ({
  getStorage: () => ({
    bucket: () => bucketMock,
  }),
}));

import { GET } from "./route";

describe("GET /api/admin/topup-proof", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    getCurrentAdminSessionMock.mockResolvedValue({
      uid: "admin-1",
      primaryRole: "finance_admin",
      roles: ["finance_admin"],
      roleSource: "claims",
    });
    fileMock.exists.mockResolvedValue([true]);
    fileMock.download.mockResolvedValue([Buffer.from("proof-bytes")]);
    fileMock.getMetadata.mockResolvedValue([{ contentType: "image/jpeg" }]);
  });

  it("serves a valid wallet top-up proof for top-up admins", async () => {
    const response = await GET(
      new NextRequest(
        "https://wain-admin.web.app/api/admin/topup-proof?path=venues%2Fvenue_1%2Fwallet_topups%2Fproof.jpg",
      ),
    );

    expect(response.status).toBe(200);
    expect(response.headers.get("content-type")).toBe("image/jpeg");
    expect(response.headers.get("cache-control")).toBe("private, no-store");
    expect(bucketMock.file).toHaveBeenCalledWith(
      "venues/venue_1/wallet_topups/proof.jpg",
    );
    expect(Buffer.from(await response.arrayBuffer()).toString()).toBe("proof-bytes");
  });

  it("rejects unauthenticated requests", async () => {
    getCurrentAdminSessionMock.mockResolvedValue(null);

    const response = await GET(
      new NextRequest(
        "https://wain-admin.web.app/api/admin/topup-proof?path=venues%2Fvenue_1%2Fwallet_topups%2Fproof.jpg",
      ),
    );

    expect(response.status).toBe(401);
    expect(bucketMock.file).not.toHaveBeenCalled();
  });

  it("rejects non top-up proof paths", async () => {
    const response = await GET(
      new NextRequest(
        "https://wain-admin.web.app/api/admin/topup-proof?path=venues%2Fvenue_1%2Fphotos%2Fproof.jpg",
      ),
    );

    expect(response.status).toBe(422);
    expect(bucketMock.file).not.toHaveBeenCalled();
  });
});
