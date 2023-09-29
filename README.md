# booru-tools

scripts for downloading and tagging images from booru websites

- stores tags in `user.xdg.tags` xattr

- tags work with KDE dolphin / KDE's baloo file indexer, idk about other desktop environments

- see https://wiki.archlinux.org/title/Extended_attributes

- These took me a whole morning to write. Its very much WIP...

## Depends on:

`jq` for json parsing

`torsocks` if you're downloading through tor

## Scripts:

`gelbdl.sh` downloads and tags files from every gelbooru link in files.txt

`gelbtag.sh` hashes and looks up every image in a folder on gelbooru

`dandl.sh` downloads and tags files from every danbooru link in files.txt

`dantag.sh` hashes and looks up every image in a folder on danbooru

`moedl.sh` downloads and tags files from moebooru imageboard (think konachan and yande.re) links in files.txt

`moetag.sh` hashes and looks up every image in a folder (provided you specify the booru)