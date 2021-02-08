echo "clang-format..."

SCRIPT_PATH="$(readlink -f $(dirname $0))"

export PATH="$SCRIPT_PATH/bin:$PATH"

cd "${SCRIPT_PATH}/../../projects/"

DestDir="${SCRIPT_PATH}/../../projects/projects/$1"

echo "$DestDir"

find ${DestDir} -regextype "posix-egrep" -regex '.*/.*\.(h|[hc]p{0,}|c{0,})$' -print -exec clang-format -style=file -i {} \;