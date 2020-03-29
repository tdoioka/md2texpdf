#!/bin/bash

err() {
  echo "$*" >&2
}

errexit() {
  err "$*"
  exit 1
}

main() {
  type inotifywait >& /dev/null \
    || errexit 'Not found inotifywait !! To install "sudo apt install inotify-tools".'

  # create wait event
  local events=(CLOSE_WRITE MOVE CREATE DELETE)
  local argev=()
  for ev in ${events[@]}; do
    argev+=("-e $ev")
  done

  local pre=
  local post=
  while :; do
    # make
    pre=$(make hash)
    make -j 4
    post=$(make hash)

    echo "checksum: pre :$pre"
    echo "checksum: post:$post"
    if [[ "${pre}" == "${post}" ]]; then
      # Create Watch target. refine evry wait.
      local filelist=($(make srclist))
      # Waiting file changes
      echo -e "Waiting [${events[@]}]: ${filelist[@]}\n\n"
      inotifywait ${argev[@]} ${filelist[@]} \
        || errexit "fail watch..."
      echo
    fi
  done
}

main
