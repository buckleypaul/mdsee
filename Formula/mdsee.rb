class Mdsee < Formula
  desc "Simple markdown file viewer for macOS with live reload"
  homepage "https://github.com/buckleypaul/mdsee"
  url "https://github.com/buckleypaul/mdsee/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "936e9d444081f3010185137cc74acfcb0f0c2acec15db73bc499d76abb225426"
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
