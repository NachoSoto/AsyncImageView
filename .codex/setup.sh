#!/usr/bin/env bash
set -euo pipefail

# Helper that evals the brew environment and persists it for future shells.
set_brew_env() {
    local brew_bin="$1"
    eval "$("${brew_bin}" shellenv)"

    local snippet="eval \"\$(${brew_bin} shellenv)\""
    for profile in "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc"; do
        if [ ! -e "${profile}" ]; then
            touch "${profile}"
        fi
        if ! grep -Fq "${snippet}" "${profile}"; then
            printf '\n%s\n' "${snippet}" >> "${profile}"
        fi
    done
}

BREW_BIN=""
for candidate in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "${candidate}" ]; then
        BREW_BIN="${candidate}"
        break
    fi
done

if [ -n "${BREW_BIN}" ]; then
    set_brew_env "${BREW_BIN}"
fi

# Install Homebrew on macOS or Linux if missing
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    for candidate in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "${candidate}" ]; then
            BREW_BIN="${candidate}"
            break
        fi
    done

    if [ -n "${BREW_BIN}" ]; then
        set_brew_env "${BREW_BIN}"
    fi
fi

if [ -z "${BREW_BIN}" ] && command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
fi

if [ -n "${BREW_BIN}" ]; then
    set_brew_env "${BREW_BIN}"
fi

# Install dependencies via Homebrew
install_with_brew() {
    local formula="$1"
    if ! brew list --formula | grep -q "^${formula}$"; then
        brew install "${formula}"
    fi
}

install_with_brew swiftlint
install_with_brew swiftformat

echo "Setup complete."
