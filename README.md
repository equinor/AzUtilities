# AzUtilities - The toolbox for all AzActions
Utilities for the AzActions

[![Action-Test](https://github.com/equinor/AzUtilities/actions/workflows/Action-Test.yml/badge.svg)](https://github.com/equinor/AzUtilities/actions/workflows/Action-Test.yml)

[![Linter](https://github.com/equinor/AzUtilities/workflows/Linter/badge.svg)](https://github.com/equinor/AzUtilities/actions/workflows/Linter.yml)

[![GitHub](https://img.shields.io/github/license/equinor/AzUtilities)](LICENSE)

This action holds all the utility modules for all other AzAction GitHub actions.

It causes the worker to download the repo, and installs all the modules to the runners.

## Why use this module?

This action was created to create a central place to maintain the utilities used for all AzActions.
Using another action that makes sure the runner has the code + have the functions within the powershell
module load automatically was the easiest way out.

Alternatives that have been identified, but not yet discussed in the team:

- Publish modules to PowerShell Gallery
- Publish modules as GitHub packages


## Inputs

N/A

## Outputs

N/A

## Environment variables

N/A

## Usage

```yaml
name: Test-Workflow

on: [push]

jobs:
  AzConnect:
    runs-on: ubuntu-latest
    steps:

      - name: Load AzUtilities
        uses: equinor/AzUtilities@v1

```

## Dependencies

N/A

## Contributing

This project welcomes contributions and suggestions. Please review [How to contribute](https://github.com/equinor/AzActions#how-to-contibute) on our [AzActions](https://github.com/equinor/AzActions) page.
