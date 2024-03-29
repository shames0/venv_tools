VENV_HOME="$HOME/.local/share/virtualenvs"

function activate_virtualenv() {
    VENV_PATH=$1
    source "$VENV_PATH/bin/activate"
    export WORKON_HOME=$VENV_PATH
}

function can_deactivate() {
    type deactivate &> /dev/null
}

function mkvenv() {
    if [[ -f "$PWD/.venv" ]]; then
        echo ".venv file exists, delete it first" 1>&2
        return
    fi

    folder_name=$(basename $PWD)
    VENV_ID=$(echo "${folder_name}-$(uuidgen)" | tee .venv)

    # create the new venv and switch to it
    VENV_PATH="$VENV_HOME/$VENV_ID"
    mkdir -p $VENV_PATH
    VENV_ROOT_NAME=$(basename $PWD)
    echo "creating virtual environment..."
    python3 -m venv --prompt $VENV_ROOT_NAME $VENV_PATH
    activate_virtualenv $VENV_PATH

    if [[ -f "$PWD/Pipfile" ]]; then
        pip install pipenv
        pipenv install
    fi
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
    if [[ ! $VENV_ID =~ [0-9A-G\-]{36}$ ]]; then
        echo ".venv file doesn't have a uuid" 1>&2
        return
    fi

    # paranoia -- shouldn't have changed
    if [[ ! $VENV_HOME =~ ^${HOME}/ ]]; then
        echo "\$VENV_HOME isn't valid: $VENV_HOME" 1>&2
        return
    fi

    # deactivate the virtual environment
    can_deactivate && deactivate

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
        can_deactivate && deactivate
        unset VENV_ROOT
    fi

    # new tmux/zellij/vimterm panes should get the environment too
    # (this might be a band-aid for something I should fix at a different level)
    if [[ $VENV_ROOT ]] \
    && ! can_deactivate; then
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
                activate_virtualenv $VENV_PATH
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

