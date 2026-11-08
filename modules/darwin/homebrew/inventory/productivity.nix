{
  homebrew.casks = [
    {
      name = "balenaetcher";
      greedy = true;
    }
    {
      name = "linear";
      greedy = true;
    }
    # These font casks do not publish a sha256.
    {
      name = "font-sf-mono";
      greedy = true;
      args.require_sha = false;
    }
    {
      name = "font-sf-pro";
      greedy = true;
      args.require_sha = false;
    }
  ];
}
