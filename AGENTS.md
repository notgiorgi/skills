# Repository guidance

This repository is public. Treat every committed file and Git history entry as publicly visible.

- Never commit personally identifiable information (PII), customer names, customer-related data, credentials, or other private information.
- Use fictional or sanitized examples and placeholders.
- Review staged changes for sensitive information before committing.

## Local installation

Install changed skills globally from this checkout with `npx skills add . -g --agent '*' --skill <name> -y`. Keep the default symlink install: canonical skills live in `~/.agents/skills`, and agent-specific directories link there.
