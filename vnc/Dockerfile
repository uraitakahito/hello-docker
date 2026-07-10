# Debian 12 (bookworm) slim — git-ssh と同系列
FROM debian:bookworm-slim

# xvfb      : 画面のない仮想 X サーバ（メモリ上だけの framebuffer）
# x11vnc    : その仮想画面を VNC プロトコルで配信する
# x11-apps  : 動作確認用の xeyes を含む
# fluxbox   : 軽量ウィンドウマネージャ（窓枠・移動・右クリックメニュー）
# novnc     : ブラウザで動く VNC クライアント（Web ページ一式）
# websockify: VNC(TCP) を WebSocket に変換して noVNC へ橋渡しする
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xvfb x11vnc x11-apps fluxbox novnc websockify && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 非 root ユーザを「作成」する（user-test の学び: USER 指定だけでは作られない）。
# 既定は 1000。ホストと UID/GID を合わせたいときは --build-arg で上書きする:
#   docker build --build-arg user_id=$(id -u) --build-arg group_id=$(id -g) ...
# GID が既存（macOS の staff=20 など）の場合は既存グループを流用する。
ARG user_name=developer
ARG user_id=1000
ARG group_id=1000
RUN if ! getent group "${group_id}" >/dev/null; then \
        groupadd --gid "${group_id}" "${user_name}"; \
    fi && \
    useradd --uid "${user_id}" --gid "${group_id}" --create-home --shell /bin/bash "${user_name}"

ENV HOME=/home/${user_name} DISPLAY=:1
# 5901: x11vnc(VNC クライアント用) / 6080: noVNC(ブラウザ用)
EXPOSE 5901 6080

COPY --chmod=755 start-vnc.sh /usr/local/bin/start-vnc.sh

USER ${user_name}
CMD ["/usr/local/bin/start-vnc.sh"]
