# CLAUDE

## General

- Always respond in English (en-US), even if the user writes in another language, unless they
  explicitly ask for a response in a different language.
- If a LSP is available:
  - Use Grep/Glob for discovery (finding files, searching patterns).
  - Use LSP for understanding (definitions, references, type info, call hierarchies).
  - After locating a file with Grep/Glob, prefer LSP for symbol navigation; read the file when
    understanding logic or control flow requires it.
- When answering questions about frameworks or programming languages, always include a link
  to the relevant official documentation and quote the specific passage that supports your answer.
- While performing a task, flag any errors or issues you notice in the file as a side note,
  even if they are unrelated to the current request. This includes:
  - Logic errors or bugs in code.
  - Spelling mistakes or grammatical issues in documentation or comments.
  - Outdated comments that no longer reflect the current code.
- When asked to review a file or check a revision, re-read it first to pick up any changes
  made since it was last read.

## Commands

- Prefer to use PowerShell (`pwsh`) for executing commands on Windows.

## Comments and Documentation

- Only use ASCII characters in documentation.
- When a public member's behavior changes, verify that its documentation (if any) still matches the
  implementation.
- If a changelog exists, record changes to the public API surface there, following its established
  writing conventions.
- Keep documentation short and concise. The target audience is well-versed with the .NET ecosystem.
- Do not translate German terminology into English in code or documentation. When in doubt,
  ask the user for permission.
- Wrap lines at 120 characters.
- In C# projects follow these additional rules:
  - Always add XML doc strings to `public` and `internal` members when generating code.
  - Ask the user before adding doc strings to `private` members.
  - For test methods, a `<summary>` tag alone is sufficient; omit all other tags.
  - Follow Microsoft's XML documentation style and language conventions. Match the tone of the
    surrounding file, and suggest deviations from Microsoft's guidelines as improvements.

## Task Management

- Track tasks in a `todo.md` file at the repository root.
- Once a task is completed and acknowledged by the author, delete it instead of marking it as done.
- After completing a task, suggest a commit message in one of two forms:
  - Short: a single-line summary for small, self-contained changes.
  - Verbose: a summary line followed by `*` bullet points, for larger changes that span multiple files.
- In a verbose commit message, add yourself as a contributor (including your current model) whenever you wrote the
  majority of the code.
