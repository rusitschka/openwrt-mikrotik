# screen only for interactive shells,
# see https://unix.stackexchange.com/a/45587
case $- in
  *i*)
    exec screen -xRR
    ;;
esac
