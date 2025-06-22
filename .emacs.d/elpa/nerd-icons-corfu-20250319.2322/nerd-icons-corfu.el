;;; nerd-icons-corfu.el --- Icons for Corfu via nerd-icons -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Luigi Sartor Piucco
;; SPDX-License-Identifier: GPL-3.0-or-later

;; Author: Luigi Sartor Piucco <luigipiucco@gmail.com>
;; Maintainer: Luigi Sartor Piucco <luigipiucco@gmail.com>
;; Created: September 21, 2023
;; Package-Version: 20250319.2322
;; Package-Revision: 55b17ee20a50
;; Keywords: convenience, files, icons
;; Homepage: https://github.com/LuigiPiucco/nerd-icons-corfu
;; Package-Requires: ((emacs "27.1") (nerd-icons "0.1.0"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Introduces a margin formatter for Corfu which adds icons. The icons are
;; configurable, but should be text icons provided by the icons fonts in
;; `nerd-icons'.
;;
;; To use, install the package and add the following to your init:
;;
;; (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)

;;; Code:

(require 'nerd-icons)

(defgroup nerd-icons-corfu
  nil
  "Icons for Corfu via Nerd Icons."
  :group 'nerd-icons)

(define-widget 'nerd-icons-corfu-icon-type 'plist
  "The type of a static icon selection."
  :tag "Icon parameters"
  :options '((:style (choice (const :tag "wicon" "w")
                             (const :tag "faicon" "fa")
                             (const :tag "flicon" "fl")
                             (const :tag "mdicon" "md")
                             (const :tag "codicon" "cod")
                             (const :tag "devicon" "dev")
                             (const :tag "ipsicon" "ips")
                             (const :tag "octicon" "oct")
                             (const :tag "pomicon" "pom")
                             (const :tag "sucicon" "suc")))
             (:icon string)
             (:face face)))
(define-widget 'nerd-icons-corfu-function-type 'plist
  "The type of a dynamic icon selection."
  :tag "Icon provider"
  :options '((:fn function)
             (:face face)))

(defcustom nerd-icons-corfu-mapping
  '((array :style "cod" :icon "symbol_array" :face font-lock-type-face)
    (boolean :style "cod" :icon "symbol_boolean" :face font-lock-builtin-face)
    (class :style "cod" :icon "symbol_class" :face font-lock-type-face)
    (color :style "cod" :icon "symbol_color" :face success)
    (command :style "cod" :icon "terminal" :face default)
    (constant :style "cod" :icon "symbol_constant" :face font-lock-constant-face)
    (constructor :style "cod" :icon "triangle_right" :face font-lock-function-name-face)
    (enummember :style "cod" :icon "symbol_enum_member" :face font-lock-builtin-face)
    (enum-member :style "cod" :icon "symbol_enum_member" :face font-lock-builtin-face)
    (enum :style "cod" :icon "symbol_enum" :face font-lock-builtin-face)
    (event :style "cod" :icon "symbol_event" :face font-lock-warning-face)
    (field :style "cod" :icon "symbol_field" :face font-lock-variable-name-face)
    (file :fn nerd-icons-icon-for-file :face font-lock-string-face)
    (folder :fn nerd-icons-icon-for-dir :face font-lock-string-face)
    (interface :style "cod" :icon "symbol_interface" :face font-lock-type-face)
    (keyword :style "cod" :icon "symbol_keyword" :face font-lock-keyword-face)
    (macro :style "cod" :icon "symbol_misc" :face font-lock-keyword-face)
    (magic :style "cod" :icon "wand" :face font-lock-builtin-face)
    (method :style "cod" :icon "symbol_method" :face font-lock-function-name-face)
    (function :style "cod" :icon "symbol_method" :face font-lock-function-name-face)
    (module :style "cod" :icon "file_submodule" :face font-lock-preprocessor-face)
    (numeric :style "cod" :icon "symbol_numeric" :face font-lock-builtin-face)
    (operator :style "cod" :icon "symbol_operator" :face font-lock-comment-delimiter-face)
    (param :style "cod" :icon "symbol_parameter" :face default)
    (property :style "cod" :icon "symbol_property" :face font-lock-variable-name-face)
    (reference :style "cod" :icon "references" :face font-lock-variable-name-face)
    (snippet :style "cod" :icon "symbol_snippet" :face font-lock-string-face)
    (string :style "cod" :icon "symbol_string" :face font-lock-string-face)
    (struct :style "cod" :icon "symbol_structure" :face font-lock-variable-name-face)
    (text :style "cod" :icon "text_size" :face font-lock-doc-face)
    (typeparameter :style "cod" :icon "list_unordered" :face font-lock-type-face)
    (type-parameter :style "cod" :icon "list_unordered" :face font-lock-type-face)
    (unit :style "cod" :icon "symbol_ruler" :face font-lock-constant-face)
    (value :style "cod" :icon "symbol_field" :face font-lock-builtin-face)
    (variable :style "cod" :icon "symbol_variable" :face font-lock-variable-name-face)
    (t :style "cod" :icon "code" :face font-lock-warning-face))
  "Mapping of completion kinds to icons.

There are two possible types for the values of this alist, static icon
parameters or a custom function that should receive the completion candidate and
return the icon.

From here on, KIND is a symbol determining what the completion is, and comes
from calling the `:company-kind' property of the completion. The special t
symbol should be used for KIND to represent the default icon, and must be
present. This applies to both element variants.

In the first case, the elements should have the form (KIND :style ICON-STY :icon
ICON-NAME [:face FACE]). ICON-STY is a string with the icon style to use, from
those available in Nerd Fonts.  ICON-NAME is a string with the name of the icon.
FACE, if present, is applied to the icon, mainly for its color.

In case of more complex customizations that need to know the completion
candidate itself, one can use a mapping like (KIND ICON-FN), and ICON-FN will be
called with the candidate to return the icon."
  :type '(alist :key-type symbol :value-type (choice nerd-icons-corfu-icon-type nerd-icons-corfu-function-type))
  :group 'nerd-icons-corfu)

(defun nerd-icons-corfu--get-by-kind (kind)
  "Returns the icon glyph for kind KIND.

The mapping of kind -> icon is defined by the user in
`nerd-icons-corfu-mapping'."
  (let* ((icon-entry (or (alist-get (or kind t) nerd-icons-corfu-mapping)
                         (alist-get t nerd-icons-corfu-mapping)))
         (style (plist-get icon-entry :style))
         (icon (plist-get icon-entry :icon))
         (icon-fun (intern (concat "nerd-icons-" style "icon")))
         (icon-name (concat "nf-" style "-" icon))
         (face (plist-get icon-entry :face)))
    (or (and (fboundp icon-fun) (funcall icon-fun icon-name :face face)) "?")))

(defun nerd-icons-corfu--eval-space ()
  "Evaluate which space (full or half-width) should be used."
  (if (display-graphic-p)
      (propertize " " 'display '(space :width 0.5))
    " "))

(defconst nerd-icons-corfu--space (nerd-icons-corfu--eval-space)
  "Space string to be used around the icon, to form a gap on either side.

The main factor here is whether we're running on terminal or graphical.")

(defun nerd-icons-corfu--refresh-space ()
  "Refresh the value of `nerd-icons-corfu--space'."
  (setq nerd-icons-corfu--space (nerd-icons-corfu--eval-space)))

;; Refresh the space, since when started as a headless server, Emacs will set
;; the wrong value before a frame is created.
(add-hook 'server-after-make-frame-hook #'nerd-icons-corfu--refresh-space)

;;;###autoload
(defun nerd-icons-corfu-formatter (_)
  "A margin formatter for Corfu, adding icons.

It receives METADATA, ignores it, and outputs a function that takes a candidate
and returns the icon."
  (and-let* ((kindfunc (plist-get completion-extra-properties :company-kind)))
    (lambda (cand)
      (let* ((kind (funcall kindfunc cand))
             (glyph (if-let* ((args (alist-get kind nerd-icons-corfu-mapping))
                              (fn (plist-get args :fn)))
                        (funcall fn (substring-no-properties cand))
                      (nerd-icons-corfu--get-by-kind kind))))
        (concat
         (and (display-graphic-p) nerd-icons-corfu--space)
         glyph
         nerd-icons-corfu--space)))))

(provide 'nerd-icons-corfu)
;;; nerd-icons-corfu.el ends here
