# defoogi

A Docker container for building [FujiNet](https://fujinet.online)
software, including firmware, libraries, and applications — as well as
cross-compiling software for a wide range of 8-bit and 16-bit systems.

Unlike many Docker build environments, **defoogi preserves file
ownership and permissions**, so your build artifacts stay usable on
the host system without extra `chown` or permission fixes.

## Docker Hub

[Docker Hub repository →](https://hub.docker.com/repository/docker/fozztexx/defoogi)

---

## Features

- Preconfigured build environment with many classic compilers,
  assemblers, and tools
- Easy prefix-style invocation: just run `defoogi make` instead of
  installing toolchains locally
- Works seamlessly in your existing project directories
- No more "root-owned" build artifacts - ownership is preserved
- Designed for FujiNet but useful for retro-computing and
  cross-compilation in general

### Included toolchains

- [cc65](https://cc65.github.io/) - 6502 C compiler and assembler
- [CMOC](https://perso.b2b2c.ca/~sarrazip/dev/cmoc.html) - C compiler for 6809
- [Open Watcom v2](https://openwatcom.org/) - C/C++ compiler for DOS and other targets
- [z88dk](https://www.z88dk.org/) - Z80 C compiler

(More assemblers, linkers, and disk tools are bundled - see the
*.docker files for details.)

---

## Usage

1. Change into the directory containing the software you want to build
2. Prefix your build commands with `defoogi`. For example:

```bash
defoogi make
```

This runs `make` inside the container but keeps the results on your
host system with the correct permissions.

You can also run individual tools directly:

```bash
defoogi cc65 hello.c
defoogi cmoc program.c
```

---

## GitHub Actions Integration

One of the most exciting workflows we’re experimenting with is
**building software directly in GitHub Actions**.

- Push your changes to GitHub
- The code is compiled automatically using `defoogi` inside a GitHub workflow
- The build artifact is published as a downloadable asset over HTTP
- On your retro battlestation, the [FujiNet](https://fujinet.online)
  can **mount that HTTP asset directly as a disk image**

This means you can:
- Edit and commit your code from any modern machine
- Wait a moment for the CI build to finish
- Boot your retro computer, mount the build directly via FujiNet, and
  run it instantly

**Key benefits:**
- No floppy disk conversions.
- No SneakerNet with SD cards.
- No fumbling with transfer tools.

It’s just **edit → push → boot → run**.

---

## Other Integration

- **VS Code** support is being developed, so you’ll be able to build
    and debug directly within your editor
- Works with shell scripts and CI/CD pipelines - just prefix your
  existing commands
