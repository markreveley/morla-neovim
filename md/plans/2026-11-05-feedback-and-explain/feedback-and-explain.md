# Feedback in plain English, and a plain-English line beside each command

> Status: done · 2026-11-05 · from the operator's use case (thread of 5 Nov 2026); live run in [`tested/2026-11-05-1915-live.md`](../../tested/2026-11-05-1915-live.md)

The operator does not read or write Vimscript. Two things the first version
assumed do not hold for them: that a wrong translation gets corrected by
hand, and that the line is read before Enter. This plan lets them complain
in plain English ("didn't work, rerun") and tells them in plain English
what each command will do.

Built. The decisions moved to `governance/ARCHITECTURE.md` as design:

| here | ARCHITECTURE |
|---|---|
| D1. The reply is one JSON object: command, explanation, feedback flag | [D8](../../governance/ARCHITECTURE.md#d8-the-reply-is-one-json-object-command-explanation-feedback-flag) |
| D2. The model sees the last command that ran, and judges | [D9](../../governance/ARCHITECTURE.md#d9-the-model-sees-the-last-run-and-judges-whether-the-line-is-about-it) |
| D3. A complaint marks the last run wrong by appending, never rewriting | [D10](../../governance/ARCHITECTURE.md#d10-a-complaint-marks-the-last-run-wrong-by-appending) |
| D4. The explanation sits beside the line, after the flags | [D11](../../governance/ARCHITECTURE.md#d11-the-explanation-sits-beside-the-line-after-the-flags) |
| D5. The buffer's lines go with each request, numbered (added during the build, from the live run) | [D12](../../governance/ARCHITECTURE.md#d12-the-buffers-lines-go-with-each-request-numbered) |
| D6. Sonnet by default (added during the build, from the live run) | [D2](../../governance/ARCHITECTURE.md#d2-claude--p-with-settings-tools-and-mcp-off-in-a-folder-of-its-own), revised |
