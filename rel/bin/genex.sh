#!/bin/bash

set -e

full_path=$(realpath $0)
current_dir=$(dirname $full_path)
bin_file="${current_dir}/genex"

lst=""

for word in $@
do
  case $lst in
    "" )
      lst="\"$word\""
      ;;
    *)
      lst="$lst, \"$word\""
      ;;
  esac
done

${bin_file} eval "Genex.ReleaseTask.run([$lst])"
