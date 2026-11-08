{
  homebrew.casks = [
    # This cask does not publish a sha256.
    {
      name = "nvidia-geforce-now";
      greedy = true;
      args.require_sha = false;
    }
  ];
}
