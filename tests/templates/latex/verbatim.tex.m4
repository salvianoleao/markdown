\documentclass{minimal}
\csname UseRawInputEncoding\endcsname
% Load the package.
\usepackage[theme=test]{markdown}
% Load the support files.
\input setup\relax
% Load the test-specific setup.
\input TEST_SETUP_FILENAME\relax
\begin{document}
% Perform the test.
\begin{markdown}
undivert(TEST_INPUT_FILENAME)dnl
\end{markdown}
\end{document}
