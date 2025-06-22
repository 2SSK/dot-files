;;; autothemer.el --- Conveniently define themes -*- lexical-binding: t -*-
;;
;; Authors: Sebastian Sturm, Jason Milkins
;;
;; Copyright 2015-2022 Sebastian Sturm, Jason Milkins
;;
;; Maintainer: Jason Milkins <jasonm23@gmail.com>
;;
;; URL: https://github.com/jasonm23/autothemer
;; Package-Version: 20230414.1419
;; Package-Revision: 8f72afc6dba5
;; Package-Requires: ((dash "2.10.0") (emacs "26.1"))
;;
;;; License:
;; This program is free software; you can redistribute it and/or modify
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
;; Reduce the amount of pain and boilerplate code needed to create custom themes using `autothemer-deftheme'.
;;
;; Autothemer also includes interactive commands and functions to
;; assist with theme building, here are a few highlights...
;;
;; - Generate specs for unthemed faces using the theme color palette.
;;   - `autothemer-generate-templates'
;;   - `autothemer-generate-templates-filtered' (filter by regexp)
;;   - `autothemer-insert-missing-face'
;;   - `autothemer-insert-missing-faces'
;; - Generate a palette SVG image
;;   - `autothemer-generate-palette-svg'
;; - Insert a color name or color from the active palette
;;   - `autothemer-insert-color-name'
;;   - `autothemer-insert-color'
;; - Colorize/font-lock palette color names in the buffer
;;   - `autothemer-colorize'  (requires `rainbow-mode' during development.)
;;
;;; Code:
(require 'cl-lib)
(require 'dash)
(require 'lisp-mnt)
(require 'color)
(require 'subr-x)

(cl-defstruct
    autothemer--color
  name
  value)

(cl-defstruct
    autothemer--theme
  colors
  defined-faces
  name
  description)

(defvar autothemer-current-theme nil
  "Palette and face list for last evaluated `autothemer-deftheme'.")

(defvar autothemer-hue-groups
  '((red             (345 . 10))
    (red-orange      (10  . 20))
    (orange-brown    (20  . 40))
    (orange-yellow   (40  . 50))
    (yellow          (50  . 60))
    (yellow-green    (60  . 80))
    (green           (80  . 140))
    (green-cyan      (140 . 170))
    (cyan            (170 . 200))
    (cyan-blue       (200 . 220))
    (blue            (220 . 240))
    (blue-magenta    (240 . 280))
    (magenta         (280 . 320))
    (magenta-pink    (320 . 330))
    (pink            (330 . 345)))
  "Set of perceptual color ranges.")

(defvar autothemer-simple-hue-groups
  '((red     (345 . 20))
    (orange  (20  . 50))
    (yellow  (50  . 60))
    (green   (60  . 140))
    (cyan    (140 . 220))
    (blue    (220 . 280))
    (magenta (280 . 345)))
  "Simple set of color groups.")

(defvar autothemer-low-mid-high-saturation-groups
  '((low (0.0 . 0.3333333333333333))
    (mid (0.3333333333333334 . 0.6666666666666666))
    (high (0.6666666666666667 . 1.0)))
  "Low, mid & high saturation groups.")

(defvar autothemer-20-percent-saturation-groups
  '((saturation-000-020-percent (0.0 . 0.2))
    (saturation-020-040-percent (0.2 . 0.4))
    (saturation-040-060-percent (0.4 . 0.6))
    (saturation-060-080-percent (0.6 . 0.8))
    (saturation-080-100-percent (0.8 . 1.0)))
  "Saturation grouping at 20% intervals.
This is the default for `autothemer-saturation-group'.")

(defvar autothemer-10-percent-saturation-groups
  '((saturation-000-010-percent (0.0 . 0.1))
    (saturation-010-020-percent (0.1 . 0.2))
    (saturation-020-030-percent (0.2 . 0.3))
    (saturation-030-040-percent (0.3 . 0.4))
    (saturation-040-050-percent (0.4 . 0.5))
    (saturation-050-060-percent (0.5 . 0.6))
    (saturation-060-070-percent (0.6 . 0.7))
    (saturation-070-080-percent (0.7 . 0.8))
    (saturation-080-090-percent (0.8 . 0.9))
    (saturation-090-100-percent (0.9 . 1.0)))
  "Saturation grouping at 10% intervals.")

(defvar autothemer-dark-mid-light-brightness-groups
 '((dark (0.0 . 0.3333333333333333))
   (mid (0.3333333333333334 . 0.6666666666666666))
   (light (0.6666666666666667 . 1.0)))
 "Dark, mid & light brightness groups.")

(defvar autothemer-20-percent-brightness-groups
  '((brightness-000-020-percent (0.0 . 0.2))
    (brightness-020-040-percent (0.2 . 0.4))
    (brightness-040-060-percent (0.4 . 0.6))
    (brightness-060-080-percent (0.6 . 0.8))
    (brightness-080-100-percent (0.8 . 1.0)))
  "Brightness groups at 20% intervals.
This is the default `autothemer-brightness-group'.")

(defvar autothemer-10-percent-brightness-groups
  '((brightness-000-010-percent (0.0 . 0.1))
    (brightness-010-020-percent (0.1 . 0.2))
    (brightness-020-030-percent (0.2 . 0.3))
    (brightness-030-040-percent (0.3 . 0.4))
    (brightness-040-050-percent (0.4 . 0.5))
    (brightness-050-060-percent (0.5 . 0.6))
    (brightness-060-070-percent (0.6 . 0.7))
    (brightness-070-080-percent (0.7 . 0.8))
    (brightness-080-090-percent (0.8 . 0.9))
    (brightness-090-100-percent (0.9 . 1.0)))
  "Brightness grouping at 10% intervals.")

(defun autothemer--reduced-spec-to-facespec (display reduced-specs)
  "Create a face spec for DISPLAY, with specs REDUCED-SPECS.

For example:

     (autothemer--reduced-spec-to-facespec
        '(min-colors 60)
        '(button (:underline t :foreground red)))
     ;; => `(button (((min-colors 60) (:underline ,t :foreground ,red))))."
  (let* ((face (elt reduced-specs 0))
         (properties (elt reduced-specs 1))
         (spec (autothemer--demote-heads `(list (,display ,properties)))))
    `(list ',face ,spec)))

(defun autothemer--demote-heads (expr)
  "Demote every list head within EXPR by one element.
E.g., (a (b c d) e (f g)) -> (list a (list b c d) e (list f g))."
  (if (listp expr)
      `(list ,@(mapcar
                (lambda (it)
                  (if (and (listp it) (not (eq (car it) 'quote)))
                      (autothemer--demote-heads it) it))
                expr))
    expr))

;;;###autoload
(defmacro autothemer-deftheme (name description palette reduced-specs &rest body)
  "Define a theme NAME with description DESCRIPTION.
A color PALETTE can be used to define `let*'-like
bindings within both the REDUCED-SPECS and the BODY."
  (let* ((face-names (-map #'car reduced-specs))
         (color-names (-map #'car (-drop 1 palette)))
         (n-displays (length (car palette)))
         (n-faces (length reduced-specs))
         (face-customizer)
         (full-palette (autothemer--fill-empty-palette-slots palette))
         (face-specs (make-symbol "face-specs"))
         (temp-n (make-symbol "n"))
         (temp-defined-colors (make-symbol "defined-colors"))
         (temp-color-structs (make-symbol "defined-colors-as-structs"))
         (temp-color (make-symbol "color"))
         (temp-colorname (make-symbol "colorname")))
    (setq face-customizer
          `(let ((,face-specs)
                 (,temp-color-structs)
                 (,temp-defined-colors))
             (deftheme ,name ,description)
             ,@(cl-loop for n from 0 to (1- n-displays)
                        collect
                        `(let* ,(autothemer--extract-let-block full-palette n)
                           ,@(when (and body (eq n 0))
                               body)
                           ,(when (> n 0)
                              `(ignore ,@color-names))
                           ,(when (and (eq n 0) (not (bound-and-true-p byte-compile-current-file)))
                              `(progn
                                 (setq ,temp-defined-colors
                                       (list ,@(--map (list 'list `',it it) color-names)))
                                 (setq ,temp-color-structs
                                       (cl-loop for (,temp-colorname ,temp-color)
                                                in ,temp-defined-colors
                                                collect (make-autothemer--color :name ,temp-colorname
                                                                                :value ,temp-color)))
                                 (setq autothemer-current-theme
                                       (make-autothemer--theme
                                        :name ,(symbol-name name)
                                        :description ,description
                                        :colors ,temp-color-structs
                                        :defined-faces ',face-names))))
                           (setq ,face-specs
                                 (autothemer--append-column
                                  ,face-specs
                                  (list ,@(--map `(list
                                                   (list
                                                    ',(autothemer--extract-display palette n)
                                                    ,(autothemer--demote-heads (elt it 1))))
                                                 reduced-specs))))))
             (apply #'custom-theme-set-faces ',name
                    (cl-loop for ,temp-n from 0 to ,(1- n-faces)
                             collect (list (elt ',face-names ,temp-n)
                                           (elt ,face-specs ,temp-n))))))
    face-customizer))

(defun autothemer--color-distance (color palette-color)
  "Return the distance in rgb space between COLOR and PALETTE-COLOR.
Here, COLOR is an Emacs color specification and PALETTE-COLOR is of
type `autothemer--color'."
  (declare (obsolete 'autothemer--cie-de2000 "0.2.13"))
  (let ((rgb-1 (autothemer-hex-to-rgb color))
        (rgb-2 (autothemer-hex-to-rgb palette-color)))
    (-sum (--zip-with (abs (- it other)) rgb-1 rgb-2))))

(defun autothemer-cie-de2000 (color-a color-b)
  "Return the color distance in CIE Lab space, between COLOR-A and COLOR-B.
Using the CIE-DE2000 algorithm."
  (let ((lab-1 (apply 'color-srgb-to-lab (autothemer-hex-to-srgb color-a)))
        (lab-2 (apply 'color-srgb-to-lab (autothemer-hex-to-srgb color-b))))
     (color-cie-de2000 lab-1 lab-2)))

(defun autothemer--find-closest-color (colors color)
  "Return the element of COLORS that is closest in CIE Lab space to COLOR.
Here, COLOR is an Emacs color specification and COLORS is a list
of `autothemer--color' structs."
  (let ((min-distance 0)
        (color (if (string-match-p "#[[:xdigit:]]\\{6\\}" color)
                   color
                 (autothemer-rgb-to-hex (color-values color))))
        (closest-color nil))
    (mapc (lambda (candidate)
            (when (color-defined-p (autothemer--color-value candidate))
              (let ((distance (autothemer-cie-de2000 color candidate)))
                (if (or (not closest-color) (< distance min-distance))
                    (setq closest-color candidate
                          min-distance distance)))))
          colors)
    closest-color))

(defun autothemer--unthemed-faces ()
  "Find uncustomized faces.
Iterate through all currently defined faces and return those that
were left uncustomized by the most recent call to
`autothemer-deftheme'."
  (let ((all-faces (face-list))
        (themed-faces (autothemer--theme-defined-faces autothemer-current-theme)))
    (--filter (not (-contains? themed-faces it)) all-faces)))

(defun autothemer--face-to-alist (face)
  "Return the attribute alist for FACE in frame (selected-frame)."
  (face-all-attributes face (selected-frame)))

(defun autothemer--cons-to-tree (the-cons)
  "Turn THE-CONS into a list, unless its cdr is `unspecified'."
  (let ((property-name (car the-cons))
        (property-value (cdr the-cons))
        (result))
    (unless (eq property-value 'unspecified)
      (setq result (list property-name property-value)))
    result))

(defun autothemer--alist-to-reduced-spec (facename alist)
  "Generate a reduced-spec for FACENAME, based on the face attribute ALIST."
  (list facename
        (--reduce-from (append acc it) nil
                       (mapcar 'autothemer--cons-to-tree
                               alist))))

(defun autothemer--approximate-spec (reduced-spec theme)
  "Replace colors in REDUCED-SPEC by their closest approximations in THEME.
Replace every expression in REDUCED-SPEC that passes
`color-defined-p' by the closest approximation found in
`autothemer-current-theme'.  Also quote all face names and
unbound symbols, such as `normal' or `demibold'."
  (let ((colors (autothemer--theme-colors theme))
        (face (car reduced-spec))
        (spec (cdr reduced-spec)))
    `(,face ,@(--tree-map (cond ((and (stringp it) (color-defined-p it))
                                 (autothemer--color-name
                                  (autothemer--find-closest-color colors it)))
                                ((stringp it) it)
                                ((numberp it) it)
                                ((facep it) `(quote ,it))
                                ((consp it) it)
                                ((not (boundp it)) `(quote ,it))
                                (t it))
                          spec))))

(defun autothemer--pad-with-nil (row min-number-of-elements)
  "Make sure that ROW has at least MIN-NUMBER-OF-ELEMENTS.
Pad with nil if necessary."
  (append
   row
   (-repeat
    (max 0
         (- min-number-of-elements
            (length row)))
    nil)))

(defun autothemer--replace-nil-by-precursor(palette-row)
  "Replace nil colors in PALETTE-ROW with their precursor.

PALETTE-ROW is of the form `(name color [color ...])' Where the
first `color' must be non nil. Any subsequent nil color will be
replaced by the previous value.

For example:
     (\"red-foo\" \"#FF0000\" nil)
Will become:
     (\"red-foo\" \"#FF0000\" \"#FF0000\")"
  (cl-assert (car palette-row))
  (let* ((color-name (car palette-row))
         (color-definitions (cdr palette-row))
         (last-definition))
    (cons color-name
          (cl-loop for definition in color-definitions
                   do (when definition (setq last-definition definition))
                   collect last-definition))))

(defun autothemer--fill-empty-palette-slots (palette)
  "Fill empty PALETTE slots so each display has all color-definitions."
  (let ((n-displays (length (car palette))))
    (cons (car palette)
          (cl-loop for row in (cdr palette)
                   collect (autothemer--replace-nil-by-precursor
                            (autothemer--pad-with-nil row (1+ n-displays)))))))

(defun autothemer--extract-display (palette n)
  "Extract from PALETTE display specification #N."
  (elt (car palette) n))

(defun autothemer--extract-let-block (palette n)
  "Extract a variable definition block from PALETTE for display type N."
  (cl-loop for row in (cdr palette)
           collect (list (car row) (elt row (1+ n)))))

;;;###autoload
(defun autothemer-insert-missing-face ()
  "Insert a face spec template for an unthemed face.
An approximate color from the palette will be used for
color attributes."
  (interactive)
  (let ((selected (completing-read "Select an un-themed face: " (autothemer--unthemed-faces))))
    (insert
     (replace-regexp-in-string "\n" ""
      (pp-to-string
       (autothemer--approximate-spec
        (autothemer--alist-to-reduced-spec (intern selected) (autothemer--face-to-alist (intern selected)))
        autothemer-current-theme))))))

;;;###autoload
(defun autothemer-insert-missing-faces (&optional regexp)
  "Insert face spec templates for unthemed faces matching REGEXP.
An error is shown when no current theme is available."
  (interactive)
  (autothemer--current-theme-guard)
  (let* ((regexp (or regexp
                     (completing-read
                      "(Match un-themed face set) Regexp: "
                      (autothemer--unthemed-faces))))
         (missing-faces
          (if (null regexp)
              (autothemer--unthemed-faces)
            (--filter
             (string-match-p regexp (symbol-name it))
             (autothemer--unthemed-faces))))
         (templates (--reduce
                     (format "%s%s" acc it)
                     (--map
                      (format "%s\n"
                              (replace-regexp-in-string
                               "\n" ""
                               (pp-to-string
                                (autothemer--approximate-spec
                                 (autothemer--alist-to-reduced-spec
                                  it (autothemer--face-to-alist it))
                                 autothemer-current-theme))))
                      missing-faces))))
    (insert templates)))

;;;###autoload
(defun autothemer-generate-templates-filtered (regexp)
  "Autogenerate customizations for unthemed faces matching REGEXP.

Calls `autothemer-generate-templates' after user provides REGEXP interactively."
  (interactive "sGenerate face templates matching regexp: ")
  (autothemer-generate-templates regexp))

;;;###autoload
(defun autothemer-generate-templates (&optional regexp)
  "Autogenerate customizations for unthemed faces (optionally by REGEXP).

Generate customizations that approximate current face definitions using the
nearest colors in the color palette of `autothemer-current-theme'.

An error is shown when no current theme is available."
  (interactive)
  (unless autothemer-current-theme
    (user-error "No autothemer-current-theme available. Please evaluate an autothemer-deftheme"))
  (let* ((missing-faces
          (if (null regexp)
              (autothemer--unthemed-faces)
            (--filter
              (string-match-p
               regexp
               (symbol-name it))
             (autothemer--unthemed-faces))))
         (templates
           (--map (autothemer--approximate-spec
                   (autothemer--alist-to-reduced-spec
                    it (autothemer--face-to-alist it))
                   autothemer-current-theme)
                  missing-faces))
         (buffer
          (get-buffer-create
           (generate-new-buffer-name "*Autothemer: unthemed faces*"))))
    (with-current-buffer buffer (emacs-lisp-mode) (insert (pp templates)))
    (switch-to-buffer buffer)))

(cl-defsubst autothemer--append-column (lists new-column)
  "If LISTS is nil, return NEW-COLUMN.
Otherwise, append NEW-COLUMN to every element of LISTS."
  (cl-assert (or (not lists) (eq (length lists) (length new-column))))
  (if lists (inline (-zip-with #'append lists new-column))
    new-column))

(defun autothemer--current-theme-guard ()
  "Guard functions from executing when there's no current theme."
  (unless autothemer-current-theme
    (user-error "No current theme available. Evaluate an autotheme definition")))

;;; Get colors from theme palette

(defun autothemer--get-color (color-name)
  "Return color palette object for (string) COLOR-NAME.

Search the `autothemer-current-theme' color palette for COLOR-NAME
and returns a color in the form of `autothemer--color' struct.

See also `autothemer--color-p',
         `autothemer--color-name',
         `autothemer--color-value'."
  (autothemer--current-theme-guard)
  (--find
   (eql (intern color-name)
        (autothemer--color-name it))
   (autothemer--theme-colors autothemer-current-theme)))

(defun autothemer--select-color (&optional prompt)
  "Select a color from the current palette, optionally use PROMPT.
Current palette is read from `autothemer-current-theme'.

The selected color will be in the form of a `autothemer--color'

See also `autothemer--color-p',
         `autothemer--color-name',
         `autothemer--color-value'."
  (autothemer--current-theme-guard)
  (let*
      ((selected
        (completing-read (if (null prompt)
                             "Select a color: "
                           prompt)
         (mapcar #'(lambda (it)
                     (let ((color (autothemer--color-value it))
                           (name (autothemer--color-name it)))
                      (format
                       "%s %s  %-45s"
                       (propertize "                                        "
                        'face (list ':background color
                                    ':foreground (readable-foreground-color color)))
                       (propertize color
                        'face (list ':background color
                                    ':foreground (readable-foreground-color color)))
                       name)))
          (autothemer--theme-colors autothemer-current-theme))))
       (color-name (cadr (split-string selected " " t " "))))
    (autothemer--get-color color-name)))

(defun autothemer-insert-color ()
  "Select and insert a color from the current autotheme palette."
  (interactive)
  (autothemer--current-theme-guard)
  (let ((color (autothemer--color-value
                 (autothemer--select-color "Insert a color: "))))
    (insert color)))

(defun autothemer-insert-color-name ()
  "Select and insert a color name from the current autotheme palette."
  (interactive)
  (autothemer--current-theme-guard)
  (let ((color-name (autothemer--color-name
                      (autothemer--select-color "Insert a color name: "))))
    (insert (format"%s" color-name))))

;;; Helper Functions

(defmacro autothemer--plist-bind (args plist &rest body)
  "Evaluate BODY with using ARGS to access PLIST values.

For example:

    (autothemer--plist-bind (a b c) '(:a 1 :b 2 :c 3) (list a b))
    => '(1 2)

If PLIST is nil, ARGS are bound to BODY nil values."
  `(if (listp ,plist)
       (cl-destructuring-bind (&key ,@args &allow-other-keys) ,plist ,@body)
     (let (,@args) ,@body)))

(defun autothemer--unindent (s)
  "Unindent string S marked with | chars."
  (replace-regexp-in-string "^ *|" "" s))

;;; let palette...
(defmacro autothemer-let-palette (&rest body)
  "Provide a let block for BODY from `autothemer-current-theme'.

Load/eval the required autothemer theme source (not
byte-compiled) to set `autothemer-current-theme'."
  (autothemer--current-theme-guard)
  `(let ,(--map (list (autothemer--color-name it) (autothemer--color-value it))
                (autothemer--theme-colors autothemer-current-theme))
     ,@body))

;;; Colorize alist for rainbow-mode
(defun autothemer--colorize-alist ()
  "Generate an alist for use with rainbow-mode.

To colorize use:

    (rainbow-colorize-by-assoc (autothemer--colorize-alist))

Colors are from `autothemer-current-theme'."
  (autothemer--current-theme-guard)
  (--map (cons (format "%s" (autothemer--color-name it))
               (autothemer--color-value it))
    (autothemer--theme-colors autothemer-current-theme)))

(defvar autothemer--colors-font-lock-keywords nil)

(defun autothemer-colorize ()
  "In the current buffer, colorize palette names, from the last evaluated theme."
  (interactive)
  (setq autothemer--colors-font-lock-keywords
      `((,(regexp-opt (mapcar 'car (autothemer--colorize-alist)) 'words)
         (0 (rainbow-colorize-by-assoc (autothemer--colorize-alist))))))
  (font-lock-add-keywords nil autothemer--colors-font-lock-keywords t))

;;; Color conversion

(defun autothemer--color-to-hsv (rgb)
  "Convert RGB, a list of `(r g b)' to list `(h s v)'.
The `r' `g' `b' values can range between `0..65535'.

In `(h s v)' `h', `s' and `v' are `0.0..1.0'."
  (cl-destructuring-bind
      (r g b) (--map (/ it 65535.0) rgb)
    (let*
        ((bri (max r g b))
         (delta (- bri (min r g b)))
         (sat (if (cl-plusp bri)
                  (/ delta bri)
                0.0))
         (normalize #'(lambda
                        (constant right left)
                        (let ((hue (+ constant (/ (* 60.0 (- right left)) delta))))
                          (if (cl-minusp hue)
                              (+ hue 360.0)
                            hue)))))
      (list (/ (cond
                ((zerop sat) 0.0)
                ((= r bri) (funcall normalize 0.0 g b)) ; dominant r
                ((= g bri) (funcall normalize 120.0 b r)) ; dominant g
                (t (funcall normalize 240.0 r g))) ; dominant b
               360.0)
            sat
            bri))))

(defun autothemer-hex-to-rgb (hex)
  "Convert HEX to `(r g b)'.
`r', `g', `b' will be values `0..65535'"
  (let* ((hex (cond ((stringp hex) hex)
                    ((autothemer--color-p hex) (autothemer--color-value hex))))
         (rgb (string-to-number (substring hex 1) 16)))
     (list
      (* #x101 (ash (logand #xFF0000 rgb) -16))
      (* #x101 (ash (logand #xFF00 rgb) -8))
      (* #x101 (logand #xFF rgb)))))

(defun autothemer-hex-to-srgb (hex)
  "Convert HEX to `(r g b)'.
`r', `g', `b' will be values `0.0..1.0'"
  (let* ((hex (cond ((stringp hex) hex)
                  ((autothemer--color-p hex) (autothemer--color-value hex))))
         (rgb (string-to-number (substring hex 1) 16)))
     (list
      (/ (ash (logand #xFF0000 rgb) -16) 255.0)
      (/ (ash (logand #xFF00 rgb) -8) 255.0)
      (/ (logand #xFF rgb) 255.0))))

(defun autothemer-rgb-to-hex (rgb)
  "0..65535 based RGB to hex string."
  (eval `(format "#%02X%02X%02X" ,@(mapcar (lambda (it) (round (* 255 (/ it 65535.0)))) rgb))))

(defun autothemer-color-hue (color)
  "Return the HSV hue of COLOR (hex color or autothemer--color struct)."
  (car (autothemer--color-to-hsv (autothemer-hex-to-rgb color))))

(defun autothemer-color-sat (color)
  "Return the HSV saturation of COLOR (hex color or autothemer--color struct)."
  (cadr (autothemer--color-to-hsv (autothemer-hex-to-rgb color))))

(defun autothemer-color-brightness (color)
  "Return the HSV brightness of COLOR (hex color or autothemer--color struct)."
  (caddr (autothemer--color-to-hsv (autothemer-hex-to-rgb color))))

;;; Sort/Order of autothemer--color structs.

(defun autothemer-darkest-order (a b)
  "Return t if the darkness of A > B."
  (let ((a (autothemer-color-brightness (autothemer--color-value a)))
        (b (autothemer-color-brightness (autothemer--color-value b))))
    (> b a)))

(defun autothemer-lightest-order (a b)
  "Return t if the lightness of A > B."
  (let ((a (autothemer-color-brightness (autothemer--color-value a)))
        (b (autothemer-color-brightness (autothemer--color-value b))))
      (> a b)))

(defun autothemer-saturated-order (a b)
  "Return t if the saturation of A > B."
  (let ((a (autothemer-color-sat (autothemer--color-value a)))
        (b (autothemer-color-sat (autothemer--color-value b))))
      (> a b)))

(defun autothemer-desaturated-order (a b)
  "Return t if the saturation of A < B."
  (let ((a (autothemer-color-sat (autothemer--color-value a)))
        (b (autothemer-color-sat (autothemer--color-value b))))
      (< a b)))

(defun autothemer-hue-order (a b)
  "Return t if the hue of A > B."
  (let ((a (autothemer-color-hue (autothemer--color-value a)))
        (b (autothemer-color-hue (autothemer--color-value b))))
      (> a b)))

(defun autothemer-sort-palette (theme-colors &optional sort-fn group-fn group-args)
  "Produce a list of sorted THEME-COLORS using SORT-FN.
If SORT-FN is nil, sort by default `autothemer-darkest-order'.
Grouping is supported via GROUP-FN & GROUP-ARGS.

See `autothemer-group-and-sort' for a full list."
  (let ((sort-fn (or sort-fn 'autothemer-darkest-order))
        (sorted (-sort sort-fn theme-colors)))
    sorted))

;; Color Grouping

(defun autothemer-color-to-group (color fn groups)
  "Group COLOR using FN, in GROUPS."
  (let ((value (funcall fn color)))
   (-reduce-from
    (lambda (acc range)
      (let ((a (car (cadr range)))
            (b (cdr (cadr range))))
       (if (<= a value b)
         (car range)
        acc)))
    nil
    groups)))

(defun autothemer-saturation-grouping (color &optional saturation-groups)
  "Return the saturation group of COLOR.
Functionally identical to `autothemer-hue-groups' for saturation.
Optionally provide a list of SATURATION-GROUPS.
The default is `autothemer-20-percent-saturation-groups'."
  (autothemer-color-to-group
   color
   'autothemer-color-sat
   (or saturation-groups autothemer-20-percent-saturation-groups)))

(defun autothemer-brightness-grouping (color &optional brightness-groups)
  "Return the brightness group of COLOR.
Functionally identical to `autothemer-hue-groups' for brightness.
Optionally provide a list of BRIGHTNESS-GROUPS.
The default is `autothemer-20-percent-brightness-groups'."
  (autothemer-color-to-group
   color
   'autothemer-color-brightness
   (or brightness-groups autothemer-20-percent-brightness-groups)))

(defun autothemer-hue-grouping (color &optional hue-groups)
  "Return the color hue group for COLOR.

Optionally provide a list of HUE-GROUPS.
\(default uses `autothemer-hue-groups'.)
Also available is `autothemer-simple-hue-groups',
both are customizable, or define your own.

This facilitates hue grouping & sorting by a secondary axis.
For example sort a list of colors by some axis (brightness or
saturation). Then group by hue groups, and sort the groups.
The format of each group in the list is:

    (group-name (n1 . n2))

Where `group-name' is a symbol to name the group,
`(n1 . n2)' is a hue range specifier (in degrees)
low `n1' to high `n2'.

A hue range which crosses the apex (i.e. `360°..0°') is permitted."
  (let* ((init-hue-groups (or (and (listp hue-groups) hue-groups)
                              (and (listp (symbol-value hue-groups))
                                   (symbol-value hue-groups))
                              autothemer-hue-groups))
         (hue-groups (-reduce-from
                      (lambda (acc range)
                        (let* ((a (car (cadr range)))
                               (b (cdr (cadr range)))
                               (r (if (> a b) ;; hue apex check 360..0
                                      `(,(list (car range) (cons a 360))
                                        ,(list (car range) (cons 0 b)))
                                    `(,range))))
                          (if acc
                              (cl-concatenate 'list acc r)
                            r)))
                      nil
                      init-hue-groups))
         (hue (autothemer-color-hue color)))
   (-reduce-from
    (lambda (acc range)
      (let ((a (car (cadr range)))
            (b (cdr (cadr range))))
       (if (<= a (* hue 360) b)
         (car range)
        acc)))
    nil
    hue-groups)))

;;; Group and sort

(defun autothemer-group-sort (groups sort-fn)
  "Sort GROUPS of colors using SORT-FN.
GROUPS are produced by `autothemer-group-colors'."
  (mapcar
    (lambda (group)
      "Groups are alists with car as key, cdr as colors."
      (let* ((name (car group))
             (colors (cdr group))
             (sorted-colors (--sort
                             (funcall sort-fn it other)
                             colors)))
        (cons name sorted-colors)))
    groups))

(defun autothemer-group-colors (palette options)
  "Group PALETTE colors into groups as defined in plist OPTIONS:
`:group-fn' - mandatory group function
`:group-args' - args for `group-fn'"
  (autothemer--plist-bind (group-fn group-args) options
   (let* ((group-keys (mapcar 'car group-args))
          (colors-with-groups (mapcar (lambda (color)
                                        (list (funcall group-fn (autothemer--color-value color)
                                                       group-args)
                                              color))
                                palette))
          (grouped-colors (mapcar (lambda (group) (--reduce (-flatten (cons acc (cdr it))) group))
                                  (-group-by 'car colors-with-groups)))
          (grouped-colors (-filter 'car (mapcar (lambda (group) (assoc group grouped-colors)) group-keys))))
        grouped-colors)))

(defun autothemer-group-and-sort (palette options)
  "Group and sort PALETTE using OPTIONS.

Options is a plist of:

#TABLE Option - Description #
    :group-fn - mandatory group function
    :group-args - optional group args (to use a non-default group)
    :sort-fn - optional sort function
#TABLE#

See color grouping functions and group lists:

Hue grouping:

#TABLE Function - Description #
    autothemer-hue-grouping - color hue group for COLOR
#TABLE#

#TABLE Hue Groups - Description #
    autothemer-hue-groups - group colors into major hue groups (default)
    autothemer-simple-hue-groups - group colors into broad hue groups
#TABLE#

Brightness grouping:

#TABLE Function - Description #
    autothemer-brightness-grouping - brightness group for COLOR
#TABLE#

#TABLE Brightness Groups - Description #
    autothemer-dark-mid-light-brightness-groups - 3 brightness groups
    autothemer-10-percent-brightness-groups - 10 brightness groups
    autothemer-20-percent-brightness-groups - 5 brightness groups (default)
#TABLE#

Saturation grouping:

#TABLE Function - Description #
    autothemer-saturation-grouping - saturation group for COLOR
#TABLE#

#TABLE Saturation Groups - Description #
    autothemer-low-mid-high-saturation-groups - 3 saturation groups
    autothemer-10-percent-saturation-groups - 10 saturation groups
    autothemer-20-percent-saturation-groups - 5 saturation groups (default)
#TABLE#
- - -

Sorting:

The sort/ordering functions take args A and B, which are expected
to be `autothemer--color' structs.

#TABLE Sort Functions - Description#
    autothemer-darkest-order - darkest to lightest
    autothemer-lightest-order - lightest to darkest
    autothemer-hue-order - sort by hue
    autothemer-saturated-order - sort by most saturated to least
    autothemer-desaturated-order - sort by least saturated to most
#TABLE#"
 (autothemer--plist-bind
  (group-fn
   group-args
   sort-fn)
  options
  (let* ((grouped-colors (autothemer-group-colors palette (list :group-fn (eval group-fn) :group-args (eval group-args))))
         (sorted-groups  (autothemer-group-sort grouped-colors (eval sort-fn))))
      sorted-groups)))

(defun autothemer-groups-to-palette (grouped-palette)
  "Flatten a GROUPED-PALETTE from `autothemer-group-and-sort' to a single list."
  (-flatten (--map (cdr it) grouped-palette)))

;;; SVG Palette generator...

(defun autothemer-generate-palette-svg (&optional options)
  "Create an SVG palette image for a theme.

Optional parameter `options` (a plist). Any required values not
supplied in OPTIONS will use defaults or prompt interactively.

#TABLE Option - Description #
    :theme-file - theme filename
    :theme-name - override the title found in :theme-file
    :theme-description - override the description found in :theme-file
    :theme-url - override the url found in :theme-file
    :font-family - font name to use in the generated SVG
    :columns - number of columns for each palette row (default: 6)
    :bg-color - Page background color
    :text-color - Main text color
    :text-accent-color - Text accent color
    :page-template - see page-template below
    :page-top-margin - (default: 120)
    :page-right-margin - (default: 30)
    :page-bottom-margin - (default: 60)
    :page-left-margin - (default: 30)
    :swatch-template - see swatch-template below
    :swatch-border-color - the border color of a color swatch
    :swatch-width - px spacing width of a color swatch (default: 100)
    :swatch-height - px spacing height of a color swatch (default: 150)
    :swatch-rotate - degrees of rotation for swatch (default: 45)
    :h-space - horizontal-space between swatches (default: 10)
    :v-space - vertical-space between swatches (default: 10)
    :sort-palette - arrange palette using a function name
    :visually-group-swatches - boolean (default: nil)
    :svg-out-file - the file/pathname to save SVG output
#TABLE#

For advanced customization the :page-template and :swatch-template can be
used to provide customize the SVG templates.

Note: Template parameters are filled by `format' so we mark them as follows:

Page Template parameters:

#TABLE Parameter - Description#
    %1$s  - width
    %2$s  - height
    %3$s  - font-family
    %4$s  - text-color
    %5$s  - text-accent-color
    %6$s  - bg-color
    %7$s  - theme-name
    %8$s  - theme-description
    %9$s  - theme-url
    %10$s - color swatches
#TABLE#

Swatch Template parameters:

#TABLE Parameter - Description#
    %1$s - x
    %2$s - y
    %3$s - swatch-border-color
    %4$s - swatch-color
    %5$s - text-accent-color
    %6$s - swatch-color-name
#TABLE#"
  (interactive)
  (autothemer--plist-bind
    (theme-file
     theme-name
     theme-description
     theme-url
     font-family
     columns
     bg-color
     text-color
     text-accent-color
     page-template
     page-top-margin
     page-right-margin
     page-bottom-margin
     page-left-margin
     swatch-template
     swatch-border-color
     swatch-width
     swatch-height
     swatch-rotate
     h-space
     v-space
     sort-palette
     visually-group-swatches
     svg-out-file)
    options
   (let ((theme-file (or theme-file (read-file-name "Select autothemer theme .el file: "))))
     (load-file theme-file) ;; make it the current-theme
     (let* ((page-template
             (or page-template
              (autothemer--unindent "<?xml version=\"1.0\" standalone=\"no\"?>
                         |<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\"
                         |\"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">
                         |<svg width=\"%1$spx\" height=\"%2$spx\"
                         |     version=\"1.1\"
                         |     xmlns=\"http://www.w3.org/2000/svg\"
                         |     xmlns:xlink=\"http://www.w3.org/1999/xlink\">
                         |  <style>
                         |    text {
                         |    font-family: \"%3$s\";
                         |    fill: %4$s;
                         |    }
                         |  </style>
                         |  <rect x=\"0\" y=\"0\" rx=\"10\" width=\"%1$spx\" height=\"%2$spx\" id=\"background-panel\" fill=\"%6$s\"/>
                         |  <g transform=\"translate(14,10)\">
                         |    <a xlink:href=\"%9$s\">
                         |    <text style=\"font-size:42pt;\" font-weight=\"bold\" x=\"3%%\" y=\"50\" id=\"theme-name\">%7$s</text>
                         |    <text style=\"font-size:12pt;\" x=\"4%%\" y=\"75\" id=\"theme-description\">%8$s</text>
                         |    <text style=\"font-size:8pt;fill: %5$s\" text-anchor=\"end\" x=\"95%%\" y=\"20\" id=\"theme-url\">%9$s</text>
                         |    </a>
                         |  </g>
                         |  <g transform=\"translate(70,-40)\">
                         |    %10$s
                         |  </g>
                         |</svg>
                         |")))

            (swatch-template
             (or swatch-template
              (autothemer--unindent "<g transform=\"translate(%1$s,%2$s),rotate(%9$s)\">
                         | <ellipse cx=\"70\" cy=\"70\" rx=\"45\" ry=\"45\" id=\"background-color\" fill=\"%3$s\"/>
                         | <ellipse cx=\"70\" cy=\"70\" rx=\"42\" ry=\"42\" id=\"color\" fill=\"%4$s\"/>
                         | <text style=\"font-size:7pt\" font-weight=\"bold\" x=\"52\" y=\"125\" id=\"color-name\">%6$s</text>
                         | <text style=\"font-size:7pt; fill:%5$s;\" font-weight=\"bold\" x=\"52\" y=\"134\" id=\"color\">%4$s</text>
                         | <!-- Rect below is for debug set stroke width to be visible -->
                         |   <rect x=\"0\" y=\"0\" width=\"%7$spx\" height=\"%8$spx\" class=\"debug-rect\" fill-opacity=\"0.0\" stroke-width=\"0.0mm\" stroke=\"#FF8000\"/>
                         |</g>
                         |")))

            (autotheme-name     (autothemer--theme-name autothemer-current-theme))
            (colors             (autothemer--theme-colors autothemer-current-theme))
            (theme-name         (or theme-name (autothemer--theme-name autothemer-current-theme)))
            (theme-description  (or theme-description (autothemer--theme-description autothemer-current-theme)))
            (theme-url          (or theme-url (lm-homepage theme-file) (read-string "Enter theme URL: " "https://github.com/")))

            (font-family        (or font-family        (read-string "Font family name: " "Helvetica Neue")))
            (swatch-width       (or swatch-width       (read-number "Swatch width: " 100)))
            (swatch-height      (or swatch-height      (read-number "Swatch height: " 150)))
            (swatch-rotate      (or swatch-rotate      (read-number "Swatch rotate: " 45)))
            (columns            (or columns            (read-number "Number or columns: " 6)))
            (page-top-margin    (or page-top-margin    (read-number "Page Top margin: " 120)))
            (page-bottom-margin (or page-bottom-margin (read-number "Page Bottom margin: " 60)))
            (page-left-margin   (or page-left-margin   (read-number "Page Left margin: " 30)))
            (page-right-margin  (or page-right-margin  (read-number "Page Right margin: " 30)))
            (h-space            (or h-space            (read-number "Swatch horiztonal spacing: " 10)))
            (v-space            (or v-space            (read-number "Swatch vertical spacing: " 10)))

            (rows (/ (length colors) columns))
            (width (+ page-right-margin page-left-margin
                      (* h-space columns)
                      (* swatch-width columns)))
            (height (+ page-top-margin page-bottom-margin
                       (* v-space rows)
                       (* swatch-height (+ 1 rows))))

            (background-color    (or bg-color            (autothemer--color-value (autothemer--select-color "Select Background color: "))))
            (text-color          (or text-color          (autothemer--color-value (autothemer--select-color "Select Text color: "))))
            (text-accent-color   (or text-accent-color   (autothemer--color-value (autothemer--select-color "Select Text accent color: "))))
            (swatch-border-color (or swatch-border-color (autothemer--color-value (autothemer--select-color "Select swatch border color: "))))
            (sort-palette        (or sort-palette
                                     (list
                                      :sort-fn (read--expression "Sort function (TAB completion, enter nil to skip): " "'autothemer-")
                                      :group-fn (read--expression "Group function (TAB completion, enter nil to skip): " "'autothemer-")
                                      :group-args (read--expression "Group list (TAB completion, enter nil to skip): " "autothemer-"))))
            (visually-group-swatches (or visually-group-swatches (y-or-n-p "Visually group swatches?")))
            (svg-out-file (or svg-out-file (read-file-name (format "Enter a Filename to save SVG palette for %s." theme-name))))

            ;(svg-grouped-swatches ())
            (svg-swatches (string-join
                            (-map-indexed
                             (lambda (index it)
                              (let ((color (autothemer--color-value it))
                                    (name  (upcase (replace-regexp-in-string
                                                    (concat autotheme-name "-") ""
                                                    (format "%s" (autothemer--color-name it)))))
                                    (x (+ page-left-margin (* (+ h-space swatch-width) (% index columns))))
                                    (y (+ page-top-margin (* (+ v-space swatch-height) (/ index columns)))))
                                 (format swatch-template
                                         x
                                         y
                                         swatch-border-color
                                         color
                                         text-accent-color
                                         name swatch-width swatch-height swatch-rotate)))
                             (if sort-palette
                                 (autothemer-groups-to-palette
                                  (autothemer-group-and-sort colors sort-palette))
                               colors))
                            "\n")))
          (with-temp-file svg-out-file
            (insert
             (format page-template
                     width
                     height
                     font-family
                     text-color
                     text-accent-color
                     background-color
                     theme-name
                     theme-description
                     theme-url
                     svg-swatches)))
      (message "%s generated." svg-out-file)))))

(defun autothemer--locate-source ()
  "Return the absolute file path of autothemer source.

Return nil if not found."
  (let* ((lib-file-name "autothemer.el")
         (located-file (file-truename (locate-library "autothemer")))
         (is-byte-compiled (string= "elc" (file-name-extension located-file)))
         (el-name (format "%s.el" (file-name-sans-extension located-file)))
         (located-el (file-truename (if (and is-byte-compiled (file-exists-p el-name))
                                        el-name
                                      located-file)))
         (located-folder (file-name-directory located-el)))
    (if (file-directory-p located-folder)
        located-folder
      nil)))

(provide 'autothemer)
;;; autothemer.el ends here
