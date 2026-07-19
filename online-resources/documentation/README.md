# Plant-it Enhanced documentation

This directory contains the maintained documentation for
[`t0n003c/plant-it-enhanced`](https://github.com/t0n003c/plant-it-enhanced). Product and deployment
changes should update these pages in the same pull request as the code.

## Preview locally

Python 3 is required. From this directory:

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
mike serve
```

Open the local URL printed by Mike. Check both desktop and narrow mobile layouts, internal links,
code blocks, and the light and dark themes before publishing.

## Publish

Publishing is for repository maintainers:

```bash
mike deploy -b static-doc --alias-type redirect <version> latest
```

Replace `<version>` with the application documentation version, such as `0.16.3`. Do not publish
documentation for a release until its container image is available from GHCR.
