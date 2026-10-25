-- The generated entry point supplies the exact, precompiled Nix module path.
return function(module_path)
  package.cpath = package.cpath .. ";" .. module_path
end
