sanitize_version() {
  echo "$1" | tr '/' '-' | tr -cs 'A-Za-z0-9._+-' '-' | sed -E 's/-+/-/g; s/^-|-$//g'
}

derive_slug() {
  basename "$1" .git
}
