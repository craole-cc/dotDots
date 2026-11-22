import { createRequire } from 'node:module'
import { createInterface } from 'node:readline/promises'
import { Writable } from 'node:stream'
import { pathToFileURL } from 'node:url'

export async function signIn(authorization, key, interaction, signal) {
  if (!authorization.describe(key)?.methods.some(method => method.id === 'oauth')) {
    throw new Error('This DSH package does not offer Codex OAuth.')
  }
  return authorization.begin({ key, method: 'oauth', interaction, signal })
}

export async function openAuthorization(anchor) {
  const resolve = createRequire(anchor).resolve
  const load = name => import(pathToFileURL(resolve(`@deepseek-ai/${name}`)))
  const [
    { Context }, { default: Credentials }, { credentialKey },
    { default: Authorization }, { default: Llm }, adapter,
  ] = await Promise.all([
    'cordis', 'dsh-credentials-local', 'dsh-credentials',
    'dsh-authorization', 'dsh-llm', 'dsh-llm-pi-ai',
  ].map(load))
  const ctx = new Context()
  try {
    await ctx.plugin(Credentials, { watch: false })
    await ctx.plugin(Authorization)
    await ctx.plugin(Llm)
    await ctx.plugin(adapter, {})
    return { ctx, key: credentialKey('llm-pi-ai', 'openai-codex') }
  } catch (error) {
    await ctx.fiber.dispose()
    throw error
  }
}

async function main(anchor) {
  if (!process.stdin.isTTY || !process.stderr.isTTY) {
    throw new Error('Run deepseek-codex-login in an interactive terminal.')
  }
  const { ctx, key } = await openAuthorization(anchor)
  const cancel = new AbortController()
  const interrupt = () => cancel.abort()
  const terminal = createInterface({
    input: process.stdin,
    output: new Writable({ write(_chunk, _encoding, done) { done() } }),
    terminal: true,
    historySize: 0,
  })
  terminal.on('SIGINT', interrupt)
  terminal.on('close', interrupt)
  process.once('SIGTERM', interrupt)
  try {
    const outcome = await signIn(ctx.authorization, key, {
      notify({ message, url, code }) {
        for (const line of [message, url, code]) if (line) process.stderr.write(`${line}\n`)
      },
      async prompt({ message, options, signal }) {
        const promptSignal = signal ? AbortSignal.any([signal, cancel.signal]) : cancel.signal
        process.stderr.write(`${message}\n`)
        options?.forEach((option, index) => process.stderr.write(`  ${index + 1}. ${option.label}\n`))
        try {
          while (true) {
            process.stderr.write(options ? 'Choice number: ' : 'Input is hidden: ')
            const answer = await terminal.question('', { signal: promptSignal })
            process.stderr.write('\n')
            if (!options) return answer
            const choice = options[Number(answer) - 1]
            if (choice) return choice.id
          }
        } finally {
          if (promptSignal.aborted) process.stderr.write('\n')
        }
      },
    }, cancel.signal)
    console.log(outcome.status === 'authorized' ? 'DSH Codex sign-in complete.' : 'DSH Codex sign-in cancelled.')
    if (outcome.status === 'cancelled') process.exitCode = 130
  } finally {
    terminal.close()
    process.removeListener('SIGTERM', interrupt)
    await ctx.fiber.dispose()
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv[2]).catch(() => {
    console.error('DSH Codex sign-in failed. Check that the installed package supports Codex OAuth and retry.')
    process.exitCode = 1
  })
}
