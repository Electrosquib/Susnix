#!/usr/bin/env python3
"""Ask DeepSeek a question without an SDK or shell-evaluated configuration."""

import json
from http.client import HTTPException
import math
import os
from pathlib import Path
import re
import shlex
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener


HELP = """Usage: ask QUESTION...
       ? QUESTION...
Example: ask whats the weight of the moon
         ? whats the weight of the moon?

Uses DeepSeek V4.1 Flash (deepseek-flash) and streams the answer.
Export DEEPSEEK_API_KEY in Bash or put it in ~/Desktop/.env.
Exported variables override the file. XDG Desktop paths are supported.

Optional environment / .env settings:
  DEEPSEEK_MODEL       default: deepseek-flash
  DEEPSEEK_BASE_URL    default: https://api.deepseek.com
  ASK_TIMEOUT         seconds without network data, default: 120
  ASK_ENV_FILE        explicit .env path (export in Bash)

Each invocation is a fresh question. Nothing is saved locally.
Use quotes for shell characters: ask "What's the moon's mass?"
"""
CONFIG_KEYS = {"DEEPSEEK_API_KEY", "DEEPSEEK_MODEL", "DEEPSEEK_BASE_URL", "ASK_TIMEOUT"}


class AskError(Exception):
    pass


class NoRedirect(HTTPRedirectHandler):
    # Do not forward the bearer key to another host via an HTTP redirect.
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def desktop_path(env):
    home = Path(env.get("HOME", str(Path.home())))
    config = Path(env.get("XDG_CONFIG_HOME", str(home / ".config")))
    try:
        for line in (config / "user-dirs.dirs").read_text(encoding="utf-8").splitlines():
            match = re.match(r'^\s*XDG_DESKTOP_DIR\s*=\s*(.*)$', line)
            if match:
                words = shlex.split(match[1], comments=True)
                if len(words) == 1:
                    raw = words[0].replace("${HOME}", str(home)).replace("$HOME", str(home))
                    path = Path(raw)
                    if path.is_absolute():
                        return path
    except FileNotFoundError:
        pass
    except (OSError, UnicodeError, ValueError) as error:
        raise AskError("Cannot read XDG Desktop configuration.") from error
    return home / "Desktop"


def load_settings(env):
    explicit = env.get("ASK_ENV_FILE")
    path = Path(os.path.expanduser(explicit)) if explicit else desktop_path(env) / ".env"
    values = {}
    try:
        lines = path.read_text(encoding="utf-8-sig").splitlines()
    except FileNotFoundError:
        if explicit:
            raise AskError(f"Configuration file does not exist: {path}")
        lines = []
    except (OSError, UnicodeError) as error:
        raise AskError(f"Cannot read configuration file: {path}") from error
    for number, line in enumerate(lines, 1):
        match = re.match(r'^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$', line)
        if not match or match[1] not in CONFIG_KEYS or match[1] in env:
            continue
        try:
            words = shlex.split(match[2], comments=True, posix=True)
        except ValueError as error:
            raise AskError(f"Invalid quoted value in {path}, line {number}.") from error
        if len(words) > 1:
            raise AskError(f"Quote values containing spaces in {path}, line {number}.")
        values[match[1]] = words[0] if words else ""
    values.update({key: env[key] for key in CONFIG_KEYS if key in env})
    key = values.get("DEEPSEEK_API_KEY", "").strip()
    if not key:
        raise AskError(f"Set DEEPSEEK_API_KEY in Bash or {path} before asking a question.")
    if any(ord(char) < 32 or ord(char) > 126 for char in key):
        raise AskError("DEEPSEEK_API_KEY contains invalid characters.")
    base = values.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com").rstrip("/")
    try:
        url = urlsplit(base)
    except ValueError as error:
        raise AskError("DEEPSEEK_BASE_URL is not a valid URL.") from error
    if url.scheme != "https" or not url.hostname or url.username or url.password or url.query or url.fragment:
        raise AskError("DEEPSEEK_BASE_URL must be an HTTPS URL without credentials, query or fragment.")
    model = values.get("DEEPSEEK_MODEL", "deepseek-flash").strip()
    if not model:
        raise AskError("DEEPSEEK_MODEL must not be empty.")
    try:
        timeout = float(values.get("ASK_TIMEOUT", "120"))
    except ValueError as error:
        raise AskError("ASK_TIMEOUT must be a positive number of seconds.") from error
    if not math.isfinite(timeout) or timeout <= 0:
        raise AskError("ASK_TIMEOUT must be a positive number of seconds.")
    return key, base, model, timeout


