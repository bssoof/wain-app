// Run with: npm run test:scripts   (node --test, no emulator and no deps)

import assert from "node:assert/strict";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, describe, test } from "node:test";

import {
  SECRET_FIELDS,
  parseOutputOptions,
  redactSecrets,
  writeSeedFile,
} from "./seed-output.mjs";

/// The shape `main()` builds, with recognisable stand-ins for the secrets.
function sampleResult() {
  return {
    projectId: "wain-d2e28",
    emulatorHosts: { auth: "127.0.0.1:9099", firestore: "127.0.0.1:8080" },
    admin: {
      uid: "uid-1",
      email: "local.admin@wain.test",
      password: "WainLocalAdmin!2026",
      role: "super_admin",
    },
    tokens: {
      authToken: "eyJhbGciOiJub25lIn0.header.payload.signature",
      appCheckToken: "local-dev-app-check",
    },
    seeded: { venueId: "local_emulator_venue_01" },
  };
}

const scratchDirs = [];

after(async () => {
  await Promise.all(
    scratchDirs.map((dir) => rm(dir, { recursive: true, force: true })),
  );
});

describe("parseOutputOptions", () => {
  test("defaults to redacted stdout and no file", () => {
    assert.deepEqual(parseOutputOptions([]), {
      outPath: undefined,
      printSecrets: false,
    });
  });

  test("accepts --out in both spellings", () => {
    assert.equal(parseOutputOptions(["--out", "seed.json"]).outPath, "seed.json");
    assert.equal(parseOutputOptions(["--out=seed.json"]).outPath, "seed.json");
  });

  test("rejects --out without a path rather than silently redacting", () => {
    // The failure mode this guards: `--out --print-secrets` swallowing the
    // second flag as a filename, so the operator gets neither.
    assert.throws(() => parseOutputOptions(["--out"]), /needs a file path/);
    assert.throws(
      () => parseOutputOptions(["--out", "--print-secrets"]),
      /needs a file path/,
    );
    assert.throws(() => parseOutputOptions(["--out="]), /needs a file path/);
  });

  test("--print-secrets is opt-in only", () => {
    assert.equal(parseOutputOptions(["--print-secrets"]).printSecrets, true);
    assert.equal(parseOutputOptions(["--out", "x.json"]).printSecrets, false);
  });
});

describe("redactSecrets", () => {
  test("no secret value survives anywhere in the serialised output", () => {
    const result = sampleResult();
    const serialised = JSON.stringify(redactSecrets(result));

    for (const [group, field] of SECRET_FIELDS) {
      assert.ok(
        !serialised.includes(result[group][field]),
        `${group}.${field} leaked into stdout`,
      );
    }
  });

  test("keeps the shape and the non-secret fields intact", () => {
    const redacted = redactSecrets(sampleResult());

    assert.equal(redacted.projectId, "wain-d2e28");
    assert.equal(redacted.admin.uid, "uid-1");
    assert.equal(redacted.admin.email, "local.admin@wain.test");
    assert.equal(redacted.emulatorHosts.auth, "127.0.0.1:9099");
    assert.equal(redacted.seeded.venueId, "local_emulator_venue_01");
  });

  test("reports the length so a truncated token is distinguishable", () => {
    const result = sampleResult();
    const redacted = redactSecrets(result);

    assert.equal(
      redacted.tokens.authToken,
      `<redacted, ${result.tokens.authToken.length} chars>`,
    );
  });

  test("does not mutate the caller's payload", () => {
    const result = sampleResult();
    redactSecrets(result);

    assert.equal(result.tokens.authToken, sampleResult().tokens.authToken);
    assert.equal(result.admin.password, sampleResult().admin.password);
  });

  test("tolerates a missing secret instead of throwing", () => {
    const result = sampleResult();
    delete result.tokens;

    assert.doesNotThrow(() => redactSecrets(result));
  });
});

describe("writeSeedFile", () => {
  test("writes the unredacted payload and creates missing directories", async () => {
    const dir = await mkdtemp(join(tmpdir(), "wain-seed-"));
    scratchDirs.push(dir);

    const target = join(dir, "nested", "seed.json");
    const written = await writeSeedFile(target, sampleResult());

    const parsed = JSON.parse(await readFile(written, "utf8"));
    assert.equal(parsed.tokens.authToken, sampleResult().tokens.authToken);
    assert.equal(parsed.admin.password, sampleResult().admin.password);
  });

  test("overwrites a previous seed rather than appending to it", async () => {
    const dir = await mkdtemp(join(tmpdir(), "wain-seed-"));
    scratchDirs.push(dir);

    const target = join(dir, "seed.json");
    await writeSeedFile(target, sampleResult());
    await writeSeedFile(target, { ...sampleResult(), projectId: "second-run" });

    const parsed = JSON.parse(await readFile(target, "utf8"));
    assert.equal(parsed.projectId, "second-run");
  });
});
