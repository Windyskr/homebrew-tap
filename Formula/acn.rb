# Homebrew Formula。放在 tap 仓库里即可 brew install，或本地：
#   brew install --build-from-source ./Formula/acn.rb
class Acn < Formula
  desc "Agent Completion Notification - Agent 任务完成通知（Claude Code / Codex → 飞书 / Bark）"
  homepage "https://github.com/windyskr/agent-completion-notification"
  url "https://github.com/windyskr/agent-completion-notification/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "040892dbfd96d769d07ea8ea618711619cc934b9f0b711f6798818b9f4e75717"
  license "MIT"
  head "https://github.com/windyskr/agent-completion-notification.git", branch: "main"

  bottle do
    root_url "https://github.com/Windyskr/homebrew-tap/releases/download/acn-2.0.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "92de26ce0b267b47e1f54c9a2f6cd4b5ead9e63486619b111297868f5ca2d2bf"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "6e6f720da6afdb732fc4f0dd0188bf8d0f7dcf249338c9bbaf25af65243d6a2b"
    sha256 cellar: :any,                 x86_64_linux:  "1d0701197faf20125c154bea4272021e29ec16c0230a677db8b5cd55bb56078e"
  end

  depends_on "go" => :build

  def install
    # std_go_args 已经带了 -s -w，这里只补版本号。
    system "go", "build", *std_go_args(ldflags: "-X main.version=#{version}"), "./cmd/acn"
  end

  def caveats
    <<~EOS
      接入 Claude Code 与 Codex（会自动备份两者的配置）：
        acn config feishu-url <飞书机器人地址>
        # 或：acn config bark-url https://api.day.app/<key>
        acn install
        acn doctor

      Claude Code 与 Codex 需重启后生效。查看状态：acn status
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/acn version")

    ENV["ACN_CONFIG_DIR"] = testpath/"config"

    # hook 的两条硬约束，缺一都会弄坏调用方：
    #   1. stdout 必须为空——Codex 的 Stop hook 见到 {"decision":"block"} 会自动续跑一轮；
    #   2. 任何输入下都得退出 0——非零退出码会在用户终端里显示报错。
    # 必须用 pipe_output 显式关闭 stdin，否则 hook 会一直等 EOF 而挂住。
    assert_empty pipe_output("#{bin}/acn hook claude 2>/dev/null", "", 0)
    assert_empty pipe_output("#{bin}/acn hook claude 2>/dev/null", "not json", 0)
  end
end
