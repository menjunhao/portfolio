# 作品集

## 内容

### 罪恶装备 奋战 游戏深度体验和拆解分析报告

- 最新版本：v1.0
- 文件：[GGST-analysis-report.zip](https://github.com/menjunhao/portfolio/releases/download/v1.0/GGST-analysis-report.zip)
- 大小：约 308.0 MB

## 版本历史

| 版本 | 文件 | 大小 | 发布日期 |
| --- | --- | --- | --- |
| [v1.0](https://github.com/menjunhao/portfolio/releases/tag/v1.0) | [GGST-analysis-report.zip](https://github.com/menjunhao/portfolio/releases/download/v1.0/GGST-analysis-report.zip) | 308.0 MB | 2026-11-18 |

## 发布新版本

每次更新使用新 tag，旧版本保留在 Releases 中，不被覆盖：

```powershell
$env:GITHUB_TOKEN = '<PAT>'
.\scripts\release.ps1 -Tag v1.1 -File 'E:\path\to\report.zip' -AssetName GGST-analysis-report.zip
```

规则：

- 附件名只能使用 ASCII 字符，中文名会被 GitHub 重置为 `default.zip`
- 单个附件不超过 2 GB（超过 100 MB 的文件不要放进 Git 历史）
- 脚本执行完会打印一行表格，粘贴到上面的版本历史中即可
- 只想检查参数时加 `-DryRun`，不会创建任何东西