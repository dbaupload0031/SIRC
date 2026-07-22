# SIRC 每日監控報告

此儲存庫存放 SIRC 每日平台整理突破監控的可公開閱讀 HTML 報告。

## 報告位置

`reports/platform-breakout/` 依實際資料日期保存報告。每日流程完成查詢與 HTML 產製後，會將新報告提交並推送至 `main`；推送成功後，LINE 推播訊息會附上該 GitHub 檔案頁連結。

## 憑證安全

LINE Channel access token 僅能以本機安全設定或環境變數 `LINE_CHANNEL_ACCESS_TOKEN` 保存，並以 `LINE_GROUP_ID` 設定目的群組；不得寫入 HTML、Git 提交或本儲存庫。

本儲存庫公開可讀。報告僅供監控與研究，不構成投資建議或下單指示。
