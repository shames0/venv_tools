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

function rmvenv() {
    if [[ ! -f "$PWD/.venv" ]]; then
        echo "no .venv file in this directory" 1>&2
        return
    fi

    VENV_ID=$(<.venv)
    # safety check -- should be a full-length uuid
    if [[ ! $VENV_ID =~ ^[0-9A-G\-]{36}$ ]]; then
        echo ".venv file doesn't have a uuid" 1>&2
    fi

    # paranoia -- shouldn't have changed
    if [[ ! $VENV_HOME =~ ^${HOME}/[.]venv ]]; then
        echo "\$VENV_HOME isn't valid: $VENV_HOME" 1>&2
    fi

    # deactivate the virtual environment
    type deactivate > /dev/null \
        && deactivate

    [[ $VENV_ROOT ]] \
        && unset VENV_ROOT

    # remove the configuration files
    VENV_PATH="$VENV_HOME/$VENV_ID"
    rm -fr $VENV_PATH
    rm .venv
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
            VENV_PATH="$VENV_HOME/$(<$CUR_PATH/.venv)"
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
if ! (($precmd_functions[(Ie)$include_func])); then
    precmd_functions=( ${precmd_functions} findvenv )
fi

