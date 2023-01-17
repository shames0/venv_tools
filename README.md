# venv_tools

Easier management of python virtual environments using `python3 -m venv` in a zsh environment.

## Synopsis

    cd my-repo/
    mkvenv      # a virtual environment for this folder is created and stored in ~/.venv/${UUID}
                # a .venv file is created that contains $UUID so the virtual env can be found later
                # the new virtual env is automatically activated

    pip install -r requirements.txt     # requirements are installed to the virtual environment

    cd ../      # the virtual environment is automatically deactivated

    cd my-repo/  # the virtual environment is automatically re-activated

## Description

Exposes two functions `mkvenv` and `findvenv`. The latter is added to zsh's list of `chpwd_functions` so that it is called whenever the working directory changes.


**`mkvenv`**

allows the user to create a python virtual environment in their current working directory. It stores all the necessary virtual environment files in a subfolder of `~/.venv/`, and places the new of that subfolder in the current directories' `.venv` file.


**`findvenv`**

if a virtual environment hasn't already been activated by either `mkvenv` or `findvenv`, this function will search for a `.venv` in the current working directory path or one of its parent directories. If a `.venv` file is located, the indicated virtual environment in that file will be activated.

if a virtual environment has already been activated by either `mkvenv` or `findvenv`, and the current working directory path no longer includes the path that contained the last found `.venv` file, the virtual environment will be de-activated.

## How to use / "Install"

source the `venv_tools.zsh` file in your `~/.zshrc`, `~/.zprofile`, or `~/.zlogin` (depending on your preference)
