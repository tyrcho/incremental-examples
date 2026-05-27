# 01 — Setup and Build

## Directory layout

```
incremental-examples/odin/
├── main.odin
└── README.md
```

Keep the project flat at the language root. No `src/`, no subpackages — sibling C++ uses the same shape, and Rust/Crystal/Nim's `src/` subdir is forced by their toolchain, not by preference. Odin's `odin build .` compiles every `.odin` file in the current directory as one package; with a single source file, the layout is just two files.

## Install Odin (macOS, this machine)

Odin is not currently installed (`which odin` returned non-zero in pre-flight). Use Homebrew:

```bash
brew install odin
```

This installs the `odin` binary and its `vendor/` collection under Homebrew's prefix (e.g. `/opt/homebrew/Cellar/odin/<version>/libexec/`). The Homebrew formula sets `ODIN_ROOT` correctly so that the `vendor:` import path resolves without manual environment setup.

Verify with:

```bash
odin version
odin report   # shows the resolved ODIN_ROOT and vendor path
```

If the user prefers an official build, the `odin-lang/Odin` GitHub releases page ships macOS tarballs. Extract somewhere stable and either symlink `odin` into `PATH` or export `ODIN_ROOT` to the extracted directory. Homebrew is simpler on this machine; document only Homebrew in the deliverable's `README.md` to keep it short.

## Why no separate raylib install

`vendor:raylib` is part of the Odin distribution. The package bundles:

- `vendor/raylib/raylib.odin` — the binding (function decls with `foreign` blocks).
- `vendor/raylib/macos/libraylib.a` and `vendor/raylib/macos-arm64/libraylib.a` — prebuilt static libraries.
- Equivalent `vendor/raylib/linux/` and `vendor/raylib/windows/` directories.

When the compiler resolves `import rl "vendor:raylib"`, it links the matching static `.a` for the host triple automatically. No `brew install raylib`, no `pkg-config`, no link flags in a manifest. This is the single largest reason the Odin implementation is shorter at the build-system layer than the C++ or Crystal variants.

If `import rl "vendor:raylib"` fails to resolve at build time, the cause is almost always a missing or wrong `ODIN_ROOT`. Confirm with `odin report` that it points at the directory containing `vendor/`.

## Build and run commands

Per spec §10, the canonical invocation is `odin run . -o:speed`:

```bash
cd incremental-examples/odin
odin run . -o:speed
```

`odin run` compiles into a temporary executable and executes it in one step — fine for development. For a persistent release binary alongside the source:

```bash
odin build . -o:speed -out:idle_clicker
./idle_clicker
```

Optimization levels: `-o:none`, `-o:minimal`, `-o:size`, `-o:speed`, `-o:aggressive`. Spec §11 requires a release-build binary; `-o:speed` is the right pick — it matches `cargo --release` / `cmake -DCMAKE_BUILD_TYPE=Release` / `shards build --release` in spirit.

For dev iteration, `odin run .` (no flag) defaults to `-o:minimal` and compiles fast. Switch to `-o:speed` for the final acceptance pass.

## README contents (for the deliverable, not this plan)

Single short file. Required per spec §10:

- One-paragraph description.
- Build command (`odin build . -o:speed -out:idle_clicker`).
- Run command (`./idle_clicker`, or `odin run . -o:speed` to do both in one step).
- Controls: "Left-click the green square to earn currency; left-click an upgrade to buy it."

No screenshots, no design notes, no roadmap. Mention that no separate raylib install is needed — readers coming from the C++ or Crystal sibling will expect that step and benefit from one sentence confirming it isn't there.
