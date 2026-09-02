;;; -*- lexical-binding: t -*-
;; early-init.el 在 Emacs 启动时最先加载，早于 init.el
;; 适合在这里做 package 初始化、UI 优化等

;; ---- 包管理初始化 ----
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; 首次配置时，emacs 会自动解析并安装这些包（见下）
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; 让 use-package 默认缓存已编译的包，加快加载
(setq use-package-always-ensure t)