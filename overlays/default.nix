self: super:
let
  overlays = [
    # package overlay must be applied before emacs overlay
    # (import ./package.nix)
    (import ./openshift.nix)
  ];
in
super.lib.composeManyExtensions overlays self super
