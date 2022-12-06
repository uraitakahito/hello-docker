# HELLO-DOCKER #

## docker stopでgraceful shutdownできない場合

[cant_kill](cant_kill)

[詳細](https://ngzm.hateblo.jp/entry/2017/08/22/185224)

回避するにはリンク先のようにDocker内にinitを仕込むか、container作成の際にinitを指定する。

```console
% docker run --init --name hello_node -p 3000:3000 nodetest
```
