class Ezkey < Formula
  desc "Print ezkey disclaimer and macOS build instructions"
  homepage "https://ezkey.app"
  url "https://github.com/edtadros/ezkey/archive/refs/heads/master.tar.gz"
  version "1.0.0"
  license "MIT"
  depends_on :macos
  depends_on "node"

  def install
    bin.install "cli/ezkey.mjs" => "ezkey"
  end

  test do
    assert_match "ezkey", shell_output("#{bin}/ezkey")
  end
end
