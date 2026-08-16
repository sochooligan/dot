;; /usr/share/emacs/site-lisp/default.el

;;; default.el - loaded after ".emacs" on startup
;;;
;;; Setting `inhibit-default-init' non-nil in "~/.emacs"
;;; prevents loading of this file.  Also the "-q" option to emacs
;;; prevents both "~/.emacs" and this file from being loaded at startup.

(setq-default smime-CA-directory "/etc/ssl/certs")

;; 2024.11.23
(global-display-line-numbers-mode 1)  ;; 全局开启行号
(column-number-mode t)  ;; 显示列号

(winner-mode t)  ;; 记录历史窗口，可以来回跳转
(repeat-mode t)  ;; 命令重复出入，简化输入
(menu-bar-mode -1) ;; without menu bar

;; 定义函数：关闭当前缓冲区
(defun kill-current-buffer() 
  (interactive)
  (kill-buffer (current-buffer)))

;; 按键 C-x k 原来调用的是kill-buffer命令, 需要交互；
;;    将其修改为调用自定义的kill-current-buffer,
;;    不询问直接关闭当前文件；
(global-set-key (kbd "C-x k") 'kill-current-buffer)

;; when closed without saving, changed content will generate # file
(setq auto-save-default nil)
;; 保存文件时，我依然会生成一个包含初始内容的 ~ file

(setq scroll-step 1)

;; eshell use short pash
;; CAR: Contents of the Address part of Register number
;; CDR: Contents of the Decrement part of Register number
(setq eshell-prompt-function
      (lambda()
	(concat
	 (car (last (split-string (eshell/pwd) "/")))	 
	 " $ ")))

;; text mode and auto fill mode
(setq-default major-mode 'text-mode)
(add-hook 'text-mode-hook 'turn-on-auto-fill)

(setq-default auto-fill-mode t)
(setq-default fill-column 80)       ; txt
;;(setq-default fill-column 200)       ; txt
;;(setq-default fill-column 60)       ; C++-Crash-Course
;;(setq-default fill-column 50)       ; short
;;(setq-default fill-column 77)       ; K&R C text

;; c++mode 选择对齐风格
(defun my-c++-mode-hook()
  (c-set-style "stroustrup"))
(setq-default major-mode 'c++-mode)
(add-hook 'c++-mode-hook 'my-c++-mode-hook)

;; c-mode 选择对齐风格
(defun my-c-mode-hook()
  (c-set-style "user"))
(setq-default major-mode 'c-mode)

(add-hook 'c-mode-hook 'my-c-mode-hook)


;; hide mode line 
;;(setq-default mode-line-format nil)
