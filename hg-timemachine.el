;;; hg-timemachine.el --- Walk through hg revisions of a file

;; Copyright (C) 2014 Mattias Lundell

;; Author: Mattias Lundell <mattias@lundell.com>
;; Version: 0.1
;; URL: https://github.com/mattias-lundell/hg-timemachine
;; Package-Requires: ((cl-lib "0.5") (s "1.9.0"))
;; Keywords: hg

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Shamelessly stolen from https://github.com/pidu/git-timemachine
;;; and adapted to fit mercurial

;;; Use hg-timemachine to browse historic versions of a file with p
;;; (previous) and n (next).

(require 's)
(require 'cl-lib)

;;; Code:

(defvar hg-timemachine-directory nil)
(make-variable-buffer-local 'hg-timemachine-directory)
(defvar hg-timemachine-file nil)
(make-variable-buffer-local 'hg-timemachine-file)
(defvar hg-timemachine-revision nil)
(make-variable-buffer-local 'hg-timemachine-revision)

(defun hg-timemachine--revisions ()
 "List hg revisions of current buffers file."
 (split-string
  (shell-command-to-string
   (format "cd %s && hg log --template '{node|short}\n' %s"
    (shell-quote-argument hg-timemachine-directory)
    (shell-quote-argument hg-timemachine-file)))))

(defun hg-timemachine-show-current-revision ()
 "Show last (current) revision of file."
 (interactive)
 (hg-timemachine-show-revision (car (hg-timemachine--revisions))))

(defun hg-timemachine-show-previous-revision ()
 "Show previous revision of file."
 (interactive)
 (hg-timemachine-show-revision (cadr (member hg-timemachine-revision (hg-timemachine--revisions)))))

(defun hg-timemachine-show-next-revision ()
 "Show next revision of file."
 (interactive)
 (hg-timemachine-show-revision (cadr (member hg-timemachine-revision (reverse (hg-timemachine--revisions))))))

(defun hg-timemachine-show-revision (revision)
 "Show a REVISION (commit hash) of the current file."
 (when revision
  (let ((current-position (point)))
   (setq buffer-read-only nil)
   (erase-buffer)
   (insert
    (shell-command-to-string
     (format "cd %s && hg cat %s -r %s"
      (shell-quote-argument hg-timemachine-directory)
      (shell-quote-argument hg-timemachine-file)
      (shell-quote-argument revision))))
   (setq buffer-read-only t)
   (set-buffer-modified-p nil)
   (let* ((revisions (hg-timemachine--revisions))
          (n-of-m (format "(%d/%d)" (- (length revisions) (cl-position revision revisions :test 'equal)) (length revisions))))
    (setq mode-line-format (list "Commit: " revision " -- %b -- " n-of-m " -- [%p]")))
   (setq hg-timemachine-revision revision)
   (goto-char current-position))))

(defun hg-timemachine-quit ()
 "Exit the timemachine."
 (interactive)
 (kill-buffer))

(defun hg-timemachine-kill-revision ()
 "Kill the current revisions commit hash."
 (interactive)
 (let ((this-revision hg-timemachine-revision))
  (with-temp-buffer
   (insert this-revision)
   (message (buffer-string))
   (kill-region (point-min) (point-max)))))

(define-minor-mode hg-timemachine-mode
 "Hg Timemachine, feel the wings of history."
 :init-value nil
 :lighter " Timemachine"
 :keymap
 '(("p" . hg-timemachine-show-previous-revision)
   ("n" . hg-timemachine-show-next-revision)
   ("q" . hg-timemachine-quit)
   ("w" . hg-timemachine-kill-revision))
 :group 'hg-timemachine)

;;;###autoload
(defun hg-timemachine ()
 "Enable hg timemachine for file of current buffer."
 (interactive)
 (let* ((hg-directory (concat (s-trim-right (shell-command-to-string "hg root")) "/"))
        (relative-file (s-chop-prefix hg-directory (buffer-file-name)))
        (timemachine-buffer (format "timemachine:%s" (buffer-name))))
  (with-current-buffer (get-buffer-create timemachine-buffer)
   (setq buffer-file-name relative-file)
   (set-auto-mode)
   (hg-timemachine-mode)
   (setq hg-timemachine-directory hg-directory
         hg-timemachine-file relative-file
         hg-timemachine-revision nil)
   (hg-timemachine-show-current-revision)
   (switch-to-buffer timemachine-buffer))))

(provide 'hg-timemachine)

;;; hg-timemachine.el ends here
