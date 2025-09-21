# Kas Action

[![CI](https://github.com/gajeshbhat/kas-action/actions/workflows/ci.yml/badge.svg)](https://github.com/gajeshbhat/kas-action/actions/workflows/ci.yml)

Build Yocto/OpenEmbedded projects using [Siemens kas](https://kas.readthedocs.io/) with optimized caching and CI integration.

## Features

- **Zero-config builds** - Works out-of-the-box with sensible defaults
- **Intelligent caching** - Automatic DL_DIR and SSTATE_DIR caching
- **Optimized parallelism** - Auto-detects CPU cores or custom configuration
- **Private repository support** - SSH key integration for private layers
- **Full kas compatibility** - 100% passthrough to kas commands
- **Flexible container versions** - Pin kas versions or use latest

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
| `kas_file` | Space-separated kas YAML files | ✅ | - |
| `kas_tag` | Kas container tag from ghcr.io/siemens/kas/kas | ❌ | `latest` |
| `kas_cmd` | Kas command (build, shell, checkout, etc.) | ❌ | `build` |
| `kas_args` | Additional arguments for kas command | ❌ | `""` |
| `bitbake_args` | Arguments passed to bitbake | ❌ | `""` |
| `dl_dir` | Download cache directory | ❌ | `dl_cache` |
| `sstate_dir` | Shared state cache directory | ❌ | `sstate_cache` |
| `parallelism` | Build parallelism (`auto`, number, or `BB=4,MAKE=8`) | ❌ | `auto` |
| `accept_licenses` | Space-separated licenses to accept | ❌ | `""` |
| `extra_env` | Additional environment variables (multiline) | ❌ | `""` |

## Outputs

| Output | Description |
|--------|-------------|
| `image_dir` | Path to built images directory |
| `build_dir` | Path to build directory |

## Examples

### Multi-Machine Build

```yaml
strategy:
  matrix:
    machine: [qemux86-64, raspberrypi4-64]

steps:
  - uses: gajesh/kas-action@v1
    with:
      kas_file: kas/base.yml kas/ci-overlay.yml
      extra_env: |
        MACHINE=${{ matrix.machine }}
        BUILD_ID=${{ github.run_number }}
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
- ⚠️ **Limited resources**: 7GB RAM, 14GB disk space
- ✅ **Good for**: Small builds and images similar to core-image-minimal

### Self-hosted Runners (Recommended)
- **Minimum**: 16GB RAM, 100GB NVMe SSD, 8+ CPU cores
- **Optimal**: 32GB+ RAM, 500GB+ NVMe SSD, 16+ CPU cores
- **Best for**: Production builds, full distributions

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

### Environment Variables

```yaml
- uses: gajesh/kas-action@v1
  with:
    kas_file: kas.yml
    extra_env: |
      # Build optimization
      BB_HASHSERVE=auto
      BB_SIGNATURE_HANDLER=OEEquivHash

      # Custom mirrors
      SSTATE_MIRRORS=file://.*/.*-native.* http://sstate.company.com/PATH
      PREMIRRORS=git://.*/.* http://git-cache.company.com/

      # Build metadata
      BUILD_ID=${{ github.run_number }}
      GIT_COMMIT=${{ github.sha }}
```

## License

[MIT](LICENSE) - same as kas project

## Support

- 📖 [kas Documentation](https://kas.readthedocs.io/)
- 🐛 [Report Issues](https://github.com/gajesh/kas-action/issues)
