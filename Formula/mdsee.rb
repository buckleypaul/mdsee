class Mdsee < Formula
  desc "Simple markdown file viewer for macOS with live reload"
  homepage "https://github.com/buckleypaul/mdsee"
  url "https://github.com/buckleypaul/mdsee/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "b3448eb865eb2473b88070ce2a5017ec7435f0b2e21a00b5cffa0be14b79d402"
  license "MIT"

  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    libexec.install ".build/release/mdsee"
    libexec.install ".build/release/mdsee_mdsee.bundle"
    bin.write_exec_script libexec/"mdsee"
  end

  test do
    # Test that mdsee prints usage when no arguments provided
    output = shell_output("#{bin}/mdsee 2>&1", 1)
    assert_match "Usage:", output
  end
end
