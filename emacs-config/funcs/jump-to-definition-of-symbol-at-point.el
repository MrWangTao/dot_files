(defun jump-to-definition-of-symbol-at-point ()
  (interactive)
  (if (and (symbol-at-point) (zerop (call-process "bash" nil nil nil "-c" (concat "[ -z $(global --result=grep -i " (thing-at-point 'symbol) ") ]"))))
      (if (-contains? '(emacs-lisp-mode lisp-interaction-mode) major-mode)
          (if (zerop (variable-at-point))
              (find-function (function-called-at-point))
            (find-variable (variable-at-point)))
        (if (bound-and-true-p robe-mode)
            (call-interactively 'robe-jump)
          (call-interactively 'helm-gtags-find-tag)))
    (call-interactively 'helm-gtags-find-tag)))

(defun jump-to-definition-of-symbol-at-point-other-window ()
  (interactive)
  (if (and (symbol-at-point) (zerop (call-process "bash" nil nil nil "-c" (concat "[ -z $(global --result=grep -i " (thing-at-point 'symbol) ") ]"))))
      (if (-contains? '(emacs-lisp-mode lisp-interaction-mode) major-mode)
          (if (zerop (variable-at-point))
              (call-interactively 'find-function-at-point)
            (call-interactively 'find-variable-at-point))
        (if (bound-and-true-p robe-mode)
            (call-interactively 'robe-jump-other-window)
          (call-interactively 'helm-gtags-find-tag-other-window)))
    (call-interactively 'helm-gtags-find-tag-other-window)))

(defun robe-jump-other-window (arg)
  "Jump to the method or module at point, prompt for module or file if necessary.
If invoked with a prefix or no symbol at point, delegate to `robe-ask'."
  (interactive "P")
  (robe-start)
  (let* ((bounds (robe-complete-bounds))
         (thing (buffer-substring (car bounds) (cdr bounds))))
    (cond
     ((or (not thing) arg)
      (robe-ask-other-window))
     ((robe-const-p thing)
      (robe-jump-to-module-other-window thing))
     (t
      (robe-jump-to (robe-jump-prompt thing) t)))))

(defun robe-jump-to-module-other-window (name)
  "Prompt for module, jump to a file where it has method definitions."
  (interactive `(,(robe-completing-read "Module: " (robe-request "modules"))))
  (let ((paths (robe-request "class_locations" name (car (robe-context)))))
    (when (null paths) (error "Can't find the location"))
    (let ((file (if (= (length paths) 1)
                    (car paths)
                  (let ((alist (robe-to-abbr-paths paths)))
                    (cdr (assoc (robe-completing-read "File: " alist nil t)
                                alist))))))
      (robe-find-file file t)
      (goto-char (point-min))
      (let* ((nesting (split-string name "::"))
             (cnt (1- (length nesting)))
             case-fold-search)
        (re-search-forward (concat "^[ \t]*\\(class\\|module\\) +.*\\_<"
                                   (loop for i from 1 to cnt
                                         concat "\\(")
                                   (mapconcat #'identity nesting "::\\)?")
                                   "\\_>")))
      (back-to-indentation))))

(defun robe-ask-other-window ()
  "Prompt for module, method, and jump to its definition."
  (interactive)
  (robe-jump-to (robe-ask-prompt) t))
