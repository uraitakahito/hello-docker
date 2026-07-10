#!/bin/bash
set -eo pipefail

# 1) 仮想ディスプレイ :1 を起動（1280x800・24bit カラー）
Xvfb :1 -screen 0 1280x800x24 &

# 2) X サーバのソケットが出来るまで待つ（追加パッケージ不要な簡易チェック）
until [ -e /tmp/.X11-unix/X1 ]; do sleep 0.1; done

# 3) ウィンドウマネージャ（窓枠・移動・右クリックメニュー）
fluxbox &

# 4) 動作確認用の GUI アプリ（目玉がカーソルを追う）。DISPLAY は ENV で :1
xeyes &

# 5) noVNC: VNC(5901) を WebSocket 経由でブラウザ(6080)へ橋渡し
websockify --web=/usr/share/novnc 6080 localhost:5901 &

# 6) 画面 :1 を VNC(5901) で配信。学習用途なのでパスワード無し(-nopw)
exec x11vnc -display :1 -rfbport 5901 -forever -shared -nopw
