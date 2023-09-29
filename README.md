# booru-tools

scripts for downloading and tagging images from booru websites

- stores tags in `user.xdg.tags` xattr

- tags work with KDE dolphin / KDE's baloo file indexer, idk about other desktop environments

- see https://wiki.archlinux.org/title/Extended_attributes

- These took me a whole morning to write. Its very much WIP...

## Depends on:

`jq` for json parsing

`torsocks` if you're downloading through tor

```
./gelbdl.sh [-t] [-s]
Simply make a files.txt inside a folder and paste all your links, then run this script to download them all!
        -h      shows this help message
        -t      downloads using tor (requires torsocks)
        -s      sets the delay after each request, defaults to 1
```

```
./gelbtag.sh [-t] [-s]
Tags existing pictures inside a folder
        -h      shows this help message
        -t      downloads using tor (requires torsocks)
        -s      sets the delay after each request, defaults to 1
```