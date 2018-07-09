#!/bin/sh

echo "standard output"
if [ $# -gt 0 ]; then
  echo "standard error" 1>&2
fi
exit $#
