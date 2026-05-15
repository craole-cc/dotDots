/* ---------------------------
  TITLE (no page number)
---------------------------- */
#set page(
  paper: "us-letter",
  margin: 1in,
  numbering: none,
)

#set text(
  font: "Times New Roman",
  size: 12pt,
  hyphenate: false,
)

#set par(
  justify: true,
  leading: 1.8em,
  spacing: 24pt,
  first-line-indent: 0.5in,
)

#set heading(
  numbering: none,
)

#show heading: it => [
  #v(0.8em)
  #align(center)[#text(weight: "bold")[#it.body]]
  #v(0.4em)
]

#align(center)[
  #v(1.5in)
  #text(
    weight: "bold",
  )[A Faith-Integrated Approach to the Care of Major Depressive Disorder]
  #v(1.2em)
  Winsome Cole
  #v(0.85em)
  Christian Counselling
  #v(0.85em)
  Caribbean Bible Institute
  #v(0.85em)
  Tamar Royal-Reynolds
  #v(0.85em)
  May 15, 2026
]
/* ---------------------------
  BODY (numbering starts here)
---------------------------- */
#pagebreak(weak: false)

#counter(page).update(1)
#set page(
  numbering: "1",
  number-align: top + right,
)

#counter(page).update(1)
#include "pages/01-introduction.typ"
#include "pages/02-biblical-principles.typ"
#include "pages/03-counselling-theories.typ"
#include "pages/04-integration.typ"
#include "pages/05-critical-evaluation.typ"
#include "pages/06-conclusion.typ"

/* ---------------------------
  REFERENCES
---------------------------- */
#pagebreak()

#set par(
  justify: false,
  leading: .8em,
  spacing: 18pt,
)

#bibliography("pages/references.bib", style: "american-psychological-association", title: "References")
