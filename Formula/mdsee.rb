class Mdsee < Formula
  desc "Simple markdown file viewer for macOS with live reload"
  homepage "https://github.com/buckleypaul/mdsee"
  url "https://github.com/buckleypaul/mdsee/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "28df3a05de9fa780acfd8b48c735f160dbd13a51382640fd0aee61f36e0ca164"
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
