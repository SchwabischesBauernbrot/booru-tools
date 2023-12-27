# booru-tools

scripts for downloading and tagging images from booru websites

- stores tags in `user.xdg.tags` xattr

- tags work with KDE dolphin / KDE's baloo file indexer, idk about other desktop environments

- see https://wiki.archlinux.org/title/Extended_attributes

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

`e621dl.sh` downloads and tags files from every e621 link in files.txt

`e621tag.sh` hashes and looks up every image in a folder on e621

`*dl-tag.sh` downloads all files found for a given tag

## BUGS

Until federation is added to gitea, I can't do issues here :(

Please feel free to reach out to me on fedi at [@bronze@pl.kitsunemimi.club](https://pl.kitsunemimi.club/users/bronze) , [@bronze@wolfgirl.bar](https://wolfgirl.bar/users/bronze) or by email at [bronze@kitsunemimi.club](mailto:bronze@kitsunemimi.club)