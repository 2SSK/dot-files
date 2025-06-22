;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "kubernetes" "20250330.1936"
  "Magit-like porcelain for Kubernetes."
  '((dash          "2.12.0")
    (magit-section "3.1.1")
    (magit-popup   "2.13.0")
    (with-editor   "3.0.4")
    (request       "0.3.2")
    (s             "1.12.0")
    (transient     "0.3.0"))
  :url "https://github.com/kubernetes-el/kubernetes-el"
  :commit "938ef502414d093de827bf7f11bdb30843878a37"
  :revdesc "938ef502414d"
  :keywords '("kubernetes")
  :authors '(("Chris Barrett" . "chris+emacs@walrus.cool"))
  :maintainers '(("Chris Barrett" . "chris+emacs@walrus.cool")
                 ("Noorul Islam K M" . "noorul@noorul.com")
                 ("Jonathan Jin" . "me@jonathanj.in")))
