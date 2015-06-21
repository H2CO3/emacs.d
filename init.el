;;; init.el -- my Emacs config file

;;; Commentary:
;;; You may or may not like this. Choose features at will.

;;; Code:
(add-to-list 'load-path "~/.emacs.d/plugins")

;; import MELPA repository
(when (>= emacs-major-version 24)
  (require 'package)
  (package-initialize)
  (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
)

;; import general-purpose libraries
(require 'linum)
(require 'flycheck)
(require 'pabbrev)
(require 'vvb-mode)
(require 'undo-tree)
(require 'ido)

;; activate flycheck Sparkling mode
;; configure it so that it only checks upn saving
(require 'sparkling-flycheck)
(setq flycheck-check-syntax-automatically '(mode-enabled save))

;; Import non-default language modes
(require 'sparkling-mode)
(require 'lua-mode)
(require 'swift-mode)
(require 'lilypond-mode)

;; Objective-C(++) mode
(add-to-list 'auto-mode-alist '("\\.mm\\'" . objc-mode))
;; LilyPond mode
(add-to-list 'auto-mode-alist '("\\.ly\\'" . LilyPond-mode))

;; set default color theme
(require 'color-theme)
(color-theme-initialize)
(color-theme-ld-dark)

;; UTF-8 everywhere!
(prefer-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(setq locale-coding-system 'utf-8)

;; activate linum library (line numbers)
(global-linum-mode 1)

;; activate ido-mode
(ido-mode t)

;; highlight current (active) line
(global-hl-line-mode 1)
(set-face-background 'hl-line "#555")

;; save minibuffer history (don't wanna retype all those compiler invocations)
(savehist-mode 1)
(setq history-length 1000)

;; allow opening recent files
(recentf-mode 1)
(setq recentf-max-saved-items 100)

;; if I mark stuff, I want to overwrite it on insert
(delete-selection-mode 1)

;; Treat undo properly - as a tree
(global-undo-tree-mode 1)

;; I don't want backup '~' and autosave '#' files to clutter the current directory
(setq backup-directory-alist
  `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
  `((".*" ,temporary-file-directory t)))

;; give more spare memory to GC (in exchange for speed, allegedly)
(setq gc-cons-threshold 20000000)

;; activate and set up auto completion view PredictiveAbbreviations mode
(global-pabbrev-mode t)
(require 'popup)
(defun pabbrevx-suggestions-goto-buffer (suggestions)
	(let* ((candidates (mapcar 'car suggestions))
				 (bounds (pabbrev-bounds-of-thing-at-point))
				 (selection (popup-menu* candidates
																 :point (car bounds)
																 :scroll-bar t)))
		(when selection
			;; modified version of pabbrev-suggestions-insert
			(let ((point))
				(save-excursion
					(progn
						(delete-region (car bounds) (cdr bounds))
						(insert selection)
						(setq point (point))))
				(if point
						(goto-char point))
				;; need to nil this so pabbrev-expand-maybe-full won't try
				;; pabbrev expansion if user hits another TAB after ac aborts
				(setq pabbrev-last-expansion-suggestions nil)
			)
		)
	)
)

(fset 'pabbrev-suggestions-goto-buffer 'pabbrevx-suggestions-goto-buffer)

;; fix stupid keyboard settings on OS X
(set-keyboard-coding-system nil)

;; indent using tabs...
(setq-default c-basic-offset   4
              tab-width        4
              indent-tabs-mode t
	      backward-delete-function (quote backward-delete-char))

;; ...but align with spaces!
(defadvice align-regexp (around align-regexp-with-spaces activate)
  "Make 'align-regexp' use spaces instead of tabs."
  (let ((indent-tabs-mode nil))
	    ad-do-it))

;; Linux coding style for (Objective-)C(++)
(setq c-default-style "linux" c-basic-offset 4)

;; scroll only one line when going out of screen
(setq scroll-conservatively most-positive-fixnum)

;; when I say 'backspace', I mean 'backtab'
(setq backward-delete-char-untabify-method nil)

;; newline always indents
(define-key global-map (kbd "RET") 'newline-and-indent)

;; comment code block
(global-set-key (kbd "C-c c") 'comment-region)
;; uncomment code block
(global-set-key (kbd "C-c u") 'uncomment-region)
;; add cursors to each line of a region
(global-set-key (kbd "C-x C-l") 'mc/edit-lines)
;; expand-region
(global-set-key (kbd "M-=") 'er/expand-region)
(global-set-key (kbd "M-_") 'er/contract-region)
;; mark-multiple
(global-set-key (kbd "M-+") 'mc/mark-next-like-this)

;; copy entire line without moving cursor
(fset 'my-copy-line-from-indentation
  "\C-[m\C-@\C-e\C-[w")

(global-set-key
  (kbd "C-c C-k")
  (lambda (&optional arg)
	(interactive "p")
	(save-excursion
	  (execute-kbd-macro (symbol-function 'my-copy-line-from-indentation)))))

;; trailing WS sucks
(add-hook 'c-mode-hook (lambda ()
  (add-to-list 'write-file-functions 'delete-trailing-whitespace)))
(add-hook 'c++-mode-hook (lambda ()
  (add-to-list 'write-file-functions 'delete-trailing-whitespace)))
(add-hook 'sparkling-mode-hook (lambda ()
  (add-to-list 'write-file-functions 'delete-trailing-whitespace)))
(add-hook 'js-mode-hook (lambda ()
  (add-to-list 'write-file-functions 'delete-trailing-whitespace)))

;; more convenient than M-g g
(global-set-key "\C-x\C-g" 'goto-line)

;; I use the Terminal in full screen, so this is nice to have
(display-time)

;; Prevent Flycheck from whining about C++11. It's a standard, c'mon!
(add-hook 'c-mode-hook (lambda () (setq flycheck-clang-language-standard "c99")))
(add-hook 'c++-mode-hook (lambda () (setq flycheck-clang-language-standard "c++11")))

;; enable Flycheck
(add-hook 'after-init-hook #'global-flycheck-mode)

;; this is just cool
(defun toggle-frame-split ()
  "If the frame is split vertically, split it horizontally or vice versa.
Assumes that the frame is only split into two."
  (interactive)
  (unless (= (length (window-list)) 2) (error "Can only toggle a frame split in two"))
  (let ((split-vertically-p (window-combined-p)))
    (delete-window) ; closes current window
    (if split-vertically-p
	(split-window-horizontally)
      (split-window-vertically)) ; gives us a split with the other window twice
    (switch-to-buffer nil) ; restore the original window in this part of the frame
  )
)

(global-set-key (kbd "C-x C-h") 'toggle-frame-split)

;; I don't want M-backspace to put the text in the kill ring.
;; Just delete it!
(defun delete-word-no-kill (arg)
  "Delete characters backward until encountering the beginning of a word.
With argument ARG, do this that many times."
  (interactive "p")
  (delete-region (point) (progn (backward-word arg) (point))))

(global-set-key (kbd "M-DEL") 'delete-word-no-kill)

;; enable parenthesis-match highlighting
(require 'highlight-parentheses)

(define-globalized-minor-mode global-highlight-parentheses-mode highlight-parentheses-mode
  (lambda nil (highlight-parentheses-mode t)))

(global-highlight-parentheses-mode t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(c-offsets-alist (quote ((arglist-close . c-lineup-close-paren))))
 '(ido-cannot-complete-command (quote ido-next-match))
 '(ido-case-fold t)
 '(ido-enable-flex-matching t)
 '(reb-re-syntax (quote read))
 '(send-mail-function (quote mailclient-send-it))
 '(show-paren-mode t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ido-first-match ((t (:inherit font-lock-keyword-face :weight bold))))
 '(ido-incomplete-regexp ((t (:inherit font-lock-default-face)))))

;; Do not indent namespaces
(c-set-offset 'innamespace 0)

;; Fix wrong C++11 lambda-as-argument indentation
(defadvice c-lineup-arglist (around my activate)
  "Improve indentation of continued C++11 lambda function opened as argument."
  (setq ad-return-value
		(if (and (equal major-mode 'c++-mode)
				 (ignore-errors
				   (save-excursion
					 (goto-char (c-langelem-pos langelem))
					 ;; Detect "[...](" or "[...]{". preceded by "," or "(",
					 ;;   and with unclosed brace.
					 (looking-at ".*[(,][ \t]*\\[[^]]*\\][ \t]*[({][^}]*$"))))
			0                           ; no additional indent
		  ad-do-it)))                   ; default behavior


;; y/n is good enough, I don't want to type full words
(defalias 'yes-or-no-p 'y-or-n-p)

;;; init.el ends here
