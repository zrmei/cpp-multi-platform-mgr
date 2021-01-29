echo "clang-format..."

SCRIPT_PATH="$(readlink -f $(dirname $0))"

export PATH="$SCRIPT_PATH/bin:$PATH"

cd "${SCRIPT_PATH}/../../src/"

DestDir=$1

if [[ "$1" == "" ]]; then
    DestDir="${SCRIPT_PATH}/../../src/MiddleWare/"
fi

echo "$DestDir"

find ${DestDir} -regextype "posix-egrep" -regex '.*/.*\.(h|[hc]p{0,}|c{0,})$' -print -exec clang-format -style=file -i {} \;