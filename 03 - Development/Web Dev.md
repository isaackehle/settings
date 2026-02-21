---
tags: [development]
---

# <img src="https://github.com/w3c.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Web Development

Tools and frameworks for web development. See also: [[Volta]] for Node.js management.

## Prerequisites

- [[Xcode]] — required for native build tools
- [[Git]] — version control
- [[Volta]] — Node.js version management

## Infrastructure Tools

- [[SOPS]] — secrets management
- [[Gradle]] — JVM build tool
- [[Terraform]] — infrastructure as code

## Vite

[Vite](https://vite.dev/) is a modern frontend build tool and dev server with very fast startup.

```shell
npm create vite@latest
```

## Just

[just](https://just.systems) is a command runner (simpler alternative to Make).

```shell
brew install just
```

## Feature Flags

- [LaunchDarkly](https://launchdarkly.com)

## NPM Global Packages

List all globally installed npm packages:

```shell
npm ls -g --depth 0
```

Common globals:

```shell
npm install -g npm-check-updates
npm install -g typescript
npm install -g eslint
npm install -g webpack webpack-dev-server
npm install -g rimraf
```

## Angular

```shell
npm install -g @angular/cli
```

## Configuration

No basic configuration required.

## Start / Usage

```shell
npm create vite@latest
```

## References

- [NativeScript documentation](https://docs.nativescript.org/)
- [Frontend tooling with Vite](https://vite.dev/guide/)
