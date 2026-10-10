# typed: false
# frozen_string_literal: true

# Installs the pre-built, ad-hoc signed Pohunek.app of the native GUI.
# `scripts/bump pohunek-gui` rewrites `url` and `sha256` for each release; the
# version is derived from the URL.
class PohunekGui < Formula
  desc "Native desktop GUI for supervising pohunek sessions"
  homepage "https://github.com/zajca/pohunek-work"
  url "https://github.com/zajca/pohunek-work/releases/download/gui-v0.3.2/pohunek-gui-0.3.2-aarch64-apple-darwin.tar.gz"
  sha256 "d4d7614619e0418f63726ba6145ca68a8d1fbc996f021704414d90a96ff12592"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma
  depends_on "zajca/pohunek/pohunek"

  def install
    # The bundle is kept whole so its code signature stays valid; `pohunek-gui`
    # on the PATH is a symlink to the executable inside it.
    prefix.install "Pohunek.app"
    bin.install_symlink prefix/"Pohunek.app/Contents/MacOS/pohunek-gui"
  end

  def caveats
    <<~EOS
      Pohunek.app is installed at:
        #{opt_prefix}/Pohunek.app

      Open it with:
        open "#{opt_prefix}/Pohunek.app"
      or start it from a terminal with `pohunek-gui`.

      The GUI talks to the pohunek daemon from the pohunek formula; register the
      background service with `pohunek service install` (see `brew info pohunek`).

      The app is ad-hoc signed, not notarized. macOS may ask again for Keychain
      access after an upgrade because the code signature changes.

      Verify the provenance of the release archive with:
        gh attestation verify "$(brew --cache pohunek-gui)" --repo zajca/pohunek-work
    EOS
  end

  test do
    app = prefix/"Pohunek.app"
    system "/usr/bin/codesign", "--verify", "--deep", "--strict", app
    plist = app/"Contents/Info.plist"
    assert_equal "io.github.zajca.pohunek.gui",
                 shell_output("/usr/bin/plutil -extract CFBundleIdentifier raw -o - #{plist}").strip
    assert_equal version.to_s,
                 shell_output("/usr/bin/plutil -extract CFBundleShortVersionString raw -o - #{plist}").strip
    assert_predicate bin/"pohunek-gui", :executable?
  end
end
