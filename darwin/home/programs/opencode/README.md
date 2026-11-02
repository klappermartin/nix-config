# OpenCode

Home Manager enables the OpenCode package from nixpkgs without configuring a
provider, authentication plugin, MCP server, agent, or skill. Codex and Pi remain
separate packages in the shared developer package list.

OpenCode can still discover user and project configuration, and saved auth data
is outside this module. Review project configuration and use only company-
approved provider credentials before sending company data to a model.
