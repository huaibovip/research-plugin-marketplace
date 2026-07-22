# research-marketplace

Community-driven research collection of plugins, agents, prompts, and skills


## Install Marketplace

Add this marketplace to Agent (`Claude Code` / `Codex` / `Copilot`):

```bash
# claude / copilot
/plugin marketplace add huaibovip/research-marketplace@git

# codex
codex plugin marketplace add huaibovip/research-marketplace@git
```

or

```bash
# claude / copilot (ssh)
/plugin marketplace add git@github.com:huaibovip/research-marketplace.git#git

# codex (ssh)
codex plugin marketplace add git@github.com:huaibovip/research-marketplace.git#git
```


## Update Marketplace
```bash
# claude
claude plugin marketplace update research-marketplace

# copilot
copilot plugin marketplace update research-marketplace

# codex
codex plugin marketplace upgrade research-marketplace
```

## Available Plugins

### [Research Writing assistant](https://github.com/Norman-bury/research-writing-skill)

**Description:** 面向中文科研论文的AI写作助手: 支持头脑风暴、章节写作、文献综述、Python图表、LaTeX输出

```bash
# claude / coplit
/plugin install research-writing-assistant@research-marketplace

# codex
codex plugin add research-writing-assistant@research-marketplace
```

---

### [Academic Research Skills](https://github.com/Imbad0202/academic-research-skills)

**Description:** Academic Research Skills — production-grade research, writing, peer review, and pipeline orchestration

```bash
# claude / coplit
/plugin install academic-research-skills@research-marketplace

# codex
codex plugin add academic-research-skills@research-marketplace
```

---

### [Academic Research Suite](https://github.com/Imbad0202/academic-research-skills-codex)

**Description:** Academic Research Skills (Codex) — production-grade research, writing, peer review, and pipeline orchestration

```bash
# claude / coplit
/plugin install academic-research-suite@research-marketplace

# codex
codex plugin add academic-research-suite@research-marketplace
```

---

### [Nature Skills](https://github.com/Yuan1z0825/nature-skills)

**Description:** Academic workflow bundles for Nature-style scientific work — figures, manuscript writing and polishing, reviewer assessment, citation management, data availability, paper reading, literature search, response letters, and paper-to-presentation conversion

```bash
# claude / coplit
/plugin install nature-skills@research-marketplace

# codex
codex plugin add nature-skills@research-marketplace
```

---

### [Zotero-CLI](https://github.com/Agents365-ai/zotero-cli-cc)

**Description:** Plugin collection for Zotero-based research workflows

```bash
# claude / coplit
/plugin install zotero-cli@research-marketplace

# codex
codex plugin add zotero-cli@research-marketplace
```

### [Papper-Spine](https://github.com/WUBING2023/PaperSpine)

**Description:** Contribution-first, reviewer-aware academic paper and report writing system

```bash
# claude / coplit
/plugin install paper-spine@research-marketplace

# codex
codex plugin add paper-spine@research-marketplace
```

### [Codex-Plugin-CC (Claude only)](https://github.com/openai/codex-plugin-cc)

**Description:** Use Codex from Claude Code to review code or delegate tasks

```bash
# claude
/plugin install codex@research-marketplace
```
---

## Marketplace Structure

```
research-marketplace/
├── .agents/plugins/        # Codex
│   └── marketplace.json
├── .claude-plugin/         # Claude Code
│   └── marketplace.json
├── .github/plugin/         # Copilot
│   └── marketplace.json
├── LICENSE
└── README.md
```

## Uninstall Marketplace

```bash
# claude / coplit
/plugin marketplace remove research-marketplace

# codex
codex plugin marketplace remove research-marketplace
```

## Support

- **Issues**: https://github.com/huaibovip/research-marketplace/issues

## License

Marketplace metadata: Apache-2.0 license

Individual plugins: See respective plugin licenses
