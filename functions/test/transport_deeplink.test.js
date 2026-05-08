const test = require("node:test");
const assert = require("node:assert/strict");

const {
  validateDeepLinkUrl,
} = require("../lib/transport.js");

async function expectInvalid(action, expectedMessage) {
  let caught = null;
  try {
    await action();
  } catch (error) {
    caught = error;
  }

  assert.ok(caught, "Expected deep-link validation to fail.");
  assert.equal(caught.code, "invalid-argument");
  assert.match(caught.message, expectedMessage);
}

test("transport deep-link validation allows configured https host", () => {
  assert.doesNotThrow(() =>
    validateDeepLinkUrl("https://known-partner.com/book?ride=1", {
      partnerId: "known-partner",
      allowedHosts: ["known-partner.com"],
    }),
  );
});

test("transport deep-link validation rejects javascript scheme", async () => {
  await expectInvalid(
    () =>
      validateDeepLinkUrl("javascript:alert(1)", {
        allowedHosts: ["known-partner.com"],
      }),
    /transport_deep_link_scheme_rejected/,
  );
});

test("transport deep-link validation rejects file scheme", async () => {
  await expectInvalid(
    () =>
      validateDeepLinkUrl("file:///etc/passwd", {
        allowedHosts: ["known-partner.com"],
      }),
    /transport_deep_link_scheme_rejected/,
  );
});

test("transport deep-link validation rejects intent scheme", async () => {
  await expectInvalid(
    () =>
      validateDeepLinkUrl("intent://scan/#Intent;scheme=zxing;end", {
        allowedHosts: ["known-partner.com"],
      }),
    /transport_deep_link_scheme_rejected/,
  );
});

test("transport deep-link validation rejects unconfigured https host", async () => {
  await expectInvalid(
    () =>
      validateDeepLinkUrl("https://attacker.com/book", {
        allowedHosts: ["known-partner.com"],
      }),
    /transport_deep_link_host_not_allowed/,
  );
});

test("transport deep-link validation allows configured known app scheme", () => {
  assert.doesNotThrow(() =>
    validateDeepLinkUrl("uber://ride?pickup=1,2", {
      partnerId: "uber",
      allowedSchemes: ["uber"],
    }),
  );
});

test("transport deep-link validation allows configured wildcard subdomain", () => {
  assert.doesNotThrow(() =>
    validateDeepLinkUrl("https://m.uber.com/ul/?action=setPickup", {
      partnerId: "uber",
      allowedHosts: ["*.uber.com"],
    }),
  );
});
