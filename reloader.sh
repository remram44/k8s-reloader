#!/bin/sh

USAGE="$(printf 'Usage:\n  INPUTS="<configmap|secret> <namespace> <name> [<configmap|...> <namespace> <...> [...]]"\n  TARGETS="<deployment|replicaset|statefulset> <namespace> <name> [<deployment|...> <...> [...]]"\n')"

compute_hash(){
    sha256sum - | sed 's/\s.*//'
}

if [ $# != 0 ]; then
    printf 'Unexpected arguments\n%s\n' "$USAGE" >&2
    exit 1
fi

set -- $INPUTS
if [ $# = 0 ]; then
    printf '$INPUTS is not set\n%s\n' "$USAGE" >&2
    exit 1
fi
INPUT_HASHES=
while [ $# -ge 3 ]; do
    TYPE="$1"
    NS="$2"
    NAME="$3"
    shift 3

    if [ "$TYPE" = "configmap" ] || [ "$TYPE" = "secret" ]; then
        OUTPUT="$(kubectl -n "$NS" get $TYPE "$NAME" -o json)"
        if [ $? != 0 ]; then
            exit 1
        fi
        INPUT_HASHES="$INPUT_HASHES $(printf '%s\n' "$OUTPUT" | jq -S -c .data | compute_hash)"
    else
        printf 'Unsupported type %s\n' "'$TYPE'" >&2
        exit 1
    fi
done
if [ $# != 0 ]; then
    printf 'Invalid number of words in $INPUTS\n' >&2
    exit 1
fi
FINAL_HASH="$(printf '%s\n' "$INPUT_HASHES" | compute_hash)"

set -- $TARGETS
if [ $# = 0 ]; then
    printf '$TARGETS is not set\n%s\n' "$USAGE" >&2
    exit 1
fi
while [ $# -ge 3 ]; do
    TYPE="$1"
    NS="$2"
    NAME="$3"
    shift 3

    if [ "$TYPE" = "deployment" ] || [ "$TYPE" = "replicaset" ] || [ "$TYPE" = "statefulset" ]; then
        OUTPUT="$(kubectl -n "$NS" get "$TYPE" "$NAME" -o json)"
        if [ $? != 0 ]; then
            exit 1
        fi
        CURRENT_ANNOTATION="$(printf '%s\n' "$OUTPUT" | jq -r '.spec.template.metadata.annotations["hpc.nyu.edu/reload-hash"]')"
    else
        printf 'Unsupported type %s\n' "'$TYPE'" >&2
        exit 1
    fi
    if [ "$FINAL_HASH" != "$CURRENT_ANNOTATION" ]; then
        printf 'Updating hash on %s %s %s: %s -> %s\n' "$NS" "$TYPE" "$NAME" "$CURRENT_ANNOTATION" "$FINAL_HASH" >&2
        kubectl -n "$NS" patch "$TYPE" "$NAME" --type=merge -p '{"spec": {"template": {"metadata": {"annotations": {"hpc.nyu.edu/reload-hash": "'"$FINAL_HASH"'"}}}}}'
    fi
done
if [ $# != 0 ]; then
    printf 'Invalid number of words in $TARGETS\n' >&2
    exit 1
fi
