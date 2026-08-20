// Output policy for the local emulator seeder.
//
// The seed result carries three secrets — the admin password, a signed-in ID
// token and an App Check token. stdout is a console, a scrollback buffer and,
// under CI, a log file, so none of them are printed there unless asked for
// explicitly. Kept in its own module because it is the security-relevant half
// of the seeder and the half worth testing without a running emulator.

import { chmod, mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";

/// Every field of the seed result that must not reach stdout on its own.
export const SECRET_FIELDS = [
  ["admin", "password"],
  ["tokens", "authToken"],
  ["tokens", "appCheckToken"],
];

/// `--out FILE` is the machine path: the full payload goes to the file and
/// stdout keeps a redacted copy of the same shape. `--print-secrets` is the
/// deliberate escape hatch for a human who wants to copy a token by hand.
export function parseOutputOptions(argv) {
  const args = [...argv];

  const readFlagValue = (name) => {
    const inline = args.find((arg) => arg.startsWith(`${name}=`));
    if (inline !== undefined) {
      const value = inline.slice(name.length + 1);
      if (value === "") {
        throw new Error(`${name} needs a file path.`);
      }
      return value;
    }

    const index = args.indexOf(name);
    if (index === -1) {
      return undefined;
    }

    const value = args[index + 1];
    if (value === undefined || value.startsWith("--")) {
      throw new Error(`${name} needs a file path.`);
    }

    return value;
  };

  return {
    outPath: readFlagValue("--out"),
    printSecrets: args.includes("--print-secrets"),
  };
}

export function redactSecrets(result) {
  const copy = structuredClone(result);

  for (const [group, field] of SECRET_FIELDS) {
    const value = copy[group]?.[field];
    if (typeof value !== "string") continue;
    // Keep the length: it is the one thing worth seeing (a truncated token and
    // a missing token look identical downstream) and it reveals nothing.
    copy[group][field] = `<redacted, ${value.length} chars>`;
  }

  return copy;
}

export async function writeSeedFile(path, payload) {
  const resolved = resolve(path);
  await mkdir(dirname(resolved), { recursive: true });
  await writeFile(resolved, `${JSON.stringify(payload, null, 2)}\n`, {
    encoding: "utf8",
    mode: 0o600,
  });

  // `mode` above only applies when the file is created; an existing file keeps
  // whatever permissions it already had. On Windows this is close to a no-op,
  // which is why the file belongs under the gitignored .tmp/ rather than
  // relying on permissions alone.
  try {
    await chmod(resolved, 0o600);
  } catch {
    // Non-fatal: a file the operator chose still beats stdout.
  }

  return resolved;
}
