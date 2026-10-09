# typed: false
# frozen_string_literal: true

# Installs the pre-built, ad-hoc signed web control center for macOS.
# `scripts/bump pohunek-web` rewrites `url` and `sha256` for each release; the
# version is derived from the URL.
class PohunekWeb < Formula
  desc "Web control center for supervising pohunek sessions"
  homepage "https://github.com/zajca/pohunek-work"
  url "https://github.com/zajca/pohunek-work/releases/download/web-v0.3.0/pohunek-web-0.3.0-aarch64-apple-darwin.tar.gz"
  sha256 "5d3231a052f99ba84ed4a2e9ec5b64a75238c5419833ddc6dd86db0ac91cd219"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma
  depends_on "zajca/pohunek/pohunek"

  def install
    # The archive's own installer copies the backend and the frontend into the
    # user's XDG data directory and registers the launchd agent. It locates the
    # files next to itself, so the tree stays intact in libexec and
    # `pohunek-web-install` runs the installer from there.
    libexec.install "pohunek-web", "frontend", "install.sh", "backend.env.example", "packaging"
    # `install` moves files, so the template the installer needs next to itself
    # is copied for the caveats rather than installed a second time.
    pkgshare.install "README.md"
    cp libexec/"backend.env.example", pkgshare
    (bin/"pohunek-web-install").write <<~SH
      #!/bin/sh
      exec "#{libexec}/install.sh" "$@"
    SH
    (bin/"pohunek-web-install").chmod 0555
  end

  def caveats
    <<~EOS
      Install the backend for your user and register its launchd agent:
        pohunek-web-install

      Edit ~/.config/pohunek/backend.env (template: #{opt_pkgshare}/backend.env.example),
      set POHUNEK_BACKEND_BIND_HOST to this host's NetBird address and
      POHUNEK_BACKEND_PORT, then run `pohunek-web-install` again.

      Run this after every `brew upgrade pohunek-web`:
        pohunek-web-install

      Run this before `brew uninstall pohunek-web`:
        pohunek-web-install --uninstall

      The backend needs the daemon from the pohunek formula
      (`pohunek service install`, see `brew info pohunek`).

      The executable is ad-hoc signed, not notarized. macOS may ask again for
      Keychain access after an upgrade because the code signature changes.

      Verify the provenance of the release archive with:
        gh attestation verify "$(brew --cache pohunek-web)" --repo zajca/pohunek-work
    EOS
  end

  test do
    assert_path_exists libexec/"frontend/index.html"
    # Without a bind host the backend refuses to start and says why.
    output = shell_output("#{libexec}/pohunek-web 2>&1", 1)
    assert_match "POHUNEK_BACKEND_BIND_HOST is required", output
    assert_match "usage:", shell_output("#{libexec}/install.sh --bogus 2>&1", 2)
  end
end
