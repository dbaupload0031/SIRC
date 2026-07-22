# 【每日平台突破報告】

此儲存庫存放 SIRC 每日平台整理突破監控的可公開閱讀 HTML 報告。

## 報告位置

`reports/platform-breakout/` 依實際資料日期保存報告。GitHub Pages 會自動部署此目錄，公開網址格式為 `https://dbaupload0031.github.io/SIRC/platform-breakout/<報告檔名>`；瀏覽器會直接渲染 HTML。

## 憑證安全

LINE Channel access token 僅能以本機安全設定或環境變數 `LINE_CHANNEL_ACCESS_TOKEN` 保存，並以 `LINE_GROUP_ID` 設定目的群組；不得寫入 HTML、Git 提交或本儲存庫。

## LINE 推播

`publish-platform-breakout.ps1` 會先提交及推送單一 HTML 報告，等待 GitHub Pages 的公開網址可開啟後，再推送 LINE 群組訊息；GitHub push 或 Pages 部署失敗時不會傳 LINE。請先在 Windows 使用者環境變數中設定 `LINE_CHANNEL_ACCESS_TOKEN` 與 `LINE_GROUP_ID`，然後執行：

```powershell
.\publish-platform-breakout.ps1 -ReportPath 'C:\path\to\report.html' -DataDate 'YYYY-MM-DD' -Summary '當日監控摘要'
```

本儲存庫公開可讀。報告僅供監控與研究，不構成投資建議或下單指示。
