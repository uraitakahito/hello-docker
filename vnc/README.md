# コンテナの中で GUI を動かして VNC で覗く

画面のない（headless な）コンテナの中で GUI アプリを動かし、ホストの macOS から
その画面を VNC で覗くための最小教材です。参考実装

## 仕組み

Linux の GUI は **X11** で動きます。アプリ（クライアント）は「X サーバ」に描画を依頼し、
X サーバが実際の画面へ描きます。コンテナには物理ディスプレイが無いので、代わりに
**Xvfb**（X *virtual* framebuffer＝メモリ上だけの仮想画面）を X サーバとして立てます。
その仮想画面を **x11vnc** が VNC で配信し、さらに **websockify + noVNC** が
VNC を WebSocket に変換してブラウザからも見られるようにします。

```text
xeyes（GUI アプリ）
   │ 描画を依頼
   ▼
Xvfb :1（仮想ディスプレイ）        ← 画面のない X サーバ
   │ 画面を取得
   ▼
x11vnc ───────────────▶ :5901     ← ネイティブ VNC クライアント用
   │ WebSocket に変換
   ▼
websockify + noVNC ───▶ :6080     ← ブラウザ用（クライアント不要）
```

**fluxbox** は軽量なウィンドウマネージャで、窓に枠を付けて移動・操作できるようにします。

## ビルドと起動

```console
% cd vnc
% docker image build -t vnc-image .
% docker container run -it --rm --init -p 5901:5901 -p 6080:6080 --name vnc-container vnc-image
```

`--init` は cant_kill の教訓そのものです。1 つのコンテナで複数プロセス（Xvfb / fluxbox /
x11vnc / websockify）を動かすため、PID 1 のシグナル転送とゾンビ回収を init（tini）に任せます。

## 接続する（2 通り）

### A. ネイティブ VNC クライアント（macOS の「画面共有」）

```console
% open vnc://localhost:5901
```

Finder の「サーバへ接続」（⌘K）に `vnc://localhost:5901` を入れても同じです。
学習用途なのでパスワードは設定していません（後述）。

### B. ブラウザ（noVNC）

ブラウザで次の URL を開くだけです。VNC クライアントのインストールは不要です。

```text
http://localhost:6080/vnc.html
```

`Connect` を押すと、コンテナ内の画面（枠付きの xeyes と fluxbox のタスクバー）が表示されます。

## ホストと UID/GID を合わせる

`USER` を書くだけではユーザーは作られません（[user-test](../user-test) の学び）。
本イメージは `developer` ユーザを実際に作成し、非 root で動かします。
ホストと UID/GID を合わせたい場合（bind mount するときなどに効いてきます）は
ビルド時に上書きします。

```console
% docker image build -t vnc-image \
    --build-arg user_id=$(id -u) --build-arg group_id=$(id -g) .
```

macOS の既定 GID は `20`（staff）で、これは Debian の `dialout` と衝突しますが、
Dockerfile 側で「その GID が既に在れば既存グループを流用する」ようにしてあるため
そのままビルドできます。

## セキュリティ（重要）

このイメージは学習用の割り切りで、x11vnc を **パスワード無し（`-nopw`）** で起動しています。
`-p` で公開したポートに誰でも繋げる状態なので、共有環境や公開ホストでは使わないでください。
本番では `x11vnc -usepw`（パスワード）や SSH トンネル越しの接続にします。
