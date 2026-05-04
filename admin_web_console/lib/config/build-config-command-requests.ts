import type {
	ConfigCommandRequestMap,
	ConfigCommandType,
} from "./config-command-contracts";
import type {
	ConfigDraftStatus,
	ConfigPricing,
} from "./config-governance-models";

export type BuildConfigCommandRequestInput = {
	pricing: ConfigPricing;
	draftStatus: ConfigDraftStatus;
	draftVersion: number;
	liveVersion: number;
	rollbackToVersion?: number;
	reason?: string;
	note?: string;
	now?: () => Date;
};

export function commandKey(command: ConfigCommandType): string {
	return `config:${command}`;
}

export function buildConfigCommandRequest<T extends ConfigCommandType>(
	command: T,
	input: BuildConfigCommandRequestInput,
): ConfigCommandRequestMap[T] {
	const now = input.now ?? (() => new Date());
	const submittedAt = now().toISOString();
	const unique = `${now().getTime()}_${Math.floor(Math.random() * 1_000_000)}`;
	const base = {
		commandId: `${command}_${unique}`,
		correlationId: `config:${command}:${unique}`,
		reason: input.reason ?? `Config governance action ${command}`,
		submittedAt,
		...(input.note
			? {
					note: input.note,
				}
			: {}),
	};

	switch (command) {
		case "config_upsert_draft":
			return {
				...base,
				action: "config_upsert_draft",
				pricing: input.pricing,
				expectedState: {
					draft_status: input.draftStatus,
					...(input.draftVersion > 0
						? {
								draft_version: input.draftVersion,
							}
						: {}),
				},
			} as ConfigCommandRequestMap[T];
		case "config_review_draft":
			return {
				...base,
				action: "config_review_draft",
				expectedState: {
					draft_status: "drafted",
					...(input.draftVersion > 0
						? {
								draft_version: input.draftVersion,
							}
						: {}),
				},
			} as ConfigCommandRequestMap[T];
		case "publish_config":
			return {
				...base,
				action: "publish_config",
				expectedState: {
					draft_status: "reviewed",
					target_live_version: input.liveVersion,
					...(input.draftVersion > 0
						? {
								draft_version: input.draftVersion,
							}
						: {}),
				},
			} as ConfigCommandRequestMap[T];
		case "rollback_config":
			return {
				...base,
				action: "rollback_config",
				rollbackToVersion: input.rollbackToVersion ?? Math.max(1, input.liveVersion),
				expectedState: {
					current_live_version: input.liveVersion,
				},
			} as ConfigCommandRequestMap[T];
		default:
			throw new Error(`Unsupported config command: ${String(command)}`);
	}
}
