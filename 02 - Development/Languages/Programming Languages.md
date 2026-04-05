---
tags: [languages, overview]
---

# Programming Languages

Practical language options across backend, systems, scripting, and data workflows.

## <img src="https://github.com/python.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Python

[Python](https://www.python.org/) is a versatile general-purpose language popular for automation, backend services, and data/AI work.

```shell
brew install pyenv
```

```shell
pyenv install 3.12.0
pyenv global 3.12.0
```

```shell
python3 -q
```

See more: [[Python]]

## <img src="https://github.com/openjdk.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Java

[Java](https://openjdk.org/) is a mature, strongly typed platform language for enterprise systems and large backend services.

```shell
brew install openjdk
```

```shell
export JAVA_HOME="$(/usr/libexec/java_home)"
```

```shell
jshell
```

See more: [[Java]]

## <img src="https://github.com/JetBrains.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Kotlin

[Kotlin](https://kotlinlang.org/) is a modern JVM language that works well for Android and backend development.

```shell
brew install kotlin
```

No basic configuration required.

```shell
kotlin -version
```

See more: [[Kotlin]]

## <img src="https://github.com/rust-lang.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Rust

[Rust](https://www.rust-lang.org/) is a systems language focused on performance and memory safety.

```shell
brew install rustup-init
```

```shell
rustup-init -y
```

```shell
cargo new hello-rust
cd hello-rust && cargo run
```

See more: [[Rust]]

## <img src="https://github.com/golang.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Go

[Go](https://go.dev/) is a simple compiled language commonly used for cloud services, APIs, and CLIs.

```shell
brew install go
```

```shell
go env -w GOPATH="$HOME/go"
```

```shell
go version
```

See more: [[Go]]

## <img src="https://github.com/microsoft.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> TypeScript

[TypeScript](https://www.typescriptlang.org/) adds static types to JavaScript for safer large-scale application development.

```shell
brew install node
```

```shell
npm install --global typescript
```

```shell
tsc --version
```

See more: [[TypeScript]]

## <img src="https://github.com/mdn.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> JavaScript

[JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript) is the core language of the web and also widely used on servers via Node.js.

```shell
brew install node
```

No basic configuration required.

```shell
node
```

## <img src="https://github.com/php.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> PHP

[PHP](https://www.php.net/) is a pragmatic server-side language widely used for web applications and CMS platforms.

```shell
brew install php
```

No basic configuration required.

```shell
php -v
```

## <img src="https://github.com/JuliaLang.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Julia

[Julia](https://julialang.org/) is a high-performance language designed for scientific computing, numerical analysis, and data work.

```shell
brew install julia
```

No basic configuration required.

```shell
julia
```

See more: [[Julia]]

## <img src="https://github.com/elixir-lang.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Elixir

[Elixir](https://elixir-lang.org/) is a functional language on the Erlang VM for scalable, fault-tolerant distributed systems.

```shell
brew install elixir
```

```shell
mix local.hex --force
```

```shell
iex
```

See more: [[Elixir]]
