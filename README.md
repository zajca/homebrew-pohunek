# homebrew-pohunek

Homebrew tap for [pohunek](https://github.com/zajca/pohunek). The formula
installs the pre-built daemon archive (`pohunek`, `pohunekd`,
`pohunek-sessiond`) for Apple silicon Macs.

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

CI checks that the installed binaries have no quarantine attribute, verify with
`codesign --verify --strict`, show `Signature=adhoc`, and carry no `Authority=`.

## Verify provenance

Every release asset has a GitHub build-provenance attestation. Verify the
archive Homebrew downloaded:

```sh
gh attestation verify "$(brew --cache pohunek)" --repo zajca/pohunek
```

## How the bump works

`scripts/bump [<tag>]` points the formula at a release (the latest one without
an argument). It downloads `pohunek-daemon-X.Y.Z-aarch64-apple-darwin.tar.gz`
and its `.sha256` from the release, checks the checksum, runs
`gh attestation verify`, and only then rewrites `url` and `sha256` in
`Formula/pohunek.rb`. If any check fails it exits non-zero and leaves the
formula untouched.

The `Bump` workflow runs the script weekly and on manual dispatch (optional
`tag` input), then commits any change to `main` as `github-actions[bot]` using
only `GITHUB_TOKEN`. Scheduled workflows of a public repository are disabled
after 60 days without repository activity; run the workflow manually in that
case. The formula in the repository carries a placeholder checksum until the
first release that ships the macOS archive has been bumped in.

## License

MIT, the same as pohunek.
