# homebrew-pohunek

Homebrew tap for [pohunek](https://github.com/zajca/pohunek) and its user
surfaces from [pohunek-work](https://github.com/zajca/pohunek-work). The
formulae install pre-built archives for Apple silicon Macs:

| Formula | Installs | Release repository |
|---------|----------|--------------------|
| `pohunek` | CLI and daemon (`pohunek`, `pohunekd`, `pohunek-sessiond`) | `zajca/pohunek` |
| `pohunek-gui` | `Pohunek.app`, native GUI (`pohunek-gui` on the `PATH`) | `zajca/pohunek-work` |
| `pohunek-web` | web control center backend and frontend | `zajca/pohunek-work` |

`pohunek-gui` and `pohunek-web` depend on `pohunek`: both talk to its daemon.
Homebrew installs the latest `pohunek`, not the release a surface was built
against, so CI checks that the installed `pohunek` supports the protocol
version the surfaces speak (`scripts/check-compatible`).

## Install

```sh
brew install zajca/pohunek/pohunek
pohunek service install
```

After every `brew upgrade pohunek`, run:

```sh
pohunek service upgrade
```

Before `brew uninstall pohunek`, run:

```sh
pohunek service uninstall
```

The three binaries live in `$(brew --prefix pohunek)/libexec`, and `pohunek` on
your `PATH` is a symlink into that directory. `pohunek service install` copies
them into `~/.local/libexec/pohunek/<version>/` and registers a launchd agent.
The service always uses the default `~/.local` prefix, because its directory
trust checks refuse prefixes under `/opt/homebrew`.

## The GUI and the web control center

```sh
brew install zajca/pohunek/pohunek-gui   # Pohunek.app
brew install zajca/pohunek/pohunek-web   # web control center
pohunek-web-install                      # per-user install of the backend
```

`pohunek-gui` keeps `Pohunek.app` whole in `$(brew --prefix pohunek-gui)` so its
code signature stays valid. `pohunek-web-install` runs the installer of the web
archive (data under `~/.local/share/pohunek/web`, a launchd agent, and
`~/.config/pohunek/backend.env`); run it again after every `brew upgrade
pohunek-web` and run `pohunek-web-install --uninstall` before `brew uninstall
pohunek-web`. `brew info <formula>` shows the exact steps.

## Ad-hoc signing, Gatekeeper and Keychain

The binaries are ad-hoc signed and not notarized, and no Apple Developer
certificate is involved.

- Gatekeeper: Homebrew formula installs do not set the quarantine attribute
  (only casks do), so Gatekeeper does not assess the binaries. Files downloaded
  by other means (a browser, for example) are quarantined and would be blocked.
- Keychain: macOS ties Keychain access to the code signature. An ad-hoc
  signature changes with every build, so macOS may ask again for Keychain access
  after an upgrade.
- Homebrew re-signs ad hoc any Mach-O file it relinks, so installed binaries stay
  ad-hoc signed.

CI checks, for every formula, that the installed files have no quarantine
attribute, verify with `codesign --verify --strict` (`--deep` for the app
bundle), show `Signature=adhoc`, and carry no `Authority=`
(`scripts/check-installed`).

## Verify provenance

Every release asset has a GitHub build-provenance attestation. Verify the
archive Homebrew downloaded:

```sh
gh attestation verify "$(brew --cache pohunek)" --repo zajca/pohunek
gh attestation verify "$(brew --cache pohunek-gui)" --repo zajca/pohunek-work
gh attestation verify "$(brew --cache pohunek-web)" --repo zajca/pohunek-work
```

## How the bump works

`scripts/bump <formula> [<tag>]` points a formula at a release of its repository.
`zajca/pohunek-work` versions its surfaces independently, so each formula has
its own tag prefix: `vX.Y.Z` for `pohunek`, `gui-vX.Y.Z` for `pohunek-gui` and
`web-vX.Y.Z` for `pohunek-web`. Without a tag the newest published release with
that prefix is used; it fails when there is none. It downloads the formula's
`aarch64-apple-darwin` archive (`pohunek-daemon-`, `pohunek-gui-` or
`pohunek-web-` `X.Y.Z-aarch64-apple-darwin.tar.gz`) and its `.sha256`, checks
the checksum, runs `gh attestation verify`, and only then rewrites `url` and
`sha256` in `Formula/<formula>.rb`. If any check fails it exits non-zero and leaves the
formula untouched.

The `Bump` workflow runs the script for every formula weekly and on manual
dispatch (optional `formula` input; the optional `tag` input needs it, because the tag prefix differs per formula), then commits any change to `main` as `github-actions[bot]` using
only `GITHUB_TOKEN`. Scheduled workflows of a public repository are disabled
after 60 days without repository activity; run the workflow manually in that
case. The formula in the repository carries a placeholder checksum until the
first release that ships the macOS archive has been bumped in.

## License

MIT, the same as pohunek.
