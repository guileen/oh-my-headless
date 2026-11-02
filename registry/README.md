# Registry

One manifest per tool: `<id>.yaml`. Schema: [`_schema.json`](./_schema.json).

Status: `omh` reads `checks.*`. Machine-private notes → `../local/` (gitignored).

Built-in gates such as `omh complexity-audit` are dispatched from `bin/omh` (`libexec/omh/`). They are not registry entries.

**Web:** `moli` = lean fetch/CDP · `playwright-cli` = codegen/multi-browser · `crawl4ai` (`crwl`) = LLM markdown/extract.

**Google (concrete):** `colab-cli` = Colab sessions/exec · `drive-dfs` = Drive mount in runtime (`colab dfs`). Separate OAuth each.
