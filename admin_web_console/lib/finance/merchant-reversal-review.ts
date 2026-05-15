export const REVERSAL_SINGLE_APPROVAL_LIMIT_ILS = 100;
export const REVERSAL_SUPER_ADMIN_THRESHOLD_ILS = 500;

export type PredictedReversalPath =
  | {
      kind: "direct";
      label: string;
    }
  | {
      kind: "needs_finance_admin";
      label: string;
    }
  | {
      kind: "needs_super_admin";
      label: string;
    };

export function predictReversalPath(amount: number): PredictedReversalPath {
  if (amount <= REVERSAL_SINGLE_APPROVAL_LIMIT_ILS) {
    return {
      kind: "direct",
      label: "سيُنفَّذ التصحيح مباشرة",
    };
  }

  if (amount <= REVERSAL_SUPER_ADMIN_THRESHOLD_ILS) {
    return {
      kind: "needs_finance_admin",
      label: "سيتطلب موافقة ثانية من finance_admin",
    };
  }

  return {
    kind: "needs_super_admin",
    label: "سيتطلب موافقة ثانية من super_admin",
  };
}
