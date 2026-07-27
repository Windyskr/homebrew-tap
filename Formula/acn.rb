# Homebrew Formula。放在 tap 仓库里即可 brew install，或本地：
#   brew install --build-from-source ./Formula/acn.rb
class Acn < Formula
  desc "Agent Completion Notification - Agent 任务完成通知（Claude Code / Codex → 飞书 / Bark）"
  homepage "https://github.com/windyskr/agent-completion-notification"
  url "https://github.com/windyskr/agent-completion-notification/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "c91d05664761462004a7d73bbb6d64b106daf8416ecb69b60839b59efd643884"
  license "MIT"
  head "https://github.com/windyskr/agent-completion-notification.git", branch: "main"

  bottle do
    root_url "https://github.com/Windyskr/homebrew-tap/releases/download/acn-0.1.5"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "66a12a927d3061b94cdf1161782beac2d0f401b3c65b92217b38e662c4b4a117"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "742b90d50b553c94510cc226299cde2612ddc488d4c8c06c136954e1114ea298"
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
