import { vi, type Mock } from "vitest";

type AsyncMockFn = (...args: any[]) => Promise<unknown>;

export type CallableMockArgs = [
  callableName: string,
  payload: Record<string, unknown>,
];

export function createTypeSafeMockInvoker<TFn extends AsyncMockFn>(
  implementation?: TFn,
): Mock<TFn> {
  if (implementation) {
    return vi.fn(implementation);
  }

  return vi.fn<TFn>();
}

export function readMockCallArgs<TArgs extends unknown[]>(
  mockFn: { mock: { calls: unknown[][] } },
  index = 0,
): TArgs {
  const call = mockFn.mock.calls[index];
  if (!call) {
    throw new Error(`Expected a mock call at index ${index}.`);
  }

  return call as unknown as TArgs;
}

export function readCallableMockCall(
  mockFn: { mock: { calls: unknown[][] } },
  index = 0,
): CallableMockArgs {
  return readMockCallArgs<CallableMockArgs>(mockFn, index);
}