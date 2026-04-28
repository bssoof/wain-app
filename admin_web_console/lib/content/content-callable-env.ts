import {
  createFinanceCallableInvokerFromEnv,
  type FinanceCallableInvokerResolution,
} from "@/lib/finance/finance-command-transport";

export function createContentCallableInvokerFromEnv(
  env: Record<string, string | undefined> = process.env,
): FinanceCallableInvokerResolution {
  return createFinanceCallableInvokerFromEnv({
    ...env,
    NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL:
      env.NEXT_PUBLIC_WAIN_CONTENT_FUNCTIONS_BASE_URL ??
      env.NEXT_PUBLIC_WAIN_FINANCE_FUNCTIONS_BASE_URL,
    NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN:
      env.NEXT_PUBLIC_WAIN_CONTENT_AUTH_TOKEN ??
      env.NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN,
    NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN:
      env.NEXT_PUBLIC_WAIN_CONTENT_APP_CHECK_TOKEN ??
      env.NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN,
  });
}
