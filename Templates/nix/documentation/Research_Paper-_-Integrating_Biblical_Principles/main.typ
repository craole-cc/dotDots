#set page(
  paper: "us-letter",
  margin: 1in,
  numbering: "1",
  number-align: top + right,
)

#set text(
  font: "TeX Gyre Termes",
  size: 12pt,
)

#set par(
  justify: true,
  leading: 1.7em,
  first-line-indent: 0.5in,
)

#set heading(
  numbering: none,
)

#show heading: it => [
  #v(1.1em)
  #align(center)[#text(weight: "bold")[#it.body]]
  #v(0.6em)
]

#align(center)[
  #v(1.5in)
  #text(weight: "bold")[A Faith-Integrated Approach to the Care of Major Depressive Disorder]
  #v(1.2em)
  Winsome Cole
  #v(0.85em)
  Caribbean Bible Institute
  #v(0.85em)
  Tamar Reynolds
  #v(0.85em)
  May 15, 2026
]

#pagebreak()
#include "sections/01-introduction.typ"
#include "sections/02-biblical-principles.typ"
#include "sections/03-counselling-theories.typ"
#include "sections/04-integration.typ"
#include "sections/05-critical-evaluation.typ"
#include "sections/06-conclusion.typ"

#pagebreak()
= References
#bibliography("references.bib", style: "apa", title: none)
