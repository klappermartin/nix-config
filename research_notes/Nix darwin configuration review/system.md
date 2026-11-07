# Flake and Darwin system architecture review

## 1. Does the current system evaluate, and is its dependency architecture sound?

### Takeaway

The present locked `mb-pro` configuration evaluates successfully, including its complete system derivation path, with **zero Darwin warnings, zero Home Manager warnings, and zero failed assertions**. Its small, explicit single-host module graph is appropriate; the clearest improvements concern operational documentation and package-policy boundaries, not adoption of a larger configuration framework.

### Cited Findings

- **Architecture:** `flake.nix:4–36` defines eight direct inputs; `:47–64` supplies one username (`martin`) and one Darwin configuration (`mb-pro`) with six explicit module entries. Four local system modules own system settings, overlays, Homebrew, and Home Manager integration. Home Manager's root imports packages/programs/services separately. This is readily traceable composition rather than incidental fragmentation. [Flake](../../flake.nix#L4), [module wiring](../../flake.nix#L47), [home root](../../darwin/home/home.nix#L1).
- **One main package universe:** Darwin, Home Manager, and NUR all follow the root nixpkgs input (`flake.nix:8–21`); Home Manager uses `useGlobalPkgs = true` and `useUserPackages = true` (`darwin/system/home-manager.nix:13–15`). Thus the system's overlays and `allowUnfree` policy apply to Home Manager too. There is no independently imported default Home Manager nixpkgs universe. [Inputs](../../flake.nix#L8), [HM wiring](../../darwin/system/home-manager.nix#L13), [package policy](../../darwin/system/configuration.nix#L31).
- **Deliberate exception:** a second nixpkgs input, `release-25.11`, supplies only the overlaid `oxker`; overlay selects the current host platform rather than hard-coding an architecture. Comment records macOS snapshot-test failures and upstream issue `mrjackwills/oxker#73`. Its consumer is the Home Manager wrapper's `${pkgs.oxker}/bin/oxker`. This is a narrow compatibility pin, not accidental system-wide stable/unstable mixing. [Input](../../flake.nix#L6), [overlay](../../darwin/system/overlays.nix#L3), [consumer](../../darwin/home/programs/oxker.nix#L7).
- **NUR is actually consumed:** Firefox extensions use `pkgs.nur.repos.rycee.firefox-addons`, so the NUR input/overlay is justified. NUR's transitive flake-parts library follows NUR's followed root nixpkgs. [Firefox](../../darwin/home/programs/firefox.nix#L223), [overlay](../../darwin/system/overlays.nix#L4), [lock](../../flake.lock#L41).
- **Lock-file freshness:** parsed `lastModified` timestamps (UTC, source timestamps, not dates the user updated the lock) are nixpkgs 2026-10-20, Darwin 2026-10-23, HM/NUR/core/cask 2026-10-24, nix-homebrew 2026-09-20, brew 2026-09-17. Stable oxker source is 2026-07-06. Exact revisions and nar hashes are committed. The comparatively old stable pin deserves periodic retesting, but age alone is not evidence of a broken or vulnerable package. NUR's transitive flake-parts timestamp is 2024-12-04; no incompatibility appeared in evaluation. [Lock](../../flake.lock#L3), [stable source](../../flake.lock#L148), [transitive flake-parts](../../flake.lock#L41).
- **Darwin identity is explicit and internally consistent:** host platform is `aarch64-darwin`, primary user comes from `username`, and `/Users/${username}` feeds Home Manager. Evaluated home directory is `/Users/martin`. A NixOS-style hardware-configuration module is not an expected missing component here. [Platform](../../darwin/system/configuration.nix#L31), [identity](../../darwin/system/configuration.nix#L206), [HM](../../darwin/system/home-manager.nix#L15), [validation transcript below](#validation-transcript).
- **State compatibility is intentionally separate from dependency freshness:** Darwin `system.stateVersion = 5`; HM `home.stateVersion = "25.05"`. HM explicitly disables symlink apps and enables copied apps, despite the older stateVersion; the locked HM module's copied-app default only becomes true at 25.11. Keeping these version values is not evidence that the flake dependencies are outdated. [Darwin](../../darwin/system/configuration.nix#L208), [HM](../../darwin/home/home.nix#L8), [locked HM copy-app module](https://github.com/nix-community/home-manager/blob/2cd3234928f60bbff695a7ee56115ef7799c47cd/modules/targets/darwin/copyapps.nix#L12-L28).
- **Verification infrastructure is minimal:** outputs expose a Darwin formatter and Darwin configuration, with no `checks` output or standalone `homeConfigurations` output. The absence of standalone Home Manager is consistent with integrated Darwin ownership, not a fault. A system-specific eval command is useful because a generic flake check is not a substitute for explicitly forcing this nonstandard Darwin output's system derivation. [Complete output definitions](../../flake.nix#L38).

#### Validation transcript

Performed 2026-10-25 in `/Users/martin/nix`. Read-only evaluation only; no build, activation, lock update, or repository configuration edit. Processes ran sequentially, never concurrently. Python imposed a 120-second subprocess deadline and process-group termination on timeout. `--offline` avoids network refresh, `--no-write-lock-file` prevents lock changes, and disabling import-from-derivation prevents hidden IFD builds.

The final invocation was:

```sh
nix eval --offline --no-write-lock-file \
  --option allow-import-from-derivation false --json \
  .#darwinConfigurations.mb-pro --apply '
  s: let c=s.config; h=c.home-manager.users.martin; in {
    systemDrv=s.system.drvPath;
    warnings=c.warnings;
    homeWarnings=h.warnings;
    failedAssertions=map (a: a.message)
      (builtins.filter (a: !a.assertion) c.assertions);
    homeFailedAssertions=map (a: a.message)
      (builtins.filter (a: !a.assertion) h.assertions);
    hostPlatform=c.nixpkgs.hostPlatform.system;
    stateVersion=c.system.stateVersion;
    homeStateVersion=h.home.stateVersion;
    homeDirectory=h.home.homeDirectory;
    appDirectory=h.targets.darwin.copyApps.directory;
    dockApps=c.system.defaults.dock.persistent-apps;
    homePackages=map (p: p.name) h.home.packages;
    systemPackages=map (p: p.name) c.environment.systemPackages;
    brewfile=c.homebrew.brewfile;
    homebrewPrefix=c.homebrew.prefix;
    moduleSources={
      darwin=s.options.homebrew.enable.declarations;
      homeManager=s.options.home-manager.users.declarations;
      nixHomebrew=s.options.nix-homebrew.enable.declarations;
    };
  }'
```

Result: **exit 0; 6.69 seconds; stderr empty**. Key output:

```json
{
  "systemDrv": "/nix/store/gk5klingvfiaqg2hgbazprsghxshk8kx-darwin-system-26.11.bb0b90d.drv",
  "warnings": [],
  "homeWarnings": [],
  "failedAssertions": [],
  "homeFailedAssertions": [],
  "hostPlatform": "aarch64-darwin",
  "stateVersion": 5,
  "homeStateVersion": "25.05",
  "homeDirectory": "/Users/martin",
  "appDirectory": "Applications/Home Manager Apps",
  "homebrewPrefix": "/opt/homebrew"
}
```

Important audit detail: the **first probe** mistakenly requested removed option `c.homebrew.brewPrefix`. It exited 1 in 2.17 seconds with the explicit message that `homebrew.brewPrefix` was removed in favor of `homebrew.prefix`, with the latter naming the prefix rather than its `bin` directory. This was **an error in the review expression, not in the repository**, which does not set the removed option. Correcting just the probe yielded the clean result above. Do not report this as a configuration error.

The evaluated Brewfile contains two taps and exactly seven casks: balenaetcher, karabiner-elements, linear, font-sf-mono, font-sf-pro, nvidia-geforce-now, spotify. All are `greedy: true`; the final four override `require_sha: false`. `trusted: true` is supplied by the locked nix-darwin default and is normal for these official-tap casks, not an unexpected local policy bypass. Evaluated system packages include devenv 2.4.0, nh 4.4.2, Nix 2.34.9 and the configured system services. Evaluated home packages include the package list and program/service-added packages, confirming module composition. [Homebrew definitions](../../darwin/system/homebrew.nix#L28), [locked upstream default](https://github.com/nix-darwin/nix-darwin/blob/bb0b90dbd54e207100de72b5dcbe3188c98a4b69/modules/homebrew.nix#L616-L634).

The option declaration paths returned by evaluation allowed inspection of the **exact locked upstream sources**, rather than assuming current online documentation matches this system:

- Darwin: `/nix/store/3a3iv3qwr8g2b66ph7j8rzj6id642alj-source`.
- HM: `/nix/store/0ql2valpm8n9qqavz2bmkg9f4q8s5f59-source`.
- nix-homebrew: `/nix/store/v7rwj6swlqpr9jk6lc93jm22w5n1wb5d-source`.

### Inferences

- Overall architecture is sound for one Apple Silicon workstation. `specialArgs` / `extraSpecialArgs` are modest and purposeful; the explicit imports do not warrant a host factory, flake-parts migration, automatic directory import machinery, or role taxonomy merely for style. This judgment follows the small output graph and shared package policy above.
- Stable oxker's extra nixpkgs closure/evaluation cost is a reasonable tradeoff for an isolated executable workaround. Do not claim ABI breakage just because its dependencies come from another nixpkgs revision. Consider recording a retest condition and exact known-good version when the pin is next touched.
- A practical lightweight validation command for future changes is `nix eval --no-write-lock-file --raw .#darwinConfigurations.mb-pro.system.drvPath`, with appropriate timeout/resource limits. A full build adds build-time validation, but was expressly out of scope here.

### Gaps

- Evaluation establishes module-option compatibility and derivation construction, not successful realization of all packages, Homebrew downloads, successful activation, App Management permission, or GUI behavior. None of those were exercised.
- No claim that the prior crash was caused by this configuration: this review collected no crash-cause evidence. The successful bounded eval does not diagnose that restart.
- The stable oxker upstream issue and PrismLauncher upstream fix were not independently revalidated in this assignment; the repository comments record their rationale. The package/program researcher may investigate their runtime/build behavior.

## 2. Are Nix, overlays, Home Manager applications, and Homebrew policies consistent?

### Takeaway

The division of responsibility is coherent: Nix manages most tools/apps, Home Manager configures the user environment and copies app bundles, and Homebrew handles a short explicit exception list. Two concrete documentation issues matter: `zap` applies more broadly than “casks dropped from this list,” and pinned tap recipes do not imply pinned bytes for checksum-free/self-updating downloads.

### Cited Findings

- **Correct nix-homebrew / nix-darwin separation:** nix-homebrew controls Homebrew installation, ARM/Intel support, user ownership and immutable tap sources (`darwin/system/homebrew.nix:8–17`); nix-darwin's Homebrew module controls package declarations and activation (`:28–65`). Taps are derived with `builtins.attrNames config.nix-homebrew.taps`, avoiding two independent tap lists. `brews` and `masApps` are explicitly empty. [Configuration](../../darwin/system/homebrew.nix#L8).
- **Pinned-tap integration really disables the API path:** the locked nix-homebrew wrapper exports `HOMEBREW_NO_AUTO_UPDATE=1` when taps are immutable, and `HOMEBREW_NO_INSTALL_FROM_API=1` whenever homebrew-core is declared. Therefore, “you forgot to disable Homebrew's API and your pinned taps are ignored” would be a false-positive finding here. [Locked nix-homebrew `modules/default.nix:126–131`](https://github.com/zhaofengli-wip/nix-homebrew/blob/c11cccfdd36dd69b5323d70d354b2853379c2426/modules/default.nix#L126-L131), [local taps](../../darwin/system/homebrew.nix#L12).
- **Confirmed medium-priority documentation/policy mismatch: zap scope.** Local comment `homebrew.nix:36–37` and README `:82–83` describe removal of casks dropped from the list. Upstream explicitly defines cleanup as acting on **all installed Homebrew packages absent from the generated Brewfile**, not only entries historically managed by this repository. Casks additionally have associated state removed by their zap rules. Thus an independently installed Homebrew cask can also be removed/zapped on activation. This is a configured policy, not evidence that data has already been lost. [Local comment](../../darwin/system/homebrew.nix#L36), [README](../../README.md#L80), [locked upstream definition `homebrew.nix:79–110`](https://github.com/nix-darwin/nix-darwin/blob/bb0b90dbd54e207100de72b5dcbe3188c98a4b69/modules/homebrew.nix#L79-L110).
- **Confirmed medium-priority reproducibility overstatement:** local `homebrew.nix:63` says pinned taps mean upgrades only occur after `nix flake update`. Yet all casks are greedy (`:40–43`), and four explicitly waive checksum enforcement (`:45,52–57`). Upstream defines greedy as upgrading even unversioned or self-updating casks. A pinned Ruby recipe does not content-address a mutable vendor download. As concrete local corroboration, installed `spotify.rb:4–7,17` declares `sha256 :no_check`, unversioned URL `https://download.scdn.co/Spotify#{arch}.dmg`, and `auto_updates true`. The installed tap source was inspected, but its identity against the pending flake tap revision was not independently proven; the policy conclusion already follows from checksum exceptions and greedy semantics. [Local settings](../../darwin/system/homebrew.nix#L40), [overstatement](../../darwin/system/homebrew.nix#L60), [locked greedy documentation](https://github.com/nix-darwin/nix-darwin/blob/bb0b90dbd54e207100de72b5dcbe3188c98a4b69/modules/homebrew.nix#L601-L607), [installed Spotify recipe](file:///opt/homebrew/Library/Taps/homebrew/homebrew-cask/Casks/s/spotify.rb).
- **Intentional checksum exceptions are explicit, not hidden:** global `require_sha = true` plus a named `unverifiedCask` helper makes the four exceptions visible. This is a useful policy boundary. `autoUpdate = false` and `mutableTaps = false` still pin recipes; they simply do not make external app updaters/downloads reproducible. [Policy](../../darwin/system/homebrew.nix#L33).
- **Rosetta activation ordering is valid:** extraActivation installs Rosetta if `oahd` is not running (`homebrew.nix:19–26`). Exact locked Darwin activation source places extraActivation at line 118, Homebrew at line 138; nix-homebrew prepends installation/setup to Homebrew's activation step. Consequently the local ordering comment is supported; do not flag it as an ordering bug. Its process-running check also matches nix-homebrew's own warning check. [Local code](../../darwin/system/homebrew.nix#L19), [locked activation](https://github.com/nix-darwin/nix-darwin/blob/bb0b90dbd54e207100de72b5dcbe3188c98a4b69/modules/system/activation-scripts.nix#L118-L138), [locked nix-homebrew setup check](https://github.com/zhaofengli-wip/nix-homebrew/blob/c11cccfdd36dd69b5323d70d354b2853379c2426/modules/default.nix#L188-L190), [setup hook](https://github.com/zhaofengli-wip/nix-homebrew/blob/c11cccfdd36dd69b5323d70d354b2853379c2426/modules/default.nix#L598-L605).
- **App integration is internally consistent:** HM copies apps to `Applications/Home Manager Apps`; Dock paths are constructed from HM's actual homeDirectory and copyApps.directory rather than duplicating a fixed path. Six Dock entries evaluate under the correct directory. WhatsApp, Slack, Thunderbird, Obsidian are in home.packages, and Firefox Developer Edition/kitty are supplied by their program modules. [HM choice](../../darwin/home/home.nix#L11), [Dock derivation](../../darwin/system/configuration.nix#L148), [packages](../../darwin/home/packages.nix#L38), [Firefox](../../darwin/home/programs/firefox.nix#L6), [kitty](../../darwin/home/programs/kitty.nix#L6).
- **Low-priority duplicate declaration:** `nerd-fonts.jetbrains-mono` is directly included in `darwin/home/packages.nix:31` and supplied again by `programs.kitty.font.package` in `kitty.nix:16`. The evaluated home package list contains `nerd-fonts-jetbrains-mono-3.5.0+2.304` twice. This is redundant declaration, not evidence of doubled Nix store contents or a build collision. [Packages](../../darwin/home/packages.nix#L31), [kitty](../../darwin/home/programs/kitty.nix#L14), [validation transcript](#validation-transcript).
- **Localized workarounds have rationale:** PrismLauncher uses a local `overrideAttrs { LANG = "C"; }` with an upstream PR/removal condition; oxker is overlaid globally because consumers should get the same package. Those are sensible different scopes. Xcode is explicitly commented out pending a manual Apple-ID download, so the configuration is not presently a complete reproducible Xcode installation. [PrismLauncher](../../darwin/home/packages.nix#L42), [oxker](../../darwin/system/overlays.nix#L5), [Xcode](../../darwin/system/configuration.nix#L8).
- **Backup behavior is explicit:** HM's `writeShellApplication` rotates `.backup` to `.backup.2` before moving the conflicting file to `.backup`; it names coreutils in runtimeInputs and quotes paths. README documents the two-generation overwrite policy. No directory/symlink edge-case execution was attempted. [Implementation](../../darwin/system/home-manager.nix#L16), [documentation](../../README.md#L154).

### Inferences

- Keep the existing package-manager split. First clarify whether Homebrew is exclusively declarative. If it is, `zap` can be intentional; document its real scope and the non-rollbackable app-state effect. If local Homebrew experiments are expected, choose a less aggressive policy intentionally (`none`, or `uninstall` when cleanup without cask data deletion is desired). This is a policy decision, not an automatic recommendation to weaken the configuration.
- Replace the “only upgrades after flake update” claim with “tap recipes are lock-pinned; vendor downloads without checksums and self-updating apps can still change independently.” Keep the named checksum exceptions as visible exceptions.
- `enableRosetta = true` provisions support for both architectures; retaining it is proportionate if an actual cask/tool needs it. This review did not prove Intel Homebrew is unnecessary. Avoid deleting it based only on the ARM host platform.
- The `oahd` test measures a running daemon, not a durable package receipt. That is a potential idempotency refinement only, **not a reproduced bug**; upstream uses the same test. It should not outrank the confirmed documentation findings.
- Package ownership should be understandable: programs with useful HM options belong in their program module; plain executables/apps belong in the package list; Homebrew remains the platform-specific exception. Removing the duplicate font declaration is optional housekeeping.

### Gaps

- No package build, checksum download, Brewfile execution, Rosetta install, or cleanup was run. Installed manually managed Homebrew packages were not inventoried; no claim of an actual collision or deletion.
- No claim that Nix-managed app data is backed up by the flake. Moving stateful apps off Homebrew avoids this particular zap policy, but their mutable data still requires a separate backup strategy if wanted.
- Exact contents of copied GUI bundles, actual Dock launch success, and App Management permissions require activation/runtime checks outside this assignment.

## 3. What architecture and documentation changes are proportionate?

### Takeaway

Preserve the current flake and module boundaries. Prioritize a reliable bootstrap/validation runbook, accurate Homebrew semantics, and a small split of the mixed system module; add host/profile abstractions only when another real host creates duplication.

### Cited Findings

- **Bootstrap assumes a matching local hostname:** README `:44,49` uses `--flake .`, while the only declared configuration is `mb-pro` (`flake.nix:52`). Locked darwin-rebuild defaults the selector to `scutil --get LocalHostName` when no `#name` is supplied. This is valid on a host named mb-pro, but not a reliable fresh-machine instruction. A read-only `os.uname().nodename` returned `mb-pro.local` here; LocalHostName itself was not queried, so this is a portability documentation finding, not a reproduced current-host failure. [README](../../README.md#L39), [flake output](../../flake.nix#L51), [locked selector implementation](https://github.com/nix-darwin/nix-darwin/blob/bb0b90dbd54e207100de72b5dcbe3188c98a4b69/pkgs/nix-tools/darwin-rebuild.sh#L162-L172).
- **Bootstrap tool differs from locked configuration source:** README's first command runs `github:nix-darwin/nix-darwin/master#darwin-rebuild`; system input is locked to an exact revision. Fresh bootstrap can thus use a newer rebuild executable than the pinned module tree. No failure was observed; the document should explain this or pin/bootstrap from the chosen input deliberately. [README](../../README.md#L44), [lock](../../flake.lock#L20).
- **Documented location and configured maintenance agree:** README clones to `~/nix`; `programs.nh.flake` derives `${config.users.users.${username}.home}/nix`. This is not an accidental absolute-user-path divergence. The path is still an intentional local convention and would need changing if the repo moves. [README](../../README.md#L31), [nh](../../darwin/system/configuration.nix#L38).
- **Main system file mixes four areas:** environment/Nix/maintenance at `configuration.nix:8–52`, authentication at `:54–57`, system services/window-manager settings at `:59–135`, macOS defaults/user identity at `:137–211`. It is 212 lines, so separation would improve navigation but this is not a massive unmaintainable monolith. [System module](../../darwin/system/configuration.nix#L8).
- **Existing user-side organization is a good base:** imports are explicit; substantial program modules already exist; default.nix retains compact settings. README already proposes extracting development packages and later supporting non-Darwin systems. These are plausible future seams, not missing prerequisites for this machine. [Home imports](../../darwin/home/home.nix#L2), [program imports](../../darwin/home/programs/default.nix#L6), [TODO](../../README.md#L99), [future non-Darwin](../../README.md#L113).
- **Minor documentation drift:** README `:136` refers to `programs/default.nix` without the actual `darwin/home/` prefix. Its feature claim “Complete system configuration” also needs context given commented-out Xcode and intentionally separately installed Reviewr plugin. No exhaustive README/runtime accuracy audit was performed here because other agents own programs/services. [btop path](../../README.md#L135), [feature list](../../README.md#L5), [Xcode](../../darwin/system/configuration.nix#L8), [external plugin](../../README.md#L140).

### Inferences

Recommended order, proportional to evidence:

1. **Operational documentation first (small effort, highest value):** show `--flake .#mb-pro` explicitly; explain username/home/platform customization for a new machine; show non-activating eval separately from build/switch; document the lock-update → eval → build → switch workflow and recovery/rollback limits. State that Nix generation rollback does not recover zapped app data or necessarily restore Homebrew app versions. Record the known Xcode/manual-permission prerequisites. Avoid describing `darwin-rebuild switch --dry-run` as safe read-only verification: locked upstream forwards dry-run as a build option while switch still reaches activation. [Locked rebuild implementation](https://github.com/nix-darwin/nix-darwin/blob/bb0b90dbd54e207100de72b5dcbe3188c98a4b69/pkgs/nix-tools/darwin-rebuild.sh).
2. **Correct Homebrew policy language:** broad cleanup scope and mutable-download caveat above. Preserve the explicit exception helper and deduplicated tap wiring.
3. **Optional surgical module split:** keep `flake.nix` explicit; extract `darwin/system/defaults.nix` and, if wanted, `darwin/system/window-management.nix` or `services.nix`. Keep host platform, primary user, home path, stateVersion, and base Nix settings in a small configuration module. Import the extracted modules explicitly from that module or the flake; do not introduce discovery magic.
4. **Optional package-list grouping:** if it improves daily maintenance, divide plain home packages into `packages/development.nix` and `packages/desktop.nix`, matching the existing TODO. Do not create a module per package. Keep the oxker workaround centralized and add a retest/removal note when revisited.
5. **Add a small repeatable check entry point:** a documented eval command is enough initially. If CI/checks are added, explicitly force `darwinConfigurations.mb-pro.system.drvPath` (or expose its derivation through an appropriate Darwin checks output) and run meaningful existing script checks. A macOS build runner is needed for genuine Darwin realization. No reason to introduce a large CI matrix for one host.
6. **Only when a second host arrives:** introduce `hosts/mb-pro/default.nix` as host identity/composition plus shared Darwin modules; introduce platform-neutral home modules only for genuinely shared configuration. Add a small `mkDarwinHost` helper only if repeated wiring justifies it. Neither flake-parts nor a third-party configuration framework is necessary to gain these boundaries.

Suggested near-term layout (illustrative recommendation, not edited):

```text
flake.nix                       # current explicit input/output wiring
darwin/system/configuration.nix # identity, platform, base Nix/system policy
darwin/system/defaults.nix      # optional extraction of system.defaults
darwin/system/services.nix      # optional extraction of system services
darwin/system/overlays.nix      # existing NUR + narrow compatibility pin
darwin/system/homebrew.nix      # existing package-manager policy
darwin/system/home-manager.nix  # existing integration + backups
darwin/home/home.nix            # existing composition + state compatibility
darwin/home/packages.nix        # retain or split into two meaningful groups
darwin/home/programs/           # existing program ownership
darwin/home/services/           # existing user service ownership
```

### Gaps

- External configuration comparisons are assigned to another researcher; no unsupported claim that this is better/worse than a named community repository is made here.
- Runtime programs/services, custom OpenCode packaging and scripting, secrets handling inside program configs, and detailed window-manager behavior are adjacent agents' scope. The successful system eval covers their Nix integration, not their runtime correctness.
- No architecture or configuration files were changed. The only intended repository write from this assignment is this research note.
