;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "kubernetes-evil" "20220625.534"
  "Kubernetes keybindings for evil-mode."
  '((kubernetes "0.18.0")
    (evil       "1.2.12"))
  :url "https://github.com/kubernetes-el/kubernetes-el"
  :commit "b155d64aa72bd1175770db3518a67a347caa36dd"
  :revdesc "b155d64aa72b"
  :authors '(("Chris Barrett" . "chris+emacs@walrus.cool"))
  :maintainers '(("Chris Barrett" . "chris+emacs@walrus.cool")))
