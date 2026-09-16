# AI context layer

Context components transform or optimize model context without owning agent orchestration, durable memory, or provider selection.

Current implementation:

- `headroom`: local context proxy. In the composed preset it sits between Hermes and the selected router.

The intended request path is:

`Hermes -> Headroom -> router -> provider`

Headroom remains independently composable through `ai-headroom`.
