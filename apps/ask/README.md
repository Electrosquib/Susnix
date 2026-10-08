# ask

A small terminal command for DeepSeek V4.1 Flash. Uses Python 3's standard
library: no SDK, background service, shell execution, or local conversation log.
Answers stream to stdout; errors go to stderr and return a nonzero exit code.
Each invocation sends only its question, with no local files or previous history.

```bash
bash scripts/setup-ask.sh
export PATH="$HOME/.local/bin:$PATH"  # current terminal; new Bash terminals get this automatically
export DEEPSEEK_API_KEY='your-key'
ask whats the weight of the moon
ask "What's the moon's mass?"
ask --help
```

Alternatively copy [.env.example](.env.example) to `~/Desktop/.env`, replace the
placeholder key, and run `chmod 600 ~/Desktop/.env`. The command also honors the
Desktop directory in `~/.config/user-dirs.dirs` (or `$XDG_CONFIG_HOME`). You do
not need to source the file. It is parsed as data: shell commands and variable
expansion in values are never executed. Quotes, comments, and `export KEY=value`
are supported. Exported Bash variables override file values, including empty
values. Unrelated keys are ignored. Real `.env` files are excluded from Git.

| Variable | Default / purpose |
| --- | --- |
| `DEEPSEEK_API_KEY` | Required API key |
| `DEEPSEEK_MODEL` | `deepseek-flash`, the API name for V4.1 Flash |
| `DEEPSEEK_BASE_URL` | `https://api.deepseek.com`; `/v1` also works |
| `ASK_TIMEOUT` | 120 seconds without network data |
| `ASK_ENV_FILE` | Export in Bash to select another `.env` file |

Non-thinking mode is used for fast answers. To override the model:

```bash
DEEPSEEK_MODEL=deepseek-v4-pro ask explain this concept
ASK_ENV_FILE="$HOME/.config/susnix/deepseek.env" ask hello
```

Bash interprets special characters before `ask` runs; quote questions containing
apostrophes, wildcards, shell operators, or substitutions. `Ctrl+C` cancels.
Missing credentials, timeouts, interrupted answers, rate limits, and account
errors produce short messages. Redirects are refused so credentials are not
forwarded to another host. HTTPS is required. Streamed terminal control
characters are stripped. No automatic retries or duplicated paid requests.

The installer preserves `.bashrc`, appending one idempotent PATH entry, and
installs `~/.local/bin/ask`. Bootstrap invokes the same installer. Open a new
Bash terminal after installation or use the PATH export above.

Validation: `python3 tests/test-ask.py -v` (offline; no API key required).
Official API/model reference: [DeepSeek API](https://api-docs.deepseek.com/en/).
