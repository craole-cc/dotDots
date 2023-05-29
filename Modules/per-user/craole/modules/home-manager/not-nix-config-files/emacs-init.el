(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(LaTeX-electric-left-right-brace t)
 '(LaTeX-mode-hook '())
 '(TeX-auto-save t)
 '(TeX-electric-math '("\\(" . "\\)"))
 '(TeX-electric-sub-and-superscript t)
 '(TeX-source-correlate-mode t)
 '(TeX-source-correlate-start-server t)
 '(TeX-view-program-selection '((output-pdf "Zathura")))
 '(custom-enabled-themes '(modus-operandi))
 '(default-input-method "german-postfix")
 '(electric-pair-mode t)
 '(elpy-rpc-virtualenv-path 'system)
 '(global-prettify-symbols-mode t)
 '(indent-tabs-mode nil)
 '(inhibit-startup-screen t)
 '(interprogram-cut-function 'wl-copy t)
 '(interprogram-paste-function 'wl-paste t)
 '(mail-envelope-from 'header)
 '(mail-host-address "lan")
 '(mail-specify-envelope-from t)
 '(menu-bar-mode nil)
 '(message-kill-buffer-on-exit t)
 '(message-send-mail-function 'message-send-mail-with-sendmail)
 '(message-sendmail-envelope-from 'header)
 '(mml-secure-openpgp-sign-with-sender t)
 '(modus-themes-bold-constructs t)
 '(modus-themes-inhibit-reload nil)
 '(modus-themes-italic-constructs t)
 '(notmuch-saved-searches
   '((:name "inbox" :query "tag:inbox not tag:flagged not tag:passed" :key "i")
     (:name "unread" :query "tag:unread" :key "u")
     (:name "passed" :query "tag:passed" :key "p")
     (:name "flagged" :query "tag:flagged" :key "f")
     (:name "sent" :query "tag:sent" :key "t")
     (:name "drafts" :query "tag:draft" :key "d")
     (:name "all mail" :query "*" :key "a")))
 '(org-export-with-smart-quotes t)
 '(prettify-symbols-unprettify-at-point 'right-edge)
 '(read-buffer-completion-ignore-case t)
 '(read-file-name-completion-ignore-case t)
 '(reftex-plug-into-AUCTeX t)
 '(send-mail-function 'sendmail-send-it)
 '(sendmail-program "msmtp")
 '(shr-cookie-policy nil)
 '(shr-inhibit-images t)
 '(shr-use-colors nil)
 '(tool-bar-mode nil))

;; turn on auto fill in all modes
(setq-default auto-fill-function 'do-auto-fill)

;; swap backspace and C-h
(define-key key-translation-map [?\C-h] [?\C-?])
(define-key key-translation-map [?\C-?] [?\C-h])
(define-key key-translation-map [?\M-h] [?\M-\d])
(define-key key-translation-map [?\M-\d] [?\M-h])

;; swap backspace and C-h ends here

;; auctex related settings
(use-package tex
  :ensure auctex
  :config
  (eval-after-load "LaTeX"
    '(progn
       (add-to-list 'tex--prettify-symbols-alist '("\\colon" . ?:)
       (put 'LaTeX-narrow-to-environment 'disabled nil)
       (electric-pair-local-mode -1))))
  (add-hook 'TeX-after-compilation-finished-functions
            #'TeX-revert-document-buffer)
  (add-hook 'LaTeX-mode-hook 'auto-fill-mode)
  (add-hook 'LaTeX-mode-hook 'TeX-source-correlate-mode)
  (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
  (add-hook 'LaTeX-mode-hook #'LaTeX-math-mode))

;;; disable electric pairs in minibuffer
(defun my-electric-pair-inhibit (char)
  (if (not (minibufferp))
      (electric-pair-default-inhibit char)
    (minibufferp)))

(setq electric-pair-inhibit-predicate #'my-electric-pair-inhibit)

;; auctex related settings ends here

;; sign all outgoing emails by default
(add-hook 'message-setup-hook 'mml-secure-message-sign)

;; zh-cn input engine
(use-package pyim
  :ensure pyim-basedict
  :init
  (pyim-basedict-enable))

;; zh-cn input engine ends here

;; open files in dired mode
(defun dired-open-file ()
  "In dired, open the file named on this line."
  (interactive)
  (let* ((file (dired-get-filename nil t)))
    (call-process "xdg-open" nil 0 nil file)))
(eval-after-load "dired" '(progn
  (define-key dired-mode-map (kbd "C-o") 'dired-open-file)))

;; open files in dired mode ends here

;; notmuch mail reader config
(use-package notmuch
  :config
  (setq notmuch-always-prompt-for-sender nil)
  (setq notmuch-fcc-dirs "apvc.uk/Sent/")
  (define-key notmuch-search-mode-map "d"
	      (lambda (&optional beg end)
		"mark message as passed"
		(interactive (notmuch-interactive-region))
		(notmuch-search-tag (list "+passed") beg end)
		(notmuch-search-next-thread)))
  (define-key notmuch-search-mode-map "f"
	      (lambda (&optional beg end)
		"mark message as flagged"
		(interactive (notmuch-interactive-region))
		(notmuch-search-tag (list "+flagged") beg end)
		(notmuch-search-next-thread))))

;; notmuch mail reader config ends here

;; wayland paste
;; credit: yorickvP on Github
(setq wl-copy-process nil)

(defun wl-copy (text)
  (setq wl-copy-process
	(make-process
	 :name "wl-copy"
         :buffer nil
         :command '("wl-copy" "-f" "-n")
         :connection-type 'pipe))
  (process-send-string wl-copy-process text)
  (process-send-eof wl-copy-process))

(defun wl-paste ()
  (if (and wl-copy-process (process-live-p wl-copy-process))
      nil ; should return nil if we're the current paste owner
    (shell-command-to-string "wl-paste -n | tr -d \r")))

;; wayland paste ends here
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
