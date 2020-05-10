fswiki
======

FreeStyleWiki private modified repository


setup
=====

automated script
https://gist.github.com/hangingman/7b7df9ddcb25c43078e1

Change root and exec scirpt.

```:
# git clone https://gist.github.com/7b7df9ddcb25c43078e1.git
# cd 7b7df9ddcb25c43078e1
# chmod +x ./gistfile1.sh
# ./gistfile1.sh
```

Here, you can see FreeStyleWiki page at http://hostname/fswiki/wiki.cgi

setup with carton
=================

```
$ carton install
$ carton exec plackup -r -host 93.188.167.16 -p 80
```
