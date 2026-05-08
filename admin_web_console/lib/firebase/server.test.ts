import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";

const firebaseAppMocks = vi.hoisted(() => ({
  applicationDefault: vi.fn(),
  cert: vi.fn(),
  getApps: vi.fn(),
  initializeApp: vi.fn(),
}));

const fsMocks = vi.hoisted(() => ({
  existsSync: vi.fn(),
  readFileSync: vi.fn(),
}));

vi.mock("firebase-admin/app", () => firebaseAppMocks);

vi.mock("firebase-admin/auth", () => ({
  getAuth: vi.fn(),
}));

vi.mock("firebase-admin/firestore", () => ({
  getFirestore: vi.fn(),
}));

vi.mock("node:fs", () => ({
  default: fsMocks,
  ...fsMocks,
}));

async function loadServerModule() {
  vi.resetModules();
  return import("./server");
}

beforeEach(() => {
  vi.clearAllMocks();
  vi.spyOn(console, "log").mockImplementation(() => undefined);
  vi.spyOn(console, "warn").mockImplementation(() => undefined);

  firebaseAppMocks.applicationDefault.mockReturnValue({ kind: "adc" });
  firebaseAppMocks.cert.mockReturnValue({ kind: "cert" });
  firebaseAppMocks.getApps.mockReturnValue([]);
  firebaseAppMocks.initializeApp.mockImplementation((options?: unknown) => ({
    name: "mock-admin-app",
    options,
  }));

  fsMocks.existsSync.mockReturnValue(false);
  fsMocks.readFileSync.mockReturnValue(JSON.stringify({ project_id: "wain-test" }));
});

afterEach(() => {
  vi.unstubAllEnvs();
  vi.restoreAllMocks();
  vi.resetModules();
});

describe("firebase/server credential resolution", () => {
  it("uses applicationDefault in production even if a JSON key file path is set", async () => {
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv("GOOGLE_APPLICATION_CREDENTIALS", "/tmp/fake-service-account.json");
    fsMocks.existsSync.mockReturnValue(true);

    const { getAdminApp } = await loadServerModule();
    getAdminApp();

    expect(firebaseAppMocks.applicationDefault).toHaveBeenCalledOnce();
    expect(firebaseAppMocks.cert).not.toHaveBeenCalled();
    expect(fsMocks.existsSync).not.toHaveBeenCalled();
    expect(fsMocks.readFileSync).not.toHaveBeenCalled();
    expect(firebaseAppMocks.initializeApp).toHaveBeenCalledWith({
      credential: { kind: "adc" },
      projectId: "wain-d2e28",
    });
  });

  it("uses cert in development when a JSON key path resolves to an existing file", async () => {
    vi.stubEnv("NODE_ENV", "development");
    vi.stubEnv("GOOGLE_APPLICATION_CREDENTIALS", "/tmp/fake-service-account.json");
    fsMocks.existsSync.mockImplementation((candidate) => candidate === "/tmp/fake-service-account.json");

    const { getAdminApp } = await loadServerModule();
    getAdminApp();

    expect(firebaseAppMocks.cert).toHaveBeenCalledOnce();
    expect(firebaseAppMocks.applicationDefault).not.toHaveBeenCalled();
    expect(fsMocks.readFileSync).toHaveBeenCalledWith("/tmp/fake-service-account.json", "utf8");
    expect(firebaseAppMocks.initializeApp).toHaveBeenCalledWith({
      credential: { kind: "cert" },
      projectId: "wain-d2e28",
    });
  });

  it("uses applicationDefault in development when no JSON key file exists", async () => {
    vi.stubEnv("NODE_ENV", "development");
    fsMocks.existsSync.mockReturnValue(false);

    const { getAdminApp } = await loadServerModule();
    getAdminApp();

    expect(firebaseAppMocks.applicationDefault).toHaveBeenCalledOnce();
    expect(firebaseAppMocks.cert).not.toHaveBeenCalled();
    expect(firebaseAppMocks.initializeApp).toHaveBeenCalledWith({
      credential: { kind: "adc" },
      projectId: "wain-d2e28",
    });
  });
});
