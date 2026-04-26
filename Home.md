---
tags: [home, index]
---

# Settings Vault

Personal macOS development environment setup guide and reference.

## Meta

- Agent rules: see [.github/copilot-instructions.md](.github/copilot-instructions.md) (mirrored in [.cursorrules](.cursorrules), [.clinerules](.clinerules), [.windsurfrules](.windsurfrules), [AGENTS.md](AGENTS.md), [CLAUDE.md](CLAUDE.md), [GEMINI.md](GEMINI.md), and [CONVENTIONS.md](CONVENTIONS.md)).

---

## 00 - Setup

- [[Homebrew]] — Package manager; first thing to install
- [[Installations]] — Curated brew packages and goodies
- [[Fonts]] — Font installation
- [[Tweaks]] — macOS enhancements and third-party utilities
- [[Automation]] — Automation tools
- [[Transfer]] — Migrating to a new Mac

## 01 - Terminal

- [[Zsh]] — Oh My Zsh, themes, plugins
- [[iTerm]] — iTerm2 setup and keyboard shortcuts
- [[SSH]] — SSH configuration

## 1-dev

### Install
- [[install/Editors]] — VS Code, Vim, and other editors
- [[install/Git]] — Git setup, gh CLI, aliases
- [[install/Xcode]] — Xcode Command Line Tools
- [[install/Front-End/Vite]] — Modern frontend build tool
- [[install/Front-End/Vitest]] — Fast unit test framework
- [[install/Styling/Tailwind CSS]] — Utility-first CSS framework
- [[install/Styling/ShadCN]] — Component library for React
- [[install/Front-End/Angular]] — Angular CLI
- [[install/NPM Globals]] — Global npm packages
- [[install/Front-End/Next.js]] — Next.js framework
- [[install/SDK]] — SDK management
- [[install/Build Tools/esbuild]] — Extremely fast JS/TS bundler
- [[install/Build Tools/Gradle]] — Gradle build tool
- [[install/Build Tools/Grunt]] — Configuration-based task runner
- [[install/Build Tools/Gulp]] — Streaming build system
- [[install/Build Tools/Just]] — Command runner
- [[install/Build Tools/NX]] — Full-featured monorepo build system
- [[install/Build Tools/Parcel]] — Zero-config bundler
- [[install/Build Tools/Pipelines]] — CI/CD pipelines
- [[install/Build Tools/Rollup]] — ES module bundler for libraries
- [[install/Build Tools/Turborepo]] — Lightweight monorepo build system
- [[install/Build Tools/Webpack]] — Configurable module bundler
- [[install/Infrastructure/Docker]] — Docker and Docker Compose
- [[install/Infrastructure/Kubernetes]] — kubectl, helm, minikube
- [[install/Infrastructure/Rancher Desktop]] — Container and Kubernetes desktop management
- [[install/Node/Volta]] — Volta version manager (recommended)
- [[install/Node/NVM]] — Node Version Manager
- [[install/Node/FNM]] — Fast Node Manager
- [[install/Node/PNPM]] — PNPM package manager
- [[install/Node/Bun]] — Bun runtime and package manager
- [[install/Node/Corepack]] — Node.js built-in package manager manager
- [[install/Agent Config/Agent Config]] — AGENTS.md templates for AI coding agents
- [[install/Agent Config/AGENTS.md Monorepo Root]] — Root-level template for multi-stack repos
- [[install/Agent Config/AGENTS.md Next.js TypeScript]] — Frontend template for Next.js 15 / React 19 / TypeScript
- [[install/Agent Config/AGENTS.md Python FastAPI]] — Backend template for Python / FastAPI / Pydantic
- [[install/Agent Config/AGENTS.md Embedded Edge ML]] — Embedded systems and edge ML template
- [[install/Languages/Programming Languages]] — Broad language overview and quick starts
- [[install/Languages/Java]] — Java/JDK via SDKMAN
- [[install/Languages/Python/Python]] — Python 3 via pyenv
- [[install/Languages/Python/Pipenv]] — Virtual environment and dependency manager
- [[install/Languages/Python/Pytest]] — Python testing framework
- [[install/Languages/Ruby]] — Ruby via RVM
- [[install/Languages/Rust]] — Rust language setup
- [[install/Languages/Go]] — Go language setup
- [[install/Languages/TypeScript]] — TypeScript setup
- [[install/Languages/Julia]] — Julia language setup
- [[install/Languages/Elixir]] — Elixir language setup
- [[install/Languages/Kotlin]] — Kotlin
- [[install/Languages/Flutter]] — Flutter mobile framework
- [[install/Infrastructure/AWS]] — AWS CLI and tools
- [[install/Infrastructure/Cloud]] — Cloud services overview
- [[install/Infrastructure/SOPS]] — Secrets management
- [[install/Infrastructure/Terraform]] — Terraform IaC
- [[install/Databases/Databases]] — Database setup and configuration
- [[install/Databases/Services]] — Microservices and supporting services
- [[install/Databases/Apache]] — Apache server configuration

