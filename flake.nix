{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      shellHook = ''
        export LIBGL_ALWAYS_SOFTWARE=1
      '';

      packages = with pkgs; [
        zls
        zig
        glfw
        libGL
      ];
    };
  };
}
