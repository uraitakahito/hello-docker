# HELLO-DOCKER #

![MacOS](https://img.shields.io/badge/sonoma_14.0-support-success.svg?style=for-the-badge&logo=macOS)
![Windows](https://img.shields.io/badge/windows-nosupport-critical.svg?style=for-the-badge&logo=windows)

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

