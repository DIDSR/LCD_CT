Frequently Asked Questions
==========================



1. errors when running with Octave for the first time
-----------------------------------------------------

Many linux distributions come with an older version of Octave (typically Octave 4.4) which are incompatible with newer libraries such as Image or tablicious which we use in this tool. If using an older version of Octave you might get error messages like the following:

.. code-block:: octave

    demo_00_images_from_directory.m
    error: package tablicious is not installed
    error: called from
        load_packages at line 41 column 7
        pkg at line 411 column 7
        demo_images_from_directory at line 26 column 4
        test at line 9 column 1

A straightforward way to get a newer version of Octave is with Conda as recommended by the Octave site: https://wiki.octave.org/Octave_for_GNU/Linux

First in a shell terminal create an environment, install octave and a c++ compiler

.. code-block:: shell

  conda create --name octave
  conda activate octave
  conda install -c conda-forge octave
  conda install -c conda-forge cxx-compiler

Then in octave install the packages

.. code-block:: octave

  octave:1> pkg install -forge image
  octave:2> pkg install https://github.com/apjanke/octave-tablicious/releases/download/v0.3.7/tablicious-0.3.7.tar.gz
  octave:3> pkg load image tablicious

Now retry rerunning the `test.m`

.. code-block:: shell

    octave test.m

2. Matlab version errors
------------------------

Both of the error messages below indicate an imcompatible Matlab version (Release before 2016b). To avoid this error consider following the Octave install instructions above

.. code-block:: octave

    ??? Error using ==> test at 10
    Detected version of Matlab: 2007b < (2016b)

or

.. code-block:: octave

    ??? Error: File: ~/LCD_CT/demo_01_singlerecon_LCD.m Line: 13 Column: 14
    The input character is not valid in MATLAB statements or expressions.
