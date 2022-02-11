;; -------
;; brew tap d12frosted/emacs-plus
;; brew install emacs-plus@28 --with-xwidgets --with-native-comp
(set-language-environment "UTF-8")

;; Native comp
;; -----------
(if (and (fboundp 'native-comp-available-p)
	 (native-comp-available-p))
    (progn
      (setq comp-deferred-compilation t)
      (message "Native compilation is available"))
  (message "Native complation is *not* available"))

;; packaging system
;; ----------------
(require 'package)
;; repos
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(package-initialize)
;; use-package
(when (not (package-installed-p 'use-package))
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))

;; set PATH used by emacs useful for homebrew and go programs
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns))
  :ensure t
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-env "PATH")
  (exec-path-from-shell-copy-env "GOPATH")
  (exec-path-from-shell-copy-env "GOROOT"))

;; GUI Settings
;; -----------------
;; Disable menus
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(require 'display-line-numbers)
(column-number-mode)
(global-display-line-numbers-mode)
;; Prevent window split
(setq split-height-threshold 1200)
(setq split-width-threshold 2000)
;; Theme
(use-package doom-themes
  :ensure t
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
	doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-Iosvkem t)
  ;; Enable custom neotree theme (all-the-icons must be installed!)
  (doom-themes-neotree-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))
;; Font
(set-face-attribute 'default nil :font "SpaceMono NF" :height 120)
;; Modeline
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 18)
  (setq doom-modeline-hud t)
  (setq doom-modeline-buffer-file-name-style 'relative-from-project)
  (setq doom-modeline-indent-info t))
(display-battery-mode 1)

;; Projectile
;; ----------
(use-package projectile
  :ensure t
  :init
  (projectile-mode +1))
(use-package helm-projectile
  :ensure t)
;; Evil mode
;; ---------
(use-package evil
  :ensure t
  :init
  (setq evil-search-module 'evil-search)
  (setq evil-ex-complete-emacs-commands nil)
  (setq evil-vsplit-window-right t)
  (setq evil-split-window-below t)
  (setq evil-shift-round nil)
  (setq evil-want-C-u-scroll t)
  :config
  (evil-mode)
  (define-key evil-normal-state-map (kbd ", w") 'evil-window-vsplit)
  (define-key evil-normal-state-map (kbd "C-h") 'evil-window-left)
  (define-key evil-normal-state-map (kbd "C-j") 'evil-window-down)
  (define-key evil-normal-state-map (kbd "C-k") 'evil-window-up)
  (define-key evil-normal-state-map (kbd "C-l") 'evil-window-right)

  (define-key evil-normal-state-map (kbd "C-S-h") 'evil-window-decrease-width)
  (define-key evil-normal-state-map (kbd "C-S-j") 'evil-window-decrease-height)
  (define-key evil-normal-state-map (kbd "C-S-k") 'evil-window-increase-height)
  (define-key evil-normal-state-map (kbd "C-S-l") 'evil-window-increase-width)

  (define-key evil-normal-state-map (kbd "SPC p p") 'helm-projectile-switch-project)
  (define-key evil-normal-state-map (kbd "SPC p f") 'helm-projectile-find-file))

;; Go
;; --
(use-package go-mode
  :ensure t
  :hook (
	 (go-mode . flycheck-mode)
	 (before-save . lsp-format-buffer)
	 (before-save . lsp-organize-imports))
  :config
  ;; golangci-lint (linter)
  (use-package flycheck-golangci-lint
    ;; install binary: golangci-lint
    :ensure t
    :hook (go-mode . flycheck-golangci-lint-setup))

  ;; go templates
  (add-to-list 'auto-mode-alist '("\\.html.tmpl\\'" . web-mode))
  (setq web-mode-engines-alist
	'(("go" . "\\.html.tmpl\\'"))))

;; Web / Javasscript / Typescript (+ react suport)
;; -----------------------------------------
(use-package typescript-mode
  :ensure t
  :hook
  (typescript-mode . (lambda()
		       (setq flycheck-checker 'javascript-eslint)))
  (typescript-mode . lsp)
  :custom
  (typescript-indent-level 2))
(use-package web-mode
  :ensure t
  :init
  (define-derived-mode tsx-mode web-mode "TSX mode")
  :after (flycheck)
  :hook ((web-mode . lsp)
	 (tsx-mode . (lambda () (flycheck-add-next-checker 'lsp-ui 'javascript-eslint))))
  :mode (("\\.html\\'" . web-mode)
	 ("\\.html\\.eex\\'" . web-mode)
	 ("\\.html\\.tera\\'" . web-mode)
	 ("\\.gotmpl\\'" . web-mode)
	 ("\\.svelte\\'" . web-mode)
	 ("\\.tsx\\'" . tsx-mode))
  :config
  (flycheck-add-mode 'javascript-eslint 'tsx-mode)
  (setq web-mode-enable-auto-indentation nil)
  ;; 2 space indent
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2)
  (setq web-mode-script-padding 2)
  (setq web-mode-block-padding 2)
  (setq web-mode-style-padding 2)
  (setq web-mode-enable-auto-pairing t)
  (setq web-mode-enable-auto-closing t)
  (setq web-mode-enable-current-element-highlight t))

(use-package scss-mode
  :ensure t)

;; LSP
;; ---
(use-package lsp-mode
  :hook (
	 (go-mode . lsp-deferred))
  :commands (lsp lsp-deferred)
  :config
  ;; prefer flycheck over flymake
  (setq lsp-diagnostics-provider :none)
  (setq lsp-prefer-flymake nil)
  (setq lsp-eslint-auto-fix-on-save t)
  (setq lsp-eslint-enable t))
(use-package company
  :ensure t
  :bind (:map company-active-map
	      ("C-n" . company-select-next)
	      ("C-p" . company-select-previous))
  :config
  (setq company-idle-delay 0.3)
  (global-company-mode t))
;; Flycheck
(use-package flycheck
  :ensure t
  :config
  (add-hook 'typescript-mode-hook 'flycheck-mode)
  (flycheck-add-mode 'javascript-eslint 'web-mode))
(use-package flycheck-golangci-lint
  :ensure t
  :hook (go-mode . flycheck-golangci-lint-setup))
(use-package lsp-ui
  :ensure t
  :config
  (setq lsp-ui-sideline-show-diagnostics t)
  (setq lsp-ui-doc-enable t))


;; cleanup unused buffers with midnight mode
(require 'midnight)
(setq clean-buffer-list-delay-general 1)

;; Dashboard
(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-banner-logo-title "Definitely not Emacs")
  (setq dashboard-startup-banner "logo")
  (setq dashboard-center-content t)
  (setq dashboard-items '((recents  . 5)
                        (projects . 5)
                        (agenda . 5)
                        (bookmarks . 5)
                        (registers . 5))))

;; wakatime
(use-package wakatime-mode
  :ensure t
  :config
  (global-wakatime-mode))


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(dashboard helm-projectile projectile prettier-eslint rsjx-mode prettier flycheck-golangci-lint web-mode go-mode lsp-mode company-mode company doom-modeline doom-themes use-package)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
