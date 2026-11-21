/**
 * Codex router - plan on a strong Codex model, implement on a cheap one.
 *
 * Adapted from pi's examples/extensions/jev-router.ts for this machine:
 * - the classifier is used from TypeSafe directly (TYPESAFE_API_KEY) and falls back to OpenRouter;
 * - planning uses the 500K-context gpt-6.1 generation, implementation uses gpt-6-luna;
 * - everything else (compaction, direct calls) stays on the cheap model.
 *
 * Registers `codex/auto`. Usage: pi --model codex/auto
 */

import type { Message } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext, ModelRoute, ModelRouteRequest } from "@earendil-works/pi-coding-agent";

const PROVIDER = "openai-codex";
const SOL = "gpt-6.1-sol";
const TERRA = "gpt-6.1-terra";
const LUNA = "gpt-6-luna";

/** Classifier candidates, best first. */
const CLASSIFIERS: [string, string][] = [
	["typesafe", "jev-latest"],
	["openrouter", "~typesafe/jev-latest"],
];

/** Tools whose successful result means implementation has started. */
const EDIT_TOOLS = new Set(["edit", "write"]);

interface RouterState {
	phase: "planning" | "implementation";
	model: string;
}

type RouterRequest = ModelRouteRequest<RouterState>;

function routeTo(request: RouterRequest, ctx: ExtensionContext, id: string, state?: RouterState): ModelRoute<RouterState> {
	const model = ctx.modelRegistry.find(PROVIDER, id);
	if (!model) throw new Error(`Model ${PROVIDER}/${id} is not in the catalog`);
	return { model, thinkingLevel: request.thinkingLevel, state };
}

function lastUserText(messages: readonly Message[]): string {
	const content = messages.filter((message) => message.role === "user").at(-1)?.content ?? "";
	if (typeof content === "string") return content;
	return content.flatMap((block) => (block.type === "text" ? [block.text] : [])).join("\n");
}

/** Whether a tool call since the last user message edited a file successfully. */
function editedThisTurn(messages: readonly Message[]): boolean {
	const lastUser = messages.findLastIndex((message) => message.role === "user");
	return messages
		.slice(lastUser + 1)
		.some((message) => message.role === "toolResult" && EDIT_TOOLS.has(message.toolName) && !message.isError);
}

/** Planning model: Sol for complex work, Terra otherwise or when no classifier is reachable. */
async function choosePlanningModel(request: RouterRequest, ctx: ExtensionContext): Promise<string> {
	// Keep a planning model the session already uses, so switching to codex/auto costs no cache miss.
	const previous = request.previous?.model;
	if (previous?.provider === PROVIDER && (previous.id === SOL || previous.id === TERRA)) return previous.id;

	for (const [provider, id] of CLASSIFIERS) {
		const classifier = ctx.modelRegistry.findOfType("classifier", provider, id);
		if (!classifier) continue;
		try {
			const result = await ctx.modelRegistry.classify(
				classifier,
				{
					state: { prompt: lastUserText(request.messages).slice(0, 16_000) },
					questions: {
						complexity: {
							type: "choice",
							instructions: "How demanding is the software engineering work requested in `prompt`?",
							criteria: {
								standard: "Ordinary features, fixes, reviews, or questions",
								complex: "Subtle design, cross-cutting changes, or hard debugging",
							},
						},
					},
				},
				{ signal: request.signal },
			);
			if (result.stopReason !== "stop") continue;
			const answer = result.answers.complexity;
			if (answer?.type === "choice") {
				return (answer.probabilities.complex ?? 0) >= 0.5 ? SOL : TERRA;
			}
		} catch {
			// Fall through to the next classifier, then to the default.
		}
	}
	return TERRA;
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
			if (request.reason === "direct") return routeTo(request, ctx, LUNA);
			const state = request.state;
			if (!state) {
				const model = await choosePlanningModel(request, ctx);
				return routeTo(request, ctx, model, { phase: "planning", model });
			}
			// The planning model made its first edit: hand the rest of the work to Luna.
			if (state.phase === "planning" && editedThisTurn(request.messages)) {
				return routeTo(request, ctx, LUNA, { phase: "implementation", model: LUNA });
			}
			return routeTo(request, ctx, state.model);
		},
	});
}
