#!/bin/sh

PROGNAME=$(basename "$0")

case "$1" in
-h|--help)
  echo "usage: $PROGNAME [fswiki_home]"
  ;;
-v|--version)
  echo "$PROGNAME version 0.01"
  exit
  ;;
esac

echo "# fswiki setup (for 4.0.0-fork)..."
echo "prepare..."

if test -z "$FSWIKI_HOME";
then
  FSWIKI_HOME=.
fi
if test -n "$1";
then
  FSWIKI_HOME="$1"
fi

echo "  FSWIKI_HOME=$FSWIKI_HOME"
PERM_DIR=777
PERM_FILE=666

for dir in backup attach pdf log data config theme tmpl tools;
do
  echo "  check $FSWIKI_HOME/$dir..."
  test -d "$FSWIKI_HOME"/$dir || mkdir "$FSWIKI_HOME"/$dir || exit 1
  find "$FSWIKI_HOME/$dir" -type d -exec chmod $PERM_DIR {} \;
  find "$FSWIKI_HOME/$dir" -type f -exec chmod $PERM_FILE {} \;
done

for logfile in access.log attach.log freeze.log download_count.log;
do
  echo "  check $FSWIKI_HOME/log/$logfile..."
  test -e "$FSWIKI_HOME"/log/$logfile || touch "$FSWIKI_HOME"/log/$logfile || exit 1
done

FSWIKI_SECRET=$(uuidgen)
sed -i "s/secret =.*/secret = ${FSWIKI_SECRET}/g" setup.dat

echo "done"

