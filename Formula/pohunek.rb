# typed: false
# frozen_string_literal: true

# Installs the pre-built, ad-hoc signed macOS daemon archive of pohunek.
# `scripts/bump` rewrites `url` and `sha256` for each release; the version is
# derived from the URL.
class Pohunek < Formula
  desc "CLI and daemon for supervising long-running AI coding sessions"
  homepage "https://github.com/zajca/pohunek"
  url "https://github.com/zajca/pohunek/releases/download/v0.39.0/pohunek-daemon-0.39.0-aarch64-apple-darwin.tar.gz"
  sha256 "07c044cc1d772b559fed4369030c18f503fbb523d75aefd78a4f9e80d8e0b429"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on :macos

  def install
    # `pohunek service install` copies the three binaries from the directory of
    # the canonicalized `pohunek` executable, so they must be siblings in one
    # real directory; the user-facing `pohunek` is a symlink into it.
    # The catalog trust anchor and the `runtime/` tree (signed catalog, official
    # package archives and their attestations) sit beside the daemon: the daemon
    # reads both from its executable's directory. The archive MANIFEST and
    # packaging/ stay out, so `pohunek setup` treats this layout as a package
    # manager's and the formula checksum is its integrity anchor.
    libexec.install "pohunek", "pohunekd", "pohunek-sessiond", "runtime-catalog-anchor.json", "runtime"
    bin.install_symlink libexec/"pohunek"

    bash_completion.install "completions/pohunek.bash" => "pohunek" if File.exist?("completions/pohunek.bash")
    zsh_completion.install "completions/_pohunek" if File.exist?("completions/_pohunek")
    fish_completion.install "completions/pohunek.fish" if File.exist?("completions/pohunek.fish")
  end

  def caveats
    <<~EOS
      Register the background service, then set pohunek up:
        pohunek service install
        pohunek setup

      Run this after every `brew upgrade pohunek`:
        pohunek service upgrade

      Run this before `brew uninstall pohunek`:
        pohunek service uninstall

      The binaries are ad-hoc signed, not notarized. macOS may ask again for
      Keychain access after an upgrade because the code signature changes.

      Verify the provenance of the release archive with:
        gh attestation verify "$(brew --cache pohunek)" --repo zajca/pohunek
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pohunek --version")
    assert_match version.to_s, shell_output("#{libexec}/pohunekd --version")
    assert_match version.to_s, shell_output("#{libexec}/pohunek-sessiond --version")
    assert_path_exists libexec/"runtime-catalog-anchor.json"
    assert_path_exists libexec/"runtime/runtime-catalog.json"
    refute_path_exists libexec/"MANIFEST"
  end
end
