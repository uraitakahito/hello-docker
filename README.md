# HELLO-DOCKER #

![MacOS](https://img.shields.io/badge/sonoma_14.0-support-success.svg?style=for-the-badge&logo=macOS)
![Windows](https://img.shields.io/badge/windows-nosupport-critical.svg?style=for-the-badge&logo=windows)

## Docker 内から GitHub へ SSH で git clone する

Mac では、`launchd` が `ssh-agent` 相当のサービスを自動的に起動します。

```console
% ps ax | grep ssh
 4528 s000  S+     0:00.00 grep ssh
% echo $SSH_AUTH_SOCK # ssh-agent を起動していないのに SSH_AUTH_SOCK が設定されている！
/private/tmp/com.apple.launchd.xxxxx/Listeners
% launchctl list | grep ssh
-       0       com.openssh.ssh-agent
```

鍵を作成したら、公開鍵を [GitHub SSH keys](https://github.com/settings/keys) に登録します。すでに登録済みの場合は、次のコマンドで公開鍵のフィンガープリントを確認できます。

```console
% ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

最近の Mac では、鍵が ssh-agent に自動で読み込まれ、パスフレーズが keychain に保存されるように、~/.ssh/config ファイルを編集する必要があります。

```
Host github.com
  # SSH 接続時に鍵を ssh-agent に追加する
  # 注意: 接続時に自動で追加されるだけで、再起動後に自動で追加されるわけではない
  AddKeysToAgent yes
  # 鍵のパスフレーズを macOS の keychain に保存する
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

SSH 秘密鍵を ssh-agent に追加し、パスフレーズを keychain に保存します。

```console
% ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

**`ssh-add` は、コンテナ内ではなくホストの macOS で実行する必要があります。また、再起動のたびに実行する必要があることに注意してください。**

Dockerfile をビルドしてログインします。
**docker run コマンドで /run/host-services/ssh-auth.sock をマウントすることで、コンテナから Mac ホストの SSH エージェントにアクセスできます。/run/host-services/ssh-auth.sock は一見すると存在しないように見えますが、仮想ソケットなのでマウントできます。**

```console
% cd git-ssh
% PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg user_id=`id -u` --build-arg group_id=`id -g`
% docker container run -it --rm --init -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock --name $PROJECT-container $PROJECT-image /bin/bash
```

Docker 内で接続を確認します。

```console
# ssh -T git@github.com
The authenticity of host 'github.com (11.22.333.444)' can't be established.
ED25519 key fingerprint is SHA256:+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
Hi xxxxx! You've successfully authenticated, but GitHub does not provide shell access.
```

失敗した場合は、次のように表示されます。

```console
# ssh -T git@github.com
The authenticity of host 'github.com (20.27.177.113)' can't be established.
ED25519 key fingerprint is SHA256:+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
git@github.com: Permission denied (publickey).
```


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
