{
  imports = [ ../programs/firefox/company-extensions.nix ];

  # The company device uses the original unified database.
  home.sessionVariables.OPENCODE_DB = "opencode.db";
}
