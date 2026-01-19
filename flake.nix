{
  description = "Dev environment with Docker and Neovide";

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
        docker
        docker-compose
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
        # Couleurs pour les messages
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        RED='\033[0;31m'
        NC='\033[0m' # No Color

        echo -e "''${GREEN}=== Environnement de développement ===$NC"

        # Vérifier si dockerd est en cours d'exécution
        if ! sudo pgrep -x dockerd > /dev/null; then
          echo -e "''${YELLOW}Docker daemon n'est pas en cours d'exécution.$NC"
          echo "Démarrage de dockerd (nécessite sudo)..."
          sudo dockerd &
          DOCKERD_PID=$!

          # Attendre que Docker soit prêt
          echo "Attente du démarrage de Docker..."
          for i in {1..30}; do
            if sudo docker info > /dev/null 2>&1; then
              echo -e "''${GREEN}Docker est prêt!$NC"
              break
            fi
            sleep 1
          done
        else
          echo -e "''${GREEN}Docker daemon déjà en cours d'exécution.$NC"
        fi

        # Changer les permissions du socket Docker
        if [ -S /var/run/docker.sock ]; then
          echo "Configuration des permissions Docker..."
          sudo chmod 666 /var/run/docker.sock
        fi

        # Lancer docker compose
        if [ -f "docker-compose.yml" ] || [ -f "compose.yaml" ]; then
          echo -e "''${GREEN}Lancement de docker compose up --build...$NC"
          docker compose up --build -d
        else
          echo -e "''${YELLOW}Aucun fichier docker-compose.yml trouvé.$NC"
        fi


        export PATH=${pkgs.bun}/bin:$PATH

        if [ -f bun.lockb ]; then
          echo "💨 Installation des dépendances avec Bun…"
          bun install
        fi

        # Lancer Neovide
        echo -e "''${GREEN}Lancement de Neovide...$NC"
        neovide &

        echo -e "''${GREEN}Environnement prêt!$NC"
        echo -e "''${GREEN}Lancement des logs...!$NC"
        docker compose logs -f api front
      '';
    };
  };
}