### Best Practices
- [[best-practices/Web Dev]] — Web development overview
- [[best-practices/APIs]] — API development tools
- [[best-practices/CSS]] — CSS overview and styling tools
- [[best-practices/Concepts]] — Development concepts and best practices
- [[best-practices/Load Testing]] — Load testing tools

## 03 - Apps

- [[Browsers]] — Browser installation
- [[Chats]] — Chat applications
- [[Internet]] — Internet utilities
- [[Multimedia]] — Audio/video tools
- [[PDF]] — PDF tools
- [[Downloaders]] — File download utilities
- [[Calendars]] — Calendar applications
- [[Dashboards]] — Monitoring and dashboards
- [[Collaborations]] — Team collaboration tools
- [[Task Managers]] — Project management (ClickUp, etc.)
- [[Auth]] — Authentication configuration
- [[Encryption]] — Encryption tools
- [[VPN]] — VPN setup
- [[VNC]] — VNC / remote desktop
- [[VM]] — Virtual machines
- [[Synology]] — Synology NAS management tools

## 04 - AI

- [[AI Setup Architecture]] — Layered stack design, tool conflict map, machine-type model selection, and VS Code troubleshooting.
- [[Models]] — Central model reference: IDs for Ollama, OpenRouter, and direct APIs.

### Local Runtimes

- [[Local LLMs]] — Local LLM overview for Ollama, LM Studio, GPT4All, vLLM, and Llama.cpp.
- [[Ollama]] — Local LLM manager for Apple Silicon.
- [[LM Studio]] — GUI for discovering and running local LLMs.
- [[GPT4All]] — Privacy-focused local chatbot app.
- [[vLLM]] — High-throughput local LLM serving engine.
- [[Llama.cpp]] — Apple Silicon-optimized LLaMA inference library.

### Coding Assistants

- [[Coding Assistants]] — Overview of AI coding assistants: Copilot, OpenCode, Aider, Tabby, and more.
- [[Claude Code]] — Anthropic code-focused Claude assistant.
- [[Cline]] — Autonomous AI coding agent for VS Code with MCP and browser support.
- [[Continue]] — Open-source AI code assistant for VS Code and JetBrains.
- [[Google Gemini CLI]] — Google's Gemini AI assistant for command-line.
- [[OpenCode]] — Terminal-based AI coding assistant by Charm.
- [[OpenShell]] — NVIDIA's sandboxed runtime for running AI coding agents safely.
- [[VS Code AI Extensions]] — VS Code extensions for AI coding assistance.

### APIs & Services

- [[OpenRouter]] — Unified API gateway for hundreds of AI models with provider routing and fallbacks.
- [[Perplexity]] — AI search with real-time web grounding and cited answers.

### Frameworks

- [[Frameworks]] — AI frameworks and libraries: Hugging Face, LangChain, LlamaIndex, PyTorch.

### Image Generation

- [[Image Generation]] — Local image generation tools: Automatic1111, ComfyUI, Draw Things.
