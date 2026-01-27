{
  description = "Dev environment with Podman and Neovide";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };
  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
  in {
    devShells."x86_64-linux".default = pkgs.mkShell {
      buildInputs = with pkgs; [
        podman
        podman-compose
        cargo
        rustc
        rustfmt
        clippy
        rust-analyzer
        sqls
        bun
      ];
      env.RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
      shellHook = ''
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        RED='\033[0;31m'
        NC='\033[0m'

        echo -e "''${GREEN}=== Environnement de développement (Podman) ===$NC"

        export DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock"

        mkdir -p $HOME/.config/containers
        mkdir -p /run/user/$UID/podman

        cat > $HOME/.config/containers/registries.conf <<EOF
        unqualified-search-registries = ["docker.io"]

        [[registry]]
        prefix = "docker.io"
        location = "docker.io"

        [[registry]]
        prefix = "registry.hub.docker.com"
        location = "registry.hub.docker.com"
        EOF

        cat > $HOME/.config/containers/policy.json <<EOF
        {
          "default": [
            {
              "type": "insecureAcceptAnything"
            }
          ],
          "transports": {
            "docker-daemon": {
              "": [
                {
                  "type": "insecureAcceptAnything"
                }
              ]
            }
          }
        }
        EOF

        echo -e "''${GREEN}Configuration Podman créée$NC"

        if ! systemctl --user is-active podman.socket > /dev/null 2>&1; then
          echo -e "''${YELLOW}Démarrage du socket Podman...$NC"
          systemctl --user start podman.socket

          echo "Attente du démarrage de Podman..."
          for i in {1..30}; do
            if podman info > /dev/null 2>&1; then
              echo -e "''${GREEN}Podman est prêt!$NC"
              break
            fi
            sleep 1
          done
        else
          echo -e "''${GREEN}Podman socket déjà en cours d'exécution.$NC"
        fi

        alias docker=podman
        alias docker-compose=podman-compose

        if [ -f "docker-compose.yml" ] || [ -f "compose.yaml" ]; then
          echo -e "''${GREEN}Lancement de podman-compose up --build...$NC"
          podman-compose up --build -d
        else
          echo -e "''${YELLOW}Aucun fichier docker-compose.yml trouvé.$NC"
        fi

        export PATH=${pkgs.bun}/bin:$PATH
        if [ -f bun.lockb ]; then
          echo "Installation des dépendances avec Bun…"
          bun install
        fi

        echo -e "''${GREEN}Lancement de Neovide...$NC"
        neovide &

        echo -e "''${GREEN}Environnement prêt!$NC"

        sleep 3

        echo -e "''${GREEN}Pour lancer les logs : podman-compose logs -f <nom-conteneur-1> <nom-conteneur-2>!$NC"
      '';
    };
  };
}
