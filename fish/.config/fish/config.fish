# Fish configuration for the Catppuccin Mocha demo.
# Keeps the CachyOS defaults (aliases, fastfetch greeting, done notifications)
# and then layers Starship, zoxide, and a few convenience aliases on top.

if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

if not functions -q fish_greeting
    function fish_greeting
        if type -q fastfetch
            fastfetch
        end
    end
end

# Prompt and smart cd
if type -q starship
    starship init fish | source
end

if type -q zoxide
    zoxide init fish | source
end

# Editor and pager
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx SUDO_EDITOR nvim
set -gx BAT_THEME "Catppuccin Mocha"
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -gx PAGER less
set -gx LESS "-R"

# Catppuccin-ish fzf colors
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8'

# Paths
fish_add_path $HOME/.local/bin $HOME/.cargo/bin

# Aliases (these win over the CachyOS defaults because they load later)
alias ls 'eza --icons --group-directories-first'
alias ll 'eza -al --icons --group-directories-first'
alias la 'eza -a --icons --group-directories-first'
alias lt 'eza --tree --level=2 --icons'
alias cat 'bat --style=plain'
alias grep 'rg'
alias find 'fd'
alias vim 'nvim'
alias vi 'nvim'
alias ff 'fastfetch'
alias bt 'btop'
alias tm 'tmux'
alias lg 'lazygit'
alias .. 'cd ..'
alias ... 'cd ../..'
alias reload 'source ~/.config/fish/config.fish'
