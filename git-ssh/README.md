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

ssh-agentから鍵を削除する場合は次のように実行します。

```console
% ssh-add -D
All identities removed.
% ssh-add -l
The agent has no identities.
```

ゲストOSで認証に失敗した場合は、次のように表示されます。

```console
# ssh -T git@github.com
The authenticity of host 'github.com (20.27.177.113)' can't be established.
ED25519 key fingerprint is SHA256:+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
git@github.com: Permission denied (publickey).
```
