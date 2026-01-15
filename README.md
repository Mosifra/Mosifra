# Project Setup

This project can be run using either a **Nix Flake** or with packages installed directly on your machine.

## Using Nix Flake

The flake handles running all the necessary commands automatically through a development shell.  
To use it, you only need **Nix** installed with the experimental features `nix-command` and `flakes` enabled.
Enter the development shell by executing:
```bash
nix develop
```

## Running Locally Without Flake

If you prefer to run the project using the packages already available on your system, you will need **Docker** installed.  

Start the services with:

```bash
docker compose up [options]
```
