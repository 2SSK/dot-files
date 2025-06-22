;; init.el - Cleaned Emacs Configuration

;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t)

;; Minimal UI
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t)
(global-hl-line-mode t)
(global-display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)
(setq ring-bell-function 'ignore)

;; Font
(set-frame-font "JetBrainsMono Nerd Font 14" nil t)

;; Gruvbox Theme
(use-package gruvbox-theme
  :config
  (load-theme 'gruvbox-dark-medium t))

;; Doom modeline
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))

(use-package nerd-icons)

;; Environment variables
(use-package envrc
  :hook (after-init . envrc-global-mode))

;; Which-key
(use-package which-key
  :demand t
  :config
  (which-key-mode)
  (which-key-setup-minibuffer))

;; Evil mode
(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-Y-yank-to-eol t
        evil-split-window-below t
        evil-vsplit-window-right t
        evil-respect-visual-line-mode t
        evil-undo-system 'undo-tree)
  :config
  (evil-mode 1))

;; General for leader key mappings
(use-package general
  :config
  (general-evil-setup t)

  (general-create-definer my/leader-keys
    :keymaps '(normal visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")

  (my/leader-keys
    ;; Clear search highlight
    "nh" '(evil-ex-nohighlight :which-key "no highlight")

    ;; File operations
    "w"  '(save-buffer :which-key "save file")
    "q"  '(kill-this-buffer :which-key "quit buffer")
    "Q"  '(save-buffers-kill-terminal :which-key "quit Emacs")

    ;; Window management
    "sv" '(evil-window-vsplit :which-key "vertical split")
    "sh" '(evil-window-split :which-key "horizontal split")
    "se" '(balance-windows :which-key "equalize splits")
    "sx" '(evil-window-delete :which-key "close window")

    ;; Tabs
    "tn" '(tab-new :which-key "new tab")
    "tc" '(tab-close :which-key "close tab")
    "tl" '(tab-next :which-key "next tab")
    "th" '(tab-previous :which-key "previous tab")

    ;; Project
    "pf" '(projectile-find-file :which-key "find file")
    "pp" '(projectile-switch-project :which-key "switch project")

    ;; Git
    "gs" '(magit-status :which-key "Git status")

    ;; Terminal
    "ot" '(vterm :which-key "Open terminal")

    ;; Docker & Kubernetes
    "od" '(docker :which-key "Docker")
    "ok" '(kubernetes-overview :which-key "Kubernetes")

    ;; File Explorer
    "e"  '(dired :which-key "File Explorer"))

  ;; Insert mode 'jk' to escape
  (general-define-key
   :states '(insert)
   "j" (general-key-dispatch 'self-insert-command
         :timeout 0.25
         "k" 'evil-normal-state))

  ;; Window resizing
  (general-define-key
   :states '(normal visual)
   "C-c <up>"    (lambda () (interactive) (enlarge-window 3))
   "C-c <down>"  (lambda () (interactive) (enlarge-window -3))
   "C-c <left>"  (lambda () (interactive) (enlarge-window-horizontally -3))
   "C-c <right>" (lambda () (interactive) (enlarge-window-horizontally 3))))

;; LSP Mode with manual language server installation
(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :hook ((prog-mode . lsp-deferred)
         (lsp-mode . lsp-enable-which-key-integration))
  :custom
  (read-process-output-max (* 1024 1024))
  (lsp-completion-provider :none)
  (lsp-keymap-prefix "C-c")
  (lsp-diagnostics-provider :flycheck)
  (lsp-auto-guess-root t)
  (lsp-enable-snippet t)
  (lsp-enable-file-watchers nil))

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-doc-position 'bottom)
  (lsp-ui-doc-delay 0.5)
  (lsp-ui-sideline-enable t))

;; Flycheck for linting
(use-package flycheck
  :hook (lsp-mode . flycheck-mode)
  :bind (:map flycheck-mode-map
              ("M-n" . flycheck-next-error)
              ("M-p" . flycheck-previous-error))
  :custom
  (flycheck-display-errors-delay 0.3))

;; Corfu for completion
(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0)
  (corfu-popupinfo-delay '(0.5 . 0.2))
  (corfu-preview-current 'insert)
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)
  :bind (:map corfu-map
              ("TAB"        . corfu-next)
              ([tab]        . corfu-next)
              ("S-TAB"      . corfu-previous)
              ([backtab]    . corfu-previous)
              ("RET"        . corfu-insert))
  :init
  (global-corfu-mode)
  (corfu-history-mode))

;; Nerd icons in Corfu
(use-package nerd-icons-corfu
  :after corfu
  :init (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;; Yasnippet for snippets
(use-package yasnippet
  :init (yas-global-mode 1))

;; Auto formatting
(use-package apheleia
  :hook (prog-mode . apheleia-mode)
  :config
  (setf (alist-get 'prettier apheleia-formatters)
        '("prettier" "--stdin-filepath" filepath)))

;; Git integration
(use-package magit
  :commands magit-status)

;; Project management
(use-package projectile
  :demand t
  :config (projectile-mode))

;; Terminal inside Emacs
(use-package vterm
  :commands vterm)

;; Docker integration
(use-package docker
  :commands docker)

(use-package dockerfile-mode
  :mode "Dockerfile\\'")

;; Kubernetes integration
(use-package kubernetes
  :commands kubernetes-overview)

(use-package kubernetes-evil
  :after kubernetes)

;; Dashboard landing page
(use-package dashboard
  :init
  (setq dashboard-startup-banner 'logo)
  (setq dashboard-center-content t)
  (setq dashboard-items '((recents  . 5)
                          (projects . 5)))
  :config
  (dashboard-setup-startup-hook))

(setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))

;; Customization leftovers
(custom-set-variables
 '(package-selected-packages nil))
(custom-set-faces)

;; Suppress byte compile warnings
(setq byte-compile-warnings '(not obsolete noruntime unresolved))

;; Vim motions to navigate windows
(general-define-key
 :states '(normal insert emacs)
 :keymaps 'override
 "C-h" 'evil-window-left
 "C-l" 'evil-window-right
 "C-j" 'evil-window-down
 "C-k" 'evil-window-up)
(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0)
  (corfu-popupinfo-delay '(0.5 . 0.2))
  (corfu-preview-current 'insert)
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)
  :bind (:map corfu-map
              ("C-j" . corfu-next)
              ("C-k" . corfu-previous)
              ("RET" . corfu-insert))
  :init
  (global-corfu-mode)
  (corfu-history-mode))

(use-package vterm
  :commands vterm
  :hook (vterm-mode . evil-emacs-state))
