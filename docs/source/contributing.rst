Contributing Guide
==================

.. _docstrings:

docstrings
----------

The easiest and most effective way to start contributing to the user manual and documentation of the project is by helping improve our docstrings, these are the comments just below the function signature in Matlab before the function content. Here is a simple example in matlab:

.. code-block:: matlab

  function [res] = my_sum(a, b)
  % returns the sum of a and b
  %
  % :param a: first argument to sum
  % :param b: second argument to sum
  %
  % :return: res: the result
  end
  
These commented lines will be exported and make up the documentation for the function "my_sum"

Adding new pages to the user manual
-----------------------------------

Contributing Other pages to the manual can be done by creating a new text file with the file extension ".rst" in the "LCD-CT/docs/source" folder. ".rst" stands for `reStructuredText <https://en.wikipedia.org/wiki/ReStructuredText>`_. The content in the :ref:`docstrings` after the comment symbol "%" is also written in reStructuredText, which is mostly plain text with a few special rules for defining headers and cross-references. You can use look at the raw source of this page for examples of how to write rst files or check out these resources for more:

- https://sphinx-rtd-tutorial.readthedocs.io/en/latest/docstrings.html
- https://dev.to/zenulabidin/sphinx-docstring-best-practices-2fca
