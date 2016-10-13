fswiki
======

FreeStyleWiki private modified repository

Setup with Heroku (recommended)
===============================
```:bash
$ git clone https://github.com/Hiroyuki-Nagata/fswiki.git
$ cd fswiki
$ heroku create --buildpack http://github.com/pnu/heroku-buildpack-perl.git
$ git push heroku master
```

* Remove build cache
```:bash
$ heroku plugins:install heroku-repo
$ heroku repo:purge_cache -a appname
```

You will see FreeStyleWiki pages at https://xxxxxxxx.herokuapp.com/fswiki/wiki.cgi

Setup with Apache
==================

automated script
https://gist.github.com/Hiroyuki-Nagata/7b7df9ddcb25c43078e1

Change root and exec scirpt.

```:
# git clone https://gist.github.com/7b7df9ddcb25c43078e1.git
# cd 7b7df9ddcb25c43078e1
# chmod +x ./gistfile1.sh
# ./gistfile1.sh
```

Here, you can see FreeStyleWiki pages at http://hostname/fswiki/wiki.cgi
