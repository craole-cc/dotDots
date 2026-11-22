/** Codex router: plan with the shared planner, implement with the worker. */

import type { Message } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext, ModelRoute } from "@earendil-works/pi-coding-agent";

const PROVIDER = "openai-codex";
// Replaced with the shared Nix policy when the extension is installed.
const POLICY = __ROLE_POLICY__ as const;

/** Tools whose successful result means implementation has started. */
const EDIT_TOOLS = new Set(["edit", "write"]);

interface RouterState {
	phase: "planning" | "implementation";
	model: string;
}

function routeTo(ctx: ExtensionContext, role: { model: string; effort: "low" | "medium" | "high" | "xhigh" | "max" }, state?: RouterState): ModelRoute<RouterState> {
	const model = ctx.modelRegistry.find(PROVIDER, role.model);
	if (!model) throw new Error(`Model ${PROVIDER}/${role.model} is not in the catalog`);
	return { model, thinkingLevel: role.effort, state };
}

/** Whether a tool call since the last user message edited a file successfully. */
function editedThisTurn(messages: readonly Message[]): boolean {
	const lastUser = messages.findLastIndex((message) => message.role === "user");
	return messages
		.slice(lastUser + 1)
		.some((message) => message.role === "toolResult" && EDIT_TOOLS.has(message.toolName) && !message.isError);
}

export default function (pi: ExtensionAPI) {
	pi.registerVirtualModel<RouterState>({
		provider: "codex",
		id: "auto",
		name: "Auto (Codex)",
		thinkingLevels: ["low", "medium", "high", "xhigh", "max"],
		contextWindow: 500_000,
		maxTokens: 128_000,
		async route(request, ctx) {
			if (request.reason === "direct") return routeTo(ctx, POLICY.executor);
			const state = request.state;
			if (!state) {
				return routeTo(ctx, POLICY.planner, { phase: "planning", model: POLICY.planner.model });
			}
			// The planning model made its first edit: hand the rest of the work to the worker.
			if (state.phase === "planning" && editedThisTurn(request.messages)) {
				return routeTo(ctx, POLICY.worker, { phase: "implementation", model: POLICY.worker.model });
			}
			return routeTo(ctx, state.phase === "planning" ? POLICY.planner : POLICY.worker);
		},
	});
}
