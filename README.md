This is the code for my solution to the [See Click Predict Fix](http://www.kaggle.com/c/see-click-predict-fix/) competition, as described [here](http://users.cecs.anu.edu.au/~jpetterson/papers/2013/Pet13.pdf).

Author: James Petterson

## External dependencies

* [R](http://cran.r-project.org/) (version used: 2.15.1)
* R libraries:
  * doMC
  * caret
  * gbm
  * nnet
  * randomForest
  * reshape2
* [ruby](https://www.ruby-lang.org/) (version used: 1.9.3p194)
* [Vowpal Wabbit](https://github.com/JohnLangford/vowpal_wabbit/wiki) (version used: 7.0.1)
* [word2vec](https://code.google.com/p/word2vec/) (version used: 0.1b)

All modelling was done in a 4-core MacBook Pro laptop running OSX 10.8.5.

## Notes on running the code

- the path in `config.R` should point to the location where the data files are stored
- both `word2vec` and `vw` are assumed to be in the search path
- the code entry point is the file `do.sh`: it lists all commands that need to be executed to reproduce all results


## License

Copyright (c) 2013, James Petterson

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

