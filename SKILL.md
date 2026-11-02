---
name: agent-skill-creator
description: >-
  新建、安装、更新或改造 agent 技能时使用：把一份流程或规范文档变成可被加载的技能、
  选定技能名、写 frontmatter 触发描述、按当前环境的源目录和安装约定部署技能。
  用户提到「做成技能」「新建技能」「装到 .agents/skills」「这个文件放着没用」时使用。
metadata:
  short-description: 新建与安装 agent 技能
---

# agent-skill-creator

本技能中的 `D:\tools\skills` 是原作者本机的示例约定，不是其他用户的强制路径。使用时以当前用户明确指定或已有的技能源目录和安装目录为准；未指定时先确认可用位置。脚本位于本技能目录的 `scripts/install-skill.ps1`，不要假设技能安装在示例路径。下面的 Windows junction 方法仅适用于 Windows；其他系统遵循其 Agent 的安装文档。

## 何时用

- 用户说「把 X 做成技能」「新建一个技能」「装到 `.agents/skills`」「这个文件放着没用」。
- 把散落的规范/流程文档改造成 agent 可按需加载的技能。
- 修改已有技能（源即真身，安装位只是链接）。
- 安装或重新安装已有技能、检查安装链接和加载状态。

## 何时不该做成技能

- 一次性任务说明、单仓库 README、可由一条精确命令决定的选择。
- 纯资料汇编：没有动作步骤、没有触发场景。宁可留成文档，也不要造一个永远不被加载的技能。

## 目录约定（本机）

| | 路径 | 说明 |
|---|---|---|
| 源（唯一权威副本） | `D:\tools\skills\<name>\SKILL.md` | 可带 `scripts/`、`reference/`、素材文件 |
| 安装位 | `$env:USERPROFILE\.agents\skills\<name>` | **目录联接（junction）**，指向源目录 |

只有源目录保存内容；安装位删掉重建不影响源。改源文件立即生效，不需要重装；只有改**目录名**才需要重装。

## 命名

- 必须匹配 `^[a-z][a-z0-9-]*$`：小写字母开头，只含小写字母、数字、连字符。
- **下划线开头非法**：`skill()` 会直接报 `invalid skill name`（实测 `_linktest`）。
- 动作导向：`npm-publish`、`dsh-plugin-creator`；避免 `-spec` / `-doc` 这类只描述文档的后缀——名称要能预示行为。
- frontmatter 的 `name` 必须与目录名逐字一致。

## frontmatter

```yaml
---
name: <目录名>
description: >-
  一句话：做什么 + 什么时候用。把用户可能说的词、涉及的文件类型和动作都写进去。
metadata:
  short-description: 不超过 20 字的短描述
---

# 正文标题
```

- `description` 决定技能是否被加载，比正文更重要。不要写「这是一个技能」这类空话。
- `---` 与正文 `#` 标题之间留一个空行。

## 正文写法

- 先给可执行步骤（命令、完整路径、参数），再给规则与边界。
- 长模板、大表格放同目录文件（`scripts/`、`reference/`），正文只给入口。
- 相对路径以技能 base directory 为基准。
- 显式写「禁止 / 不要」的边界，比只写正面要求有效。

## 安装与更新

```powershell
pwsh -NoProfile -File '<本技能目录>\scripts\install-skill.ps1' -Name <name> -SourceRoot '<技能源目录>' -InstallRoot '<安装目录>'
```

脚本行为：校验技能名和源文件 → 创建安装目录 → 仅替换已有 junction；同名实体目录或其他链接则停止并保留 → 建 junction → 回读校验。默认源目录为脚本所在技能目录的父目录；安装目录默认为当前用户的 `.agents\skills`，可用参数覆盖。

- 删除技能：先删安装位链接，再删源目录。
- 移动 `D:\tools\skills` 会让所有技能失效，移动后需批量重建链接。
- 安装位在 C:、源在 D: 是允许的（junction 支持跨本地卷，不支持 UNC 路径）。

## 验证（必做）

1. 技能清单出现该名字（本会话会实时刷新，无需重启）。
2. `skill(<name>)` 返回完整正文，不报 `invalid skill name` / not found。
3. 正文引用的脚本路径能用 `Test-Path` 打开。
4. 清理任何临时测试技能与残留目录。

## 维护提醒

- 备份/同步工具按路径去重时，安装位是链接，不要当成第二份内容统计。
- 多个技能共享同一 git 仓库（如 `prd-master-skills`）时，链接建在仓库外，不影响 `git status`。

## Git 与 GitHub

- 在技能**源目录**检查 `git rev-parse --show-toplevel`、`git status --short`、当前分支和 `git remote -v`，确认所属仓库及远端；不要把安装位 junction 当作第二份仓库。多个技能共享仓库时只暂存本次任务涉及的文件。
- 检查 diff 和验证结果，排除凭据、缓存及无关改动；按任务要求用清楚的提交信息提交源文件。已有用户改动不得擅自覆盖或一并提交。
- 用户要求提交或推送时，按现有分支与仓库约定执行，确认目标 GitHub 远端及分支；推送前检查远程更新和仓库规则，不强推、不改写他人历史。若未初始化仓库或未配置远端，先说明情况；不要擅自创建公开仓库。完成后核对提交和远端状态并报告。
