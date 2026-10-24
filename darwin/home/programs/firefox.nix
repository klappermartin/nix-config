{
  pkgs,
  ...
}:
{
  programs.firefox = {
    enable = true;
    languagePacks = [
      "en-US"
      "de"
    ];
    profiles = {
      martin = {
        id = 0;
        name = "martin";
        isDefault = true;
        # mostly taken from: https://github.com/gvolpe/nix-config
        settings = {
          "app.normandy.first_run" = false;
          "app.shield.optoutstudies.enabled" = false;

          "app.update.channel" = "default";

          "browser.contentblocking.category" = "strict"; # or standard
          "browser.ctrlTab.recentlyUsedOrder" = false;

          "browser.download.useDownloadDir" = true;
          "browser.download.viewableInternally.typeWasRegistered.svg" = true;
          "browser.download.viewableInternally.typeWasRegistered.webp" = true;
          "browser.download.viewableInternally.typeWasRegistered.xml" = true;

          "browser.link.open_newwindow" = true;

          "browser.search.region" = "CH";
          "browser.search.widget.inNavBar" = true;

          "browser.shell.checkDefaultBrowser" = false;
          "browser.search.defaultenginename" = "Kagi Search";
          "browser.search.order.1" = "Kagi Search";
          "browser.startup.homepage" = "https://kagi.com";
          "browser.tabs.loadInBackground" = true;
          "browser.urlbar.placeholderName" = "Kagi";
          "browser.urlbar.showSearchSuggestionsFirst" = false;

          "browser.urlbar.quickactions.enabled" = false;
          "browser.urlbar.quickactions.showPrefs" = false;
          "browser.urlbar.shortcuts.quickactions" = true;
          "browser.urlbar.suggest.quickactions" = false;

          "distribution.searchplugins.defaultLocale" = "en-US";

          # "doh-rollout.balrog-migration-done" = true; DNS over HTTPS
          # "doh-rollout.doneFirstRun" = true;

          "dom.forms.autocomplete.formautofill" = false;

          "general.autoScroll" = true;
          "general.useragent.locale" = "en-US";

          # firefox tokyo night
          "extensions.activeThemeID" = "{4520dc08-80f4-4b2e-982a-c17af42e5e4d}";
          "extensions.extensions.activeThemeID" = "{4520dc08-80f4-4b2e-982a-c17af42e5e4d}";

          "extensions.update.enabled" = false;
          "extensions.webcompat.enable_picture_in_picture_overrides" = true;
          "extensions.webcompat.enable_shims" = true;
          "extensions.webcompat.perform_injections" = true;
          "extensions.webcompat.perform_ua_overrides" = true;

          "privacy.donottrackheader.enabled" = true;

          # hardware key auth settings
          # "security.webauth.u2f" = true;
          # "security.webauth.webauthn" = true;
          # "security.webauth.webauthn_enable_softtoken" = true;
          # "security.webauth.webauthn_enable_usbtoken" = true;

          "accessibility.force_disabled" = 1;

          # disable Normandy/Shield
          "app.normandy.api_url" = "";
          "app.normandy.enabled" = false;

          # personalized Extension Recommendations in about:addons and AMO [FF65+]
          # https://support.mozilla.org/kb/personalized-extension-recommendations
          "browser.discovery.enabled" = false;
          "browser.helperApps.deleteTempFileOnExit" = true;

          "browser.newtabpage.activity-stream.default.sites" = "";
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.uitour.enabled" = false;

          # use Mozilla geolocation service instead of Google.
          #"geo.provider.network.url"= "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
          # disable using the OS's geolocation service
          "geo.provider.use_gpsd" = false;
          "geo.provider.use_geoclue" = false;

          # HIDDEN PREF: disable recommendation pane in about:addons
          "extensions.getAddons.showPane" = false;
          # recommendations in about:addons' Extensions and Themes panes [FF68+]
          "extensions.htmlaboutaddons.recommendations.enabled" = false;

          # disable Network Connectivity checks
          "network.connectivity-service.enabled" = false;

          # integrated calculator
          "browser.urlbar.suggest.calculator" = true;

          # TELEMETRY
          # disable new data submission
          "datareporting.policy.dataSubmissionEnabled" = false;
          # disable Health Reports
          "datareporting.healthreport.uploadEnabled" = false;
          # 0332: disable telemetry
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          # disable Telemetry Coverage
          "toolkit.telemetry.coverage.opt-out" = true; # [HIDDEN PREF]
          "toolkit.coverage.opt-out" = true; # [FF64+] [HIDDEN PREF]
          "toolkit.coverage.endpoint.base" = "";
          # disable PingCentre telemetry
          "browser.ping-centre.telemetry" = false;
          # disable Firefox Home (Activity Stream) telemetry
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "toolkit.telemetry.reportingpolicy.firstRun" = false;
          "toolkit.telemetry.shutdownPingSender.enabledFirstsession" = false;
          "browser.vpn_promo.enabled" = false;

          # enable userChrome.css customisation
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          # default fonts (only apply when sites don't specify their own)
          "font.name.monospace.x-western" = "JetBrainsMono Nerd Font";
          "font.name.sans-serif.x-western" = "JetBrainsMono Nerd Font";
          "font.name.serif.x-western" = "JetBrainsMono Nerd Font";
        };

        userChrome = ''
          * {
            font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", monospace !important;
            font-variant-ligatures: none !important;
          }
        '';

        search = {
          force = true;
          default = "Kagi Search";
          order = [
            "Kagi Search"
            "ddg"
            "google"
          ];
          engines = {
            "Kagi Search" = {
              urls = [
                {
                  # TODO: Use kagi session token when sops is set up
                  # TODO: Aliases for lenses
                  template = "https://kagi.com/search?q={searchTerms}";
                }
              ];
              icon = "https://assets.kagi.com/v2/favicon-32x32.png";
              definedAliases = [ "@ks" ];
            };
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS Wiki" = {
              urls = [ { template = "https://nixos.wiki/index.php?search={searchTerms}"; } ];
              icon = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@nw" ];
            };
            "MyNixOS" = {
              urls = [ { template = "https://mynixos.com/search?q={searchTerms}"; } ];
              icon = "https://mynixos.com/favicon-32x32.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@nc" ];
            };
            "Nixhub.io" = {
              urls = [ { template = "https://nixhub.io/search?q={searchTerms}"; } ];
              icon = "https://www.nixhub.io/favicon.ico";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@nh" ];
            };
            "ddg".metaData.alis = "@d";
            "bing".metaData.hidden = true;
            "google".metaData.alias = "@g";
          };
        };

        # TODO: Persist extension configs separately
        extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            bitwarden
            canvasblocker
            darkreader
            dearrow
            decentraleyes
            ff2mpv
            privacy-badger
            react-devtools
            reduxdevtools
            sponsorblock
            tokyo-night-v2
            ublock-origin
            user-agent-string-switcher
            unpaywall
            to-deepl
            link-cleaner
            youtube-recommended-videos
            # epub-reader
            # gql network inspector
          ];
          # TODO: Extension settings
        };
      };
    };
  };
}
