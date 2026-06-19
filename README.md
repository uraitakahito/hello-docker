# HELLO-DOCKER #

![MacOS](https://img.shields.io/badge/sonoma_14.0-support-success.svg?style=for-the-badge&logo=macOS)
![Windows](https://img.shields.io/badge/windows-nosupport-critical.svg?style=for-the-badge&logo=windows)

## docker stop でグレースフルシャットダウンを行う方法

[ngzm のブログ](https://ngzm.hateblo.jp/entry/2017/08/22/185224)

上記リンクで紹介されているサンプル: [cant_kill](cant_kill)

これを避けるには、Docker 内に init プロセスを用意するか、コンテナ作成時に init を指定します。

```console
% docker run --init --name hello_node -p 3000:3000 nodetest
```

## 調査: Docker でユーザーはどうなるのか？

Dockerfile で USER を指定しただけではユーザーは作成されず、起動時に `-u` で指定しようとしても、やはりユーザーは作成されません。

```console
% cd user-test
% cat Dockerfile
FROM busybox
USER developer
% docker build -t user-test .
% docker run -it --rm --name c-user-test user-test /bin/sh
docker: Error response from daemon: unable to find user developer: no matching entries in passwd file.
% docker run -it --rm -u "developer" --name c-user-test user-test /bin/sh
docker: Error response from daemon: unable to find user developer: no matching entries in passwd file.
```

一方で、UID/GID を指定する分には問題なく動作します。
「UID/GID はホストと一致させる必要があるが、起動後に root 権限やユーザー名は不要」という要件であれば、これで十分です。

```console
% docker run -it --rm -u "1000:1000" busybox /bin/sh
$ cat /etc/passwd
root:x:0:0:root:/root:/bin/sh
daemon:x:1:1:daemon:/usr/sbin:/bin/false
bin:x:2:2:bin:/bin:/bin/false
sys:x:3:3:sys:/dev:/bin/false
sync:x:4:100:sync:/bin:/bin/sync
mail:x:8:8:mail:/var/spool/mail:/bin/false
www-data:x:33:33:www-data:/var/www:/bin/false
operator:x:37:37:Operator:/var:/bin/false
nobody:x:65534:65534:nobody:/home:/bin/false
$ id
uid=1000 gid=1000 groups=1000
$ whoami
whoami: unknown uid 1000
```

## Devcontainer はどうやって UID/GID を変更しているのか？

ユーザーの BASE_IMAGE から別のイメージを作成し、必要に応じてそこで書き換えているようです。devcontainers/cli の [updateUID.Dockerfile](https://github.com/devcontainers/cli/blob/d2c1bc89c39f79b8a8da437964976965f3400e81/scripts/updateUID.Dockerfile) を参照してください。
