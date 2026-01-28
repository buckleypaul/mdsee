class Mdsee < Formula
  desc "Simple markdown file viewer for macOS with live reload"
  homepage "https://github.com/USERNAME/mdsee"
  url "https://github.com/USERNAME/mdsee/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "SHA256_HASH"
  license "MIT"

  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/mdsee"
  end

  test do
    # Test that mdsee prints usage when no arguments provided
    output = shell_output("#{bin}/mdsee 2>&1", 1)
    assert_match "Usage:", output
  end
end
