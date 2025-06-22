;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "evil" "20250318.1816"
  "Extensible vi layer."
  '((emacs    "24.1")
    (cl-lib   "0.5")
    (goto-chg "1.6")
    (nadvice  "0.3"))
  :url "https://github.com/emacs-evil/evil"
  :commit "682e87fce99f39ea3155f11f87ee56b6e4593304"
  :revdesc "682e87fce99f"
  :keywords '("emulations")
  :maintainers '(("Tom Dalziel" . "tom.dalziel@gmail.com")))
