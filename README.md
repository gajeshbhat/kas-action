# Kas Action

[![CI Checks](https://github.com/gajeshbhat/kas-action/actions/workflows/ci.yml/badge.svg)](https://github.com/gajeshbhat/kas-action/actions/workflows/ci.yml) [![Integration Tests](https://github.com/gajeshbhat/kas-action/actions/workflows/tests.yml/badge.svg)](https://github.com/gajeshbhat/kas-action/actions/workflows/tests.yml)

A thin wrapper around [Siemens kas](https://kas.readthedocs.io/) to build Yocto/OpenEmbedded projects with optimized caching and CI integration.

## Quick Start

### Simple Build

```yaml
name: Yocto Build
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest  # or self-hosted for better performance and larger builds
    steps:
      - uses: actions/checkout@v4

      - name: Build with kas
        uses: gajesh/kas-action@v1
        with:
          kas_file: kas.yml
```

### With Caching

```yaml
      - name: Cache downloads and sstate
        uses: actions/cache@v4
        with:
          path: |
            dl_cache
            sstate_cache
          key: yocto-cache-${{ hashFiles('kas/*.yml') }}
          restore-keys: yocto-cache-

      - name: Build with kas
        uses: gajesh/kas-action@v1
        with:
          kas_file: kas.yml
          dl_dir: dl_cache
          sstate_dir: sstate_cache
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `kas_file` | Space-separated kas YAML files | Yes | - |
| `kas_tag` | Kas container tag from ghcr.io/siemens/kas/kas | No | `latest` |
| `kas_cmd` | Kas command (build, shell, checkout, etc.) | No | `build` |
| `kas_args` | Additional arguments for kas command | No | `""` |
| `bitbake_args` | Arguments passed to bitbake | No | `""` |
| `dl_dir` | Download cache directory | No | `dl_cache` |
| `sstate_dir` | Shared state cache directory | No | `sstate_cache` |
| `parallelism` | Build parallelism (`auto`, number, or `BB=4,MAKE=8`) | No | `auto` |
| `accept_licenses` | Space-separated licenses to accept | No | `""` |

## Outputs

| Output | Description |
|--------|-------------|
| `image_dir` | Path to built images directory |
| `build_dir` | Path to build directory |

## Examples
## CI and Tests

- CI checks: Lints shell scripts and Dockerfile (see .github/workflows/ci.yml)
- Integration tests: Smoke tests using `kas dump` on a minimal config to keep runs fast (see .github/workflows/tests.yml)
- Minimal Yocto image build: Manual, requires self-hosted runner (see .github/workflows/build-minimal.yml)



### Multi-Machine Build (via separate kas files)

```yaml
strategy:
  matrix:
    kas_file: [kas/qemux86-64.yml, kas/raspberrypi4-64.yml]

steps:
  - uses: gajesh/kas-action@v1
    with:
      kas_file: ${{ matrix.kas_file }}
```

### Private Repositories

```yaml
- name: Setup SSH for private repos
  uses: webfactory/ssh-agent@v0.8.0
  with:
    ssh-private-key: ${{ secrets.DEPLOY_KEY }}

- name: Add known hosts
  run: ssh-keyscan github.com >> ~/.ssh/known_hosts

- uses: gajesh/kas-action@v1
  with:
    kas_file: kas.yml
    accept_licenses: "commercial proprietary"
```

### SDK Generation

```yaml
- uses: gajesh/kas-action@v1
  with:
    kas_file: kas.yml
    bitbake_args: "-c populate_sdk core-image-minimal"
```

## Runner Requirements

### GitHub-hosted Runners
- Limitations: ~7GB RAM, ~14GB disk space
- Suitable for: Small builds and images similar to core-image-minimal

### Self-hosted Runners (Recommended)
- Minimum: 16GB RAM, 100GB NVMe SSD, 8+ CPU cores
- Optimal: 32GB+ RAM, 500GB+ NVMe SSD, 16+ CPU cores
- Best for: Production builds, full distributions

## Caching Strategy

### Recommended Approach
```yaml
- uses: actions/cache@v4
  with:
    path: |
      dl_cache      # ~1-5GB, highly reusable
      sstate_cache  # ~10-50GB, valuable for incremental builds
    key: yocto-${{ hashFiles('kas/*.yml') }}-${{ github.run_number }}
    restore-keys: |
      yocto-${{ hashFiles('kas/*.yml') }}-
      yocto-
```

### Cache Types
- **DL_DIR** (`dl_cache`): Source downloads - always cache this
- **SSTATE_DIR** (`sstate_cache`): Build state - cache if disk allows
- **TMPDIR**: Build workspace (~50-200GB) - usually too large to cache

## Troubleshooting

### Common Issues

**Build fails with "No space left on device"**
```bash
# Check available space
df -h
# Use self-hosted runner or clean up
```

**Private repository access denied**
```yaml
# Ensure SSH key is properly configured
- uses: webfactory/ssh-agent@v0.8.0
  with:
    ssh-private-key: ${{ secrets.DEPLOY_KEY }}
```

**Build is very slow**
```yaml
# Increase parallelism
- uses: gajesh/kas-action@v1
  with:
    parallelism: "16"  # or "BB=8,MAKE=16"
```

## Advanced Usage

### Custom Kas Commands

```yaml
# Checkout repositories only
- uses: gajesh/kas-action@v1
  with:
    kas_file: kas.yml
    kas_cmd: checkout

# Interactive shell (for debugging)
- uses: gajesh/kas-action@v1
  with:
    kas_file: kas.yml
    kas_cmd: shell
    kas_args: "--keep-config-unchanged"

# Dump configuration
- uses: gajesh/kas-action@v1
  with:
    kas_file: kas.yml
    kas_cmd: dump
```


## License

[MIT](LICENSE) - same as kas project

## Support

- Documentation: https://kas.readthedocs.io/
- Report issues: https://github.com/gajesh/kas-action/issues
