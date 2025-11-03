# HELLO-DOCKER #

![MacOS](https://img.shields.io/badge/sonoma_14.0-support-success.svg?style=for-the-badge&logo=macOS)
![Windows](https://img.shields.io/badge/windows-nosupport-critical.svg?style=for-the-badge&logo=windows)

## SSH git clone from GitHub inside Docker

~~Start ssh-agent in the background. `ssh-agent -s` starts ssh-agent and displays environment variables. Note that **each time you type this command, a new ssh-agent is started and the environment variables change.** Therefore, use `eval` as shown below.~~

```console
% eval $(ssh-agent -s) # Do not run
Agent pid 1655
```

~~Make sure the environment variable `SSH_AUTH_SOCK` is set and ssh-agent is running.~~

```console
% ps ax | grep ssh
 1655   ??  Ss     0:00.00 ssh-agent -s
% echo $SSH_AUTH_SOCK
/var/folders/v1/xxxxx/T//ssh-xxxxx/agent.1654
```

The above steps are unnecessary on macOS.
ON MAC, `launchd` AUTOMATICALLY STARTS A SERVICE EQUIVALENT TO `ssh-agent` .

```console
% ps ax | grep ssh
% echo $SSH_AUTH_SOCK # SSH_AUTH_SOCK is set even though ssh-agent hasn't been started!
/private/tmp/com.apple.launchd.xxxxx/Listeners
% launchctl list | grep ssh
-       0       com.openssh.ssh-agent
```

After creating a key, register the public key at [GitHub SSH keys](https://github.com/settings/keys). If you have already registered it, you can check the fingerprint of the public key with the following command:

```console
% ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

On recent Macs, you need to edit the ~/.ssh/config file so that the key is automatically loaded into ssh-agent and the passphrase is stored in the keychain.

```
Host github.com
  # Add the key to ssh-agent on SSH connection
  # Note: It's added automatically when connecting, not automatically after reboot
  AddKeysToAgent yes
  # Save the key's passphrase in the macOS keychain
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

Add the SSH private key to ssh-agent and save the passphrase in the keychain.

```console
% ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Please note that `ssh-add` must be run on the host macOS, not inside the container, and you need to run it after every reboot.

Build the Dockerfile and log in.

```console
% cd git-ssh
% PROJECT=$(basename `pwd`) && docker image build -t $PROJECT-image . --build-arg user_id=`id -u` --build-arg group_id=`id -g`
% docker container run -it --rm --init -v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent --name $PROJECT-container $PROJECT-image /bin/bash
# ls -al $SSH_AUTH_SOCK
srw-rw---- 1 root root 0 Aug 15 03:47 /ssh-agent
```

Change the socket permissions. This is not ideal, so let me know if there is a better way.

```console
# chmod 777 $SSH_AUTH_SOCK
```

Check connectivity inside Docker.

```console
# ssh -T git@github.com
The authenticity of host 'github.com (11.22.333.444)' can't be established.
ED25519 key fingerprint is SHA256:+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
Hi xxxxx! You've successfully authenticated, but GitHub does not provide shell access.
```

If it fails, it will be displayed as follows:

```console
# ssh -T git@github.com
The authenticity of host 'github.com (20.27.177.113)' can't be established.
ED25519 key fingerprint is SHA256:+xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
git@github.com: Permission denied (publickey).
```


## How to perform graceful shutdown with docker stop

[ngzm's blog](https://ngzm.hateblo.jp/entry/2017/08/22/185224)

Sample introduced in the above link: [cant_kill](cant_kill)

To avoid this, either set up an init process inside Docker or specify init when creating the container.

```console
% docker run --init --name hello_node -p 3000:3000 nodetest
```

## Investigation: What happens to users in Docker?

Simply specifying USER in the Dockerfile does not create the user, and even if you try to specify it with `-u` at startup, the user is still not created.

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

On the other hand, specifying UID/GID works fine.
If the requirement is "UID/GID must match the host, but root privileges or username are not needed after startup," this should be sufficient.

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

## How does Devcontainer change UID/GID?

It seems that it creates another image from the user's BASE_IMAGE and rewrites it there if necessary. See devcontainers/cli's [updateUID.Dockerfile](https://github.com/devcontainers/cli/blob/d2c1bc89c39f79b8a8da437964976965f3400e81/scripts/updateUID.Dockerfile).

