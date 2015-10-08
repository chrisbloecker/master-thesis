A Process Calculus for Parallel and Distributed Programming in Haskell
===============
__Please note__: This README.md is rather informal and I added it __after__ submitting my thesis, its content is __not__ part of the thesis.

# Abstract
Parallel and distributed programming usually aim at speeding up the execution of a program, but as a side-effect introduce a rather large amount of boilerplate code. This boilerplate code can be avoided by moving to a higher level of abstraction and utilising a process calculus to express the program as a combination of processes. The process calculus provides combinators to create basic process and combine them to more complicated process by _sequential_ or _parallel_ composition, by _repetition_ or the _choice_ between processes. Using an interpreter, the processes can be transformed into an equivalent, more optimal representation and then be executed; it also hides the boilerplate code that would usually arise in the composition of processes.

# Implementation
The implementation has been done in Haskell and can be found in [this github repository](https://github.com/chrisbloecker/hive).

# Getting the Document
You can either download the document [from here](https://github.com/chrisbloecker/master-thesis/releases/download/v1.0/Master.Thesis.Christopher.Blocker.pdf) or clone this repository and compile it yourself. You will need to have __pdflatex__, __bibtex__ and __makeindex__ installed for this.
```
git clone https://github.com/chrisbloecker/master-thesis.git
cd master-thesis
make
```
