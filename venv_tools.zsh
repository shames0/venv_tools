VENV_HOME="$HOME/.venv"

function mkvenv() {
    if [[ -f "$PWD/.venv" ]]; then
        echo ".venv file exists, delete it first" 1>&2
        return
    fi

    VENV_ID=$(uuidgen | tee .venv)

    # create the new venv and switch to it
    VENV_PATH="$VENV_HOME/$VENV_ID"
    mkdir -p $VENV_PATH
    VENV_ROOT_NAME=$(basename $PWD)
    echo "creating virtual environment..."
    python3 -m venv --prompt $VENV_ROOT_NAME $VENV_PATH
    source "$VENV_PATH/bin/activate"
    # pip install -r requirements.txt ... maybe?

    VENV_ROOT=$PWD
    export VENV_ROOT
}

function findvenv() {
    CUR_PATH=$PWD

    # if we leave a virtaul environment, make sure it gets de-activated
    if [[ $CUR_PATH ]] \
    && [[ $VENV_ROOT ]] \
    && [[ $CUR_PATH != $VENV_ROOT* ]]; then
        deactivate
        unset VENV_ROOT
    fi

    # watch for .venv files in cwd and activate them when found
    while [[ ! $VENV_ROOT ]] \
       && [[ $CUR_PATH != '/' ]] \
       && [[ $CUR_PATH != '' ]]; do
        if [[ -f "$CUR_PATH/.venv" ]]; then
            VENV_PATH="$VENV_HOME/$(cat $CUR_PATH/.venv)"
            if [[ $VENV_PATH == $VENV_HOME ]] \
            || [[ ! -d $VENV_PATH ]] \
            || [[ ! -f "$VENV_PATH/bin/activate" ]]; then
                echo "found stale .venv file: $CUR_PATH/.venv" 1>&2
                return
            else
                source "$VENV_PATH/bin/activate"
                VENV_ROOT=$CUR_PATH

                export VENV_ROOT
            fi
            break;
        fi
        CUR_PATH=$(dirname $CUR_PATH)
    done
}

# register findvenv as one of the chpwd functions if it's not already there
include_func="findvenv"
if ! (($chpwd_functions[(Ie)$include_func])); then
    chpwd_functions=( ${chpwd_functions} findvenv )
fi

