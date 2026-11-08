{
  imports = [ ../programs/firefox/personal-extensions.nix ];

  # Keep the M2's existing OpenCode V2 session and credential database.
  home.sessionVariables.OPENCODE_DB = "opencode-v2.db";
}
