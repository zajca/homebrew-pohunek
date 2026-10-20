# typed: false
# frozen_string_literal: true

# Installs the pre-built, ad-hoc signed Pohunek Companion.app, the desktop
# sidebar for the pohunek daemon. `scripts/bump pohunek-companion` rewrites
# `url` and `sha256` for each release; the version is derived from the URL.
class PohunekCompanion < Formula
  desc "Desktop sidebar companion for supervising pohunek sessions"
  homepage "https://github.com/pohunekd/pohunek-companion"
  url "https://github.com/pohunekd/pohunek-companion/releases/download/v0.1.2/pohunek-companion-0.1.2-aarch64-apple-darwin.tar.gz"
  sha256 "179ab42fe5b6796f3c899f0b292da6906f9e28faa4ad7825a1c1444467bf1a6f"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma
  depends_on "zajca/pohunek/pohunek"

  def install
    # The bundle is kept whole so its code signature stays valid; `pohunek-companion`
    # on the PATH is a symlink to the executable inside it.
    prefix.install "Pohunek Companion.app"
    bin.install_symlink prefix/"Pohunek Companion.app/Contents/MacOS/pohunek-companion"
  end

  def caveats
    <<~EOS
      Pohunek Companion.app is installed at:
        #{opt_prefix}/Pohunek Companion.app

      Open it with:
        open "#{opt_prefix}/Pohunek Companion.app"
      or start it from a terminal with `pohunek-companion`.

      The companion talks to the pohunek daemon from the pohunek formula; register
      the background service with `pohunek service install` (see `brew info pohunek`).

      The app is ad-hoc signed, not notarized. macOS may ask again for Keychain
      access after an upgrade because the code signature changes.

      Verify the provenance of the release archive with:
        gh attestation verify "$(brew --cache pohunek-companion)" --repo pohunekd/pohunek-companion
    EOS
  end

  test do
    app = prefix/"Pohunek Companion.app"
    system "/usr/bin/codesign", "--verify", "--deep", "--strict", app
    plist = app/"Contents/Info.plist"
    # The bundle path contains a space, so the arguments are passed without a shell.
    plist_value = lambda do |key|
      Utils.safe_popen_read("/usr/bin/plutil", "-extract", key, "raw", "-o", "-", plist).strip
    end
    assert_equal "io.github.pohunekd.companion", plist_value.call("CFBundleIdentifier")
    assert_equal version.to_s, plist_value.call("CFBundleShortVersionString")
    assert_predicate bin/"pohunek-companion", :executable?
  end
end
