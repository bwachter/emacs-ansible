;;; ansible-yasnippet.el --- Ansible yasnippet loader -*- lexical-binding: t -*-

;; Copyright (C) 2014 by 101000code/101000LAB
;; Copyright (C) 2024 by Mark A. Hershberger

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

;; Version: 0.4.1
;; Author: k1LoW (Kenichirou Oyama), <k1lowxb [at] gmail [dot] com>
;;                                   <k1low [at] 101000lab [dot] org>
;; Updates: Mark A. Hershberger, <mah@everybody.org>
;; URL: https://gitlab.com/emacs-ansible/emacs-ansible
;; Package-Requires: ((s "1.9.0") (f "0.16.2") (emacs "25.1"))

;;; Install
;; Put this file into load-path'ed directory, and byte compile it if
;; desired.  And put the following expression into your ~/.emacs.
;;
;; (require 'ansible-yasnippet)

;;; Commentary:
;; This is minor-mode for editing ansible files.

;;; Code:

;;require
(require 's)
(require 'f)
(require 'cl-lib)
(require 'easy-mmode)
(require 'yasnippet nil t)

(defconst ansible-yasnippet-dir (file-name-directory (or load-file-name
                                                         buffer-file-name)))

(defconst ansible-yasnippet-snip-dir (expand-file-name "snippets" ansible-yasnippet-dir))

(defun ansible-yasnippet-load-snippets ()
  "Load ansible snippets"
  (add-to-list 'yas-snippet-dirs ansible-yasnippet-snip-dir t)
  (yas-load-directory ansible-yasnippet-snip-dir))

(defun ansible-yasnippet-maybe-unload-snippets (&optional buffer-count)
  "Unload ansible snippets in case no other ansible buffers exists.
If BUFFER-COUNT is passed and is > 1, then skip unloading."
  ;; mitigates: https://github.com/k1LoW/emacs-ansible/issues/5
  (when (and (featurep 'yasnippet)
             ;; when called via kill-hook, the buffer is still existent
	     (= (or buffer-count 1)
		(seq-count (lambda (b)
                             (with-current-buffer b ansible-mode))
                           (buffer-list))))
    (setq yas-snippet-dirs (delete ansible-yasnippet-snip-dir yas-snippet-dirs))
    (yas-reload-all)))


(provide 'ansible-yasnippet)

;;; ansible-yasnippet.el ends here
