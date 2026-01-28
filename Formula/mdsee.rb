class Mdsee < Formula
  desc "Simple markdown file viewer for macOS with live reload"
  homepage "https://github.com/buckleypaul/mdsee"
  url "https://github.com/buckleypaul/mdsee/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "a0c400f4c0e0f25838cf87af2a4a2e5b1e2acf7a8fe58a3bd40adde14bcc0ab1"
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
