Contributing Guide
==================

.. _docstrings:

docstrings
----------

The easiest and most effective way to start contributing to the user manual and documentation of the project is by helping improve our `docstrings <https://www.mathworks.com/help/matlab/matlab_prog/add-help-for-your-program.html>`_, these are the comments just below the function signature in Matlab before the function content. Here is a simple example in matlab:

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

Contributing other pages to the manual requires two steps: 

1. Create a new text file with the file extension ".rst" in the `LCD-CT/docs/source <https://github.com/bnel1201/LCD-CT/tree/main/docs/source>`_ folder. 

2. Add the filename without the extension to `docs/source/index.rst <https://github.com/bnel1201/LCD-CT/blob/main/docs/source/index.rst>`_, specifically adding to the list under "toctree". For example, after creating a new manual page called "my_new_doc_page.rst", the list item under toctree would be the following:

	toctree::

	usage

	api

	my_new_doc_page

"rst" stands for `reStructuredText <https://en.wikipedia.org/wiki/ReStructuredText>`_. The content in the :ref:`docstrings` after the comment symbol "%" is also written in reStructuredText, which is mostly plain text with a few special rules for defining headers and cross-references. You can use look at the raw source of this page for examples of how to write rst files or check out these resources for more:

- https://sphinx-rtd-tutorial.readthedocs.io/en/latest/docstrings.html
- https://dev.to/zenulabidin/sphinx-docstring-best-practices-2fca
