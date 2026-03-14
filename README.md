# openclaw (Container Sandbox)

```text
┌──────────────────────────────────────┐
│   ║   く( ･ω･)っ     ║                │
│   ║      <|\>       ║   Lobster      │
│   ║      </|>       ║   In Kago      │
└──────────────────────────────────────┘
```

這個專案是給第一次使用者也能快速上手的 `openclaw` 容器環境。
目標是讓你在本機使用 OpenClaw，但把活動限制在 container 內，並保留對外網路連線能力。

## 1. 這個專案用了哪些工具

- `Docker`：建立隔離執行環境。
- `Docker Compose`：管理容器啟動/停止與安全設定。
- `OpenClaw CLI`：主要操作工具（容器內指令 `openclaw`）。

## 2. 使用條件（先確認）

- 你的電腦已安裝 Docker 與 Docker Compose v2。
- Docker daemon 已啟動（Docker Desktop / OrbStack / Linux Docker service）。
- 需要可連外網（OpenClaw 初始化會連線）。
- 建議 Docker 可用記憶體至少 4GB（本專案容器上限設定為 2GB）。

## 3. 專案檔案說明

- `Dockerfile`
  - 使用 `node:22-bookworm-slim`
  - 全域安裝 `openclaw@latest`
  - 以非 root 使用者 `10001` 執行
- `docker-compose.yml`
  - 容器啟動與安全限制
  - Named volume：`lobster_workspace`
  - 只映射本機回圈介面：`127.0.0.1:18789:18789`
- `workspace/`
  - 容器工作目錄掛載點（透過 named volume）

## 4. 第一次使用（一步一步）

1. 建置映像

```bash
docker compose build
```

2. 啟動容器

```bash
docker compose up -d
```

3. 檢查容器狀態

```bash
docker compose ps
```

4. 進入容器

```bash
docker compose exec lobster sh
```

5. 確認 OpenClaw 已安裝

```bash
openclaw --version
which openclaw
```

6. 執行初始化（擇一）

```bash
openclaw onboard --mode local --flow quickstart
```

```bash
openclaw setup --wizard --mode local
```

## 5. 怎麼開啟網頁 Dashboard

1. 先確保 gateway 綁定是 `lan`（只要設定一次）

```bash
docker compose exec lobster sh -lc 'f=/workspace/.openclaw/openclaw.json; tmp=/workspace/.openclaw/openclaw.json.tmp; jq ".gateway.bind=\"lan\"" "$f" > "$tmp" && mv "$tmp" "$f"'
```

2. 重新建立容器（套用最新 compose）

```bash
docker compose up -d --force-recreate lobster
```

3. 啟動 gateway（保持這個 terminal 開著）

```bash
docker compose exec lobster sh -lc "openclaw gateway run --bind lan --port 18789"
```

4. 另一個 terminal 取得 dashboard URL

```bash
docker compose exec lobster sh -lc "openclaw dashboard --no-open"
```

5. 把輸出的 `Dashboard URL` 貼到你主機瀏覽器開啟。

## 6. 日常使用

查看日誌：

```bash
docker compose logs -f lobster
```

離開容器 shell：

```bash
exit
```

停止容器：

```bash
docker compose down
```

## 7. 目前已啟用的隔離與安全設定

- `cap_drop: [ALL]`
- `security_opt: no-new-privileges:true`
- `user: "10001:10001"`（非 root）
- `read_only: true`（唯讀 root filesystem）
- `tmpfs`：`/tmp`、`/run`
- `pids_limit: 256`
- `mem_limit: 2g`
- `cpus: 1.0`
- `extra_hosts: host.docker.internal:0.0.0.0`
- `NODE_OPTIONS=--max-old-space-size=1536`（降低 OpenClaw OOM 風險）
- 使用 named volume，不直接 bind mount host 專案路徑

## 8. 重要限制

即使做了容器隔離，container 仍可能透過 host 的實際 IP 嘗試連回主機。  
若你要更嚴格的「不可連 host」，需要在 host 防火牆再補規則。

Linux 範例（請依你的網段調整）：

```bash
sudo iptables -I DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -I DOCKER-USER -s 172.16.0.0/12 -d 10.0.0.0/8 -j DROP
sudo iptables -I DOCKER-USER -s 172.16.0.0/12 -d 172.16.0.0/12 -j DROP
sudo iptables -I DOCKER-USER -s 172.16.0.0/12 -d 192.168.0.0/16 -j DROP
sudo iptables -A DOCKER-USER -j RETURN
```

## 9. 常見問題

- 問題：`Container ... is restarting`
  - 先看：`docker compose logs --tail=200 lobster`
- 問題：`openclaw` 指令跑到 OOM
  - 確認 compose 已設定 `mem_limit: 2g` 與 `NODE_OPTIONS`
- 問題：進不去容器
  - 先確認 `docker compose ps` 是 `Up` 狀態

## 10. 台股研究起手式

已提供可直接使用的研究模板檔案：

- `playbooks/tw-stock/system_prompt.md`
- `playbooks/tw-stock/daily_report_template.md`
- `playbooks/tw-stock/quickstart.md`

建議流程：

1. 先把 `system_prompt.md` 貼進 OpenClaw system prompt。
2. 用 `quickstart.md` 的每日起手 prompt 先跑一週。
3. 每天輸出遵循 `daily_report_template.md`，先做研究、不直接下單。
