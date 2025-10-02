# RemoteClipboard
Bunch of scripts to make life easier when manage remote servers

One day I found i missed a chance to have simple copy from tmux and nano on remote server to local clipboard, then I created this.

Put *remote-copy.sh* on your remote machine. It works like an any other tool to paste from console application using standard input 
and supports two ways to forward a content:
* Unix socket, which requires a local part
* OSC52-compatible terminal (such as Kitty, iTerm2, etc.)

Since I personally prefer to use Terminal.app, mosh and many other things that has no OSC52 support, I created a second part -
*remote-clipboard.sh*, which could be run locally on machines with macOS, WSL, Wayland, X11.

## .nanorc

```
set mouse
bind ^Y "{execute}|/home/user/remote-copy.sh{enter}{undo}" main
```

## .tmux.conf

```
set -g set-clipboard on
set -as terminal-features  ',*:clipboard'
set -as terminal-overrides ',*:Ms=\E]52;c;%p1%s\7'
set -s mouse on

set -g @copier "/home/user/remote-copy.sh"

bind -T copy-mode-vi y                 send -X copy-pipe-and-cancel "#{@copier}"
bind -T copy-mode    M-w               send -X copy-pipe-and-cancel "#{@copier}"
bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "#{@copier}"
bind -T copy-mode    MouseDragEnd1Pane send -X copy-pipe-and-cancel "#{@copier}"
```