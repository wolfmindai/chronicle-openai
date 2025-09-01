# Chronicle OpenAI

Structured Chronicle entries (attestations) in YAML, organized by year/month.
All commits should be GPG-signed to preserve provenance (Veritas principle).

Layout:
- schema/ : JSON Schema for Chronicle entries
- scripts/: helper tools (new entry, validation, etc.)
- attestations/YYYY/MM/: timestamped YAML entries
- .pre-commit-config.yaml: linting and validation hooks

Filename format:
YYYY-MM-DDTHH-mm-SSZ--<user>--<topic-slug>--<rid>.yaml
# chronicle-openai