def events(response):
    """Read complete SSE events; tolerate keepalives and multi-line data."""
    data = []
    for raw in response:
        line = raw.decode("utf-8").rstrip("\r\n")
        if not line:
            if data:
                yield "\n".join(data)
                data = []
        elif line.startswith("data:"):
            data.append(line[5:].lstrip(" "))
    if data:
        yield "\n".join(data)


def ask(question, settings, output, opener=None):
    key, base, model, timeout = settings
    body = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": question}],
        "thinking": {"type": "disabled"},
        "stream": True,
    }).encode("utf-8")
    request = Request(base + "/chat/completions", data=body, headers={
        "Authorization": "Bearer " + key,
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
    }, method="POST")
    opener = opener or build_opener(NoRedirect())
    received = False
    finished = False
    try:
        with opener.open(request, timeout=timeout) as response:
            for event in events(response):
                if event == "[DONE]":
                    finished = True
                    break
                chunk = json.loads(event)
                if "error" in chunk:
                    raise AskError("DeepSeek returned a stream error. Try again or check your API account.")
                for choice in chunk.get("choices", []):
                    content = choice.get("delta", {}).get("content")
                    if content:
                        if not isinstance(content, str):
                            raise AskError("DeepSeek returned an unexpected answer format.")
                        # Never let model text execute terminal escape sequences.
                        output.write("".join(c for c in content if c in "\n\t" or (ord(c) >= 32 and not 127 <= ord(c) <= 159)))
                        output.flush()
                        received = True
                    reason = choice.get("finish_reason")
                    if reason == "length":
                        raise AskError("Answer reached the API output limit and was truncated.")
                    if reason:
                        finished = True
    except HTTPError as error:
        message = {
            400: "Request rejected; check DEEPSEEK_MODEL and DEEPSEEK_BASE_URL.",
            401: "API key rejected; check DEEPSEEK_API_KEY.",
            402: "Your DeepSeek API account needs credit.",
            403: "Your DeepSeek API account cannot access this model.",
            404: "Endpoint or model unavailable; check DEEPSEEK_BASE_URL and DEEPSEEK_MODEL.",
            429: "DeepSeek rate limit reached. Try again shortly.",
        }.get(error.code, "DeepSeek request failed. Try again shortly.")
        raise AskError(f"HTTP {error.code}: {message}") from error
    except BrokenPipeError:
        raise
    except (URLError, OSError, HTTPException) as error:
        raise AskError("Cannot reach DeepSeek or the connection timed out. Check your connection and ASK_TIMEOUT.") from error
    except (ValueError, KeyError, TypeError, AttributeError) as error:
        raise AskError("DeepSeek returned an invalid response.") from error
    finally:
        if received:
            output.write("\n")
            output.flush()
    if not received:
        raise AskError("DeepSeek returned no answer. Try again.")
    if not finished:
        raise AskError("Connection ended before the answer finished. Try again.")


def main(argv=None):
    args = sys.argv[1:] if argv is None else argv
    if args in (["--help"], ["-h"]):
        print(HELP, end="")
        return 0
    if args and args[0] == "--":
        args = args[1:]
    question = " ".join(args).strip()
    if not question:
        print(HELP, end="", file=sys.stderr)
        return 2
    try:
        ask(question, load_settings(os.environ), sys.stdout)
    except AskError as error:
        print(f"ask: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nask: cancelled", file=sys.stderr)
        return 130
    except BrokenPipeError:
        # Consumers such as `head` may close the pipe before the stream ends.
        os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
