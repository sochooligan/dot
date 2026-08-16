
(global-display-line-numbers-mode t)  ;; 全局开启行号
(column-number-mode t)		      ;; 显示列号

(setq scroll-step 1)  ;; 滚动时一次只移动一行，而不是一次跳过整屏

(menu-bar-mode nil)  ;; 隐藏菜单栏
(winner-mode t)	    ;; 记录历史窗口，可以来回跳转
(repeat-mode t)	    ;; 简化命令输入

;; C-x z
;; 执行一次命令后按 C-x z 可再次执行

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

;; 文本模式自动换行（中文建议改用 visual-line-mode）
(add-hook 'text-mode-hook 'turn-on-auto-fill)
;;(add-hook 'text-mode-hook 'visual-line-mode)
(setq-default fill-column 80)
