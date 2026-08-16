;;; -*- lexical-binding: t -*-

;; 包管理已在 early-init.el 中初始化
(require 'use-package)

(global-display-line-numbers-mode t)  ;; 全局开启行号
(column-number-mode t)		      ;; 显示列号
(global-hl-line-mode t)               ;; 高亮当前行

(setq scroll-step 1)  ;; 滚动时一次只移动一行，而不是一次跳过整屏

(menu-bar-mode -1)  ;; 隐藏菜单栏
(winner-mode t)	    ;; 记录历史窗口，可以来回跳转
(repeat-mode t)	    ;; 简化命令输入

;; C-x z
;; 执行一次命令后按 C-x z 可再次执行

;; 更好的 buffer 列表
(global-set-key (kbd "C-x C-b") 'ibuffer)

;; 关闭当前缓冲区时，不询问直接关闭当前文件；
(global-set-key (kbd "C-x k")
		(lambda () (interactive)
		  (let ((kill-buffer-query-functions nil))
		    (kill-current-buffer))))

;; 未保存关闭缓冲区时，生成 #文件，自动保存临时文件
(setq auto-save-default t) ;; recover-this-file 选中#文件，来恢复
(setq make-backup-files t) ;; 生成备份文件（~文件）

;; eshell 提示符使用短路径
;; 只显示当前目录的末级名称，例如在 /home/jz/docs 下显示：docs $
;; 实现：用 file-name-nondirectory 取路径最后一段
(setq eshell-prompt-function
      (lambda()
	(concat (file-name-nondirectory
		 (directory-file-name
		  (expand-file-name default-directory)))
		" $ ")))


;; c/c++mode 选择对齐风格（gnu/k&r/bsd/stroustrup/linux/java/user）
(setq c-default-style '((c-mode . "user")
			(c++-mode . "stroustrup")))
(setq c-basic-offset 4)  ;; 缩进宽度

;; eglot + clangd：LSP 补全、跳转定义、imenu 索引（含宏/模板）
;; eglot-imenu 返回整数位置，treemacs 需要 marker，这里递归转换
(defun my-eglot-imenu->markers (index)
  (cond
   ((null index) nil)
   ((integerp (cdr-safe index))
    (cons (car index) (copy-marker (cdr index))))
   ((stringp (car index))
    (cons (car index) (mapcar #'my-eglot-imenu->markers (cdr index))))
   ((consp index)
    (mapcar #'my-eglot-imenu->markers index))
   (t index)))

(defun my-eglot-imenu-with-markers ()
  "eglot-imenu，但把整数位置转成 marker（treemacs 需要）"
  (my-eglot-imenu->markers (eglot-imenu)))

(defun my-eglot-fix-imenu-marker ()
  (setq-local imenu-create-index-function #'my-eglot-imenu-with-markers))

(use-package eglot
  :hook ((c-mode c++-mode) . eglot-ensure)
  :config
  (require 'eglot)
  (declare-function eglot-imenu "eglot" () t)
  (add-hook 'eglot-managed-mode-hook #'my-eglot-fix-imenu-marker))

;; 文本模式自动换行（中文建议改用 visual-line-mode）
(add-hook 'text-mode-hook 'turn-on-auto-fill)
;;(add-hook 'text-mode-hook 'visual-line-mode)
(setq-default fill-column 80)


;; treemacs 文件树
(declare-function treemacs-tag-follow-mode "treemacs-tag-follow-mode" (&optional arg) t)
(declare-function treemacs-follow-mode "treemacs-follow-mode" (&optional arg) t)
(declare-function treemacs-get-local-window "treemacs-scope" () t)
(declare-function treemacs-current-button "treemacs-core-utils" () t)
(declare-function treemacs-button-get "treemacs-core-utils" (button prop) t)
(declare-function treemacs-goto-file-node "treemacs-core-utils" (path &optional project) t)
(declare-function treemacs--expand-dir-node "treemacs-rendering" (btn &rest _) t)
(declare-function treemacs--find-project-for-buffer "treemacs-workspaces" (&optional buffer-file) t)
(declare-function dired-get-filename "dired" (&optional localp no-error-if-not-filep) t)
(defun my-treemacs-follow-mode-with-tag ()
  "tag-follow-mode 激活后重新开启 follow-mode，让两者共存。"
  (treemacs-follow-mode +1))
;; dired 跟随增强：光标落在文件上时，边栏高亮跟随到该文件；
;; 光标落在目录自身条目（. / .. / 子目录）时，展开该目录让边栏内容与 dired 同步。
;; 原因是 treemacs 自带 follow 对最后一级目录只放 point 不展开。
(defun my-treemacs-follow-dired-file (&rest _)
  (when (derived-mode-p 'dired-mode)
    (when-let* ((fname (dired-get-filename nil t))
                (proj  (treemacs--find-project-for-buffer fname))
                (win   (treemacs-get-local-window)))
      (with-selected-window win
        (treemacs-goto-file-node fname proj)
        (let ((btn (treemacs-current-button)))
          (when (and btn (eq 'dir-node-closed (treemacs-button-get btn :state)))
            (treemacs--expand-dir-node btn)))))))
;; treemacs 自带 follow 只在 buffer 切换时触发，dired 内移动光标不会触发，
;; 这里用 post-command + 空闲定时器，让边栏跟随 dired 内的光标移动
(defvar my-treemacs-dired-follow-timer nil)
(defvar my-treemacs-dired-last-file nil)
(defun my-treemacs-dired-follow-idle (buf)
  (setq my-treemacs-dired-follow-timer nil)
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (when (and (derived-mode-p 'dired-mode) (bound-and-true-p treemacs-follow-mode))
        (let ((fname (dired-get-filename nil t)))
          (when (and fname (not (equal fname my-treemacs-dired-last-file)))
            (setq my-treemacs-dired-last-file fname)
            (when-let* ((proj (treemacs--find-project-for-buffer fname))
                        (win  (treemacs-get-local-window)))
              (with-selected-window win
                (treemacs-goto-file-node fname proj)
                (let ((btn (treemacs-current-button)))
                  (when (and btn (eq 'dir-node-closed (treemacs-button-get btn :state)))
                    (treemacs--expand-dir-node btn)))))))))))
(defun my-treemacs-dired-maybe-follow ()
  (when (derived-mode-p 'dired-mode)
    (unless my-treemacs-dired-follow-timer
      (setq my-treemacs-dired-follow-timer
            (run-with-idle-timer 0.2 nil #'my-treemacs-dired-follow-idle (current-buffer))))))
(add-hook 'post-command-hook #'my-treemacs-dired-maybe-follow)
(use-package treemacs
  :commands (treemacs treemacs-add-and-display-current-project)
  :bind (("<f9>" . treemacs-add-and-display-current-project))
  :config
  (setq treemacs-tag-follow-delay 0.3)
  ;; tag-follow-mode 激活时会自动禁用 follow-mode，
  ;; 通过 hook 在激活后重新开启，让两者共存：源码跟 tag，dired 跟目录
  (add-hook 'treemacs-tag-follow-mode-hook #'my-treemacs-follow-mode-with-tag)
  (treemacs-tag-follow-mode +1)
  ;; dired 场景下 follow 落到目录节点时只高亮不展开，
  ;; 展开它让边栏与 dired 文件列表同步（须在包加载后 advice）
  (advice-add 'treemacs--follow :after #'my-treemacs-follow-dired-file))

;; M-x byte-compile-file
;; emacs --batch -f batch-byte-compile ~/.emacs.d/init.el
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(treemacs)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
