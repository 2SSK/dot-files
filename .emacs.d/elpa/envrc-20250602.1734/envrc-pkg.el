;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "envrc" "20250602.1734"
  "Support for `direnv' that operates buffer-locally."
  '((emacs      "27.1")
    (inheritenv "0.1")
    (seq        "2.24"))
  :url "https://github.com/purcell/envrc"
  :commit "cb5f6d2a4217c1e2cc963072aaa5ecfe257ab378"
  :revdesc "cb5f6d2a4217"
  :keywords '("processes" "tools")
  :authors '(("Steve Purcell" . "steve@sanityinc.com"))
  :maintainers '(("Steve Purcell" . "steve@sanityinc.com")))
