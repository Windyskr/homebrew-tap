# Homebrew Formula。放在 tap 仓库里即可 brew install，或本地：
#   brew install --build-from-source ./Formula/acn.rb
class Acn < Formula
  desc "Agent Completion Notification - Agent 任务完成通知（Claude Code / Codex → 飞书 / Bark）"
  homepage "https://github.com/windyskr/agent-completion-notification"
  url "https://github.com/windyskr/agent-completion-notification/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "83e53081ea0258c481bfe42db6327ac4f08e14c37aad4d63b6fd5f3785b2e042"
  license "MIT"
  head "https://github.com/windyskr/agent-completion-notification.git", branch: "main"

  bottle do
    root_url "https://github.com/Windyskr/homebrew-tap/releases/download/acn-1.2.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "7ee5b463a8a39087b1886176450af114dba2cb13697fac7de31171d27865fef7"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "51162584c0c88454b0619299bfb2fd358e8836b2a646610065df4e21a8b327f7"
    sha256 cellar: :any,                 x86_64_linux:  "4c374ca246ce345c95827efb1fe289b4d08af8ae4c9f8e9bf4650186c551f537"
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
