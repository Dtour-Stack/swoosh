---
name: dtour-token-gating
description: How $DTOUR token gating works — what's free, what can require stake
category: protocol
tags: [dtour, token, stake, gating, opt-in]
trust: promoted
platforms: [macOS, iOS]
triggers:
  - dtour
  - token gate
  - stake required
---

# $DTOUR Token Gating

## Principle: Everything is free

Swoosh is a consumer app. **Every feature works without $DTOUR tokens.**
There is no paywall on chat, memory, skills, goals, scout, workflows, or
any tool — including all onchain trading.

## What's free (everything that ships today)

- **All crypto tools** — EVM, Solana, Jupiter, Hyperliquid, Uniswap
  - Swapping, transferring, reading balances, building transactions
- **All agent features** — chat, memory, skills, goals, scout, workflows
- **All non-crypto tools** — files, git, terminal, swift dev, MCP, gaming

No shipping tool currently sets `isTokenGated = true`, so **nothing
requires staking $DTOUR right now**.

## The stake-gate mechanism (dormant, retained for future use)

The runtime carries a stake gate for any future premium, high-value
onchain action. A tool opts in by declaring `isTokenGated = true`; only
then does `ToolRegistry` consult the `StakeGateActor` before executing it.

When a token-gated tool is eventually introduced, the flow is:

1. User connects a wallet (optional today; required for gated trades)
2. User stakes $DTOUR via the on-chain Swoosh Protocol program
3. `StakeGateActor` checks on-chain stake for that toolset when the tool runs
4. If stake is sufficient → tool executes (still needs approval if risk=critical)
5. If insufficient → blocked with an "insufficient stake" message

The configurable stake requirements (`StakeGateConfig.default`) cover the
high-value trade toolsets — `hyperliquidTrade`, `evmBuildTransaction`,
`solanaSubmitTransaction`, `uniswap` — but these only take effect for a
tool that has flagged itself token-gated.

## How it does NOT work

- No wallet required to use the app
- No stake required for any tool that ships today, including crypto trading
- Receipt tracking only activates when a wallet is connected
- Rebates are earned passively — no action needed beyond using crypto tools
