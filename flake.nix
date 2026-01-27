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
        tmux
      ];
      env.RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
      shellHook = ''
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        RED='\033[0;31m'
        NC='\033[0m'

        echo -e "''${GREEN}=== Environnement de développement (Podman) ===$NC"

        # Config Podman
        mkdir -p $HOME/.config/containers
        cat > $HOME/.config/containers/registries.conf <<EOF
        unqualified-search-registries = ["docker.io"]
        [[registry]]
        prefix = "docker.io"
        location = "docker.io"
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

        alias docker=podman
        alias docker-compose=podman-compose

        # Lancer podman-compose
        if [ -f "docker-compose.yml" ] || [ -f "compose.yaml" ]; then
          echo -e "''${GREEN}Lancement de podman-compose up --build...$NC"
          podman-compose up --build -d
        fi

        export PATH=${pkgs.bun}/bin:$PATH
        if [ -f bun.lockb ]; then
          echo "💨 Installation des dépendances avec Bun…"
          bun install
        fi

        SESSION_NAME="podman-dev"

        if ! tmux has-session -t $SESSION_NAME 2>/dev/null; then
          # Window 0: Neovide
          tmux new-session -d -s $SESSION_NAME -n "editor"
          tmux send-keys -t $SESSION_NAME:0 "neovide" C-m

          # Window 1: Shell principal + logs
          tmux new-window -t $SESSION_NAME:1 -n "dev"
          tmux send-keys -t $SESSION_NAME:1 "echo 'Shell principal. Commandes utiles :'" C-m
          tmux send-keys -t $SESSION_NAME:1 "echo '  podman-compose ps              - État des conteneurs'" C-m
          tmux send-keys -t $SESSION_NAME:1 "echo '  podman-compose logs -f api     - Logs API'" C-m
          tmux send-keys -t $SESSION_NAME:1 "echo '  podman-compose logs -f front   - Logs front'" C-m
          tmux send-keys -t $SESSION_NAME:1 "echo '  podman-compose restart api     - Redémarrer un service'" C-m

          # Window 2: Logs
          tmux new-window -t $SESSION_NAME:2 -n "logs"
          tmux send-keys -t $SESSION_NAME:2 "sleep 2 && podman-compose logs -f" C-m

          tmux select-window -t $SESSION_NAME:1
        fi

        echo -e "''${GREEN}Environnement prêt!$NC"
        tmux attach-session -t $SESSION_NAME
      '';
    };
  };
}
