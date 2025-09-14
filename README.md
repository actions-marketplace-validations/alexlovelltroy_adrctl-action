# ADR Index Generator

A GitHub Action that generates or updates the index.md file for Architecture Decision Records (ADRs) using [adrctl](https://github.com/alexlovelltroy/adrctl).

## Usage

### Basic Usage

```yaml
- name: Generate ADR Index
  uses: alexlovelltroy/adrctl-action@v1
```

### With Custom Directory

```yaml
- name: Generate ADR Index
  uses: alexlovelltroy/adrctl-action@v1
  with:
    directory: 'docs/decisions'
```

### With Project Information

```yaml
- name: Generate ADR Index
  uses: alexlovelltroy/adrctl-action@v1
  with:
    project-name: 'My Project'
    project-url: 'https://github.com/myorg/myproject'
```

### Full Example Workflow

```yaml
name: Update ADR Index

on:
  push:
    paths:
      - 'ADRs/**.md'
      - '.github/workflows/adr-index.yml'
  pull_request:
    paths:
      - 'ADRs/**.md'

jobs:
  update-index:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Generate ADR Index
        uses: alexlovelltroy/adrctl-action@v1
        with:
          directory: 'ADRs'
          project-name: '${{ github.event.repository.name }}'
          project-url: '${{ github.event.repository.html_url }}'

      - name: Commit changes
        run: |
          if [[ -n "$(git status --porcelain)" ]]; then
            git config user.name github-actions
            git config user.email github-actions@github.com
            git add ADRs/index.md
            git commit -m "chore(adr): update index"
            git push
          fi
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `directory` | ADR directory path | No | `ADRs` |
| `out` | Output path for index file | No | `<directory>/index.md` |
| `project-name` | Project name to display in index header | No | |
| `project-url` | Project URL to link in index header | No | |

## Outputs

| Output | Description |
|--------|-------------|
| `index-path` | Path to the generated index file |

## Requirements

- ADR files must follow the naming convention: `NNNN-kebab-title.md` (e.g., `0001-adopt-microservices.md`)
- ADR files should include structured frontmatter or recognizable status markers
- Works with MADR and Nygard template formats

## About ADRs

Architecture Decision Records (ADRs) are a way to document important architectural decisions made during a project. This action helps maintain an up-to-date index of all ADRs in your repository.

For more information about the underlying tool, see [adrctl](https://github.com/alexlovelltroy/adrctl).

## License

MIT