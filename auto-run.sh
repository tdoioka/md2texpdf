#!/bin/bash

err() {
  echo "$*" >&2
}

errexit() {
  err "$*"
  exit 1
}

main() {
  # subprocess kill when exit
  trap exittrap EXIT

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

    if [[ "${pre}" == "${post}" ]]; then
      # Create Watch target. refine evry wait.
      local filelist=($(find . -name '.?*' -prune -o \
                             -type d -print))
      for pt in '*.md' 'Makefile' '*.yaml' '*.yml'; do
        filelist+=($(find . -name '.?*' -prune -o \
                          -type f -name "$pt" -print))
      done
      # Waiting file changes
      echo -e "Waiting [${events[@]}]: ${filelist[@]}\n\n"
      inotifywait ${argev[@]} ${filelist[@]} \
        || errexit "fail watch..."
      echo
    fi
  done
}

main
