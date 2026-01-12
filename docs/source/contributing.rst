Contributing Guide
==================

`Issue Tracker <https://github.com/DIDSR/LCD_CT/issues>`_ | `Source Code <https://github.com/DIDSR/LCD_CT>`_ | `Contributing Guide <https://lcd-ct.readthedocs.io/en/latest/contributing.html>`_

- **How to cite** 
   (*for paper*) Vaishnav, J.Y., Jung, W.C., Popescu, L.M., Zeng, R. and Myers, K.J. (2014), Objective assessment of image quality and dose reduction in CT iterative reconstruction. Med. Phys., 41: 071904. https://doi.org/10.1118/1.4881148

   (*for tool*) LCD-CT: Low-contrast detectability (LCD) test for assessing advanced nonlinear CT image reconstruction and denoising methods. https://www.fda.gov/medical-devices/science-and-research-medical-devices/lcd-ct-low-contrast-detectability-lcd-test-assessing-advanced-nonlinear-ct-image-reconstruction-and

   (*for data*)  Nelson, B., Zeng, R., CT Simulations of MITA Low Contrast Detectability Phantom for Model Observer Assessments. Published online June 1st, 2023. doi:10.5281/zenodo.7996580 

Support
-------

If you are having issues, please let us know.

*Toolbox developers: Brandon Nelson (brandon.nelson@fda.hhs.gov), PhD, Rongping Zeng, PhD (rongping.zeng@fda.hhs.gov)*


One of the best ways to contribute is by improving our documentation. This project uses sphinx <https://www.sphinx-doc.org/en/master/tutorial/narrative-documentation.html> as a documentor, and specific details for the Matlab Domain are given here: <https://github.com/sphinx-contrib/matlabdomain>

More resources on documentation: https://www.writethedocs.org/guide/




.. _docstrings_ref:

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

.. code-block:: rst

	usage

	api

	my_new_doc_page

Writting rst files
------------------

reStructuredText is mostly plain text with a few special rules for defining headers and cross-references. Like `Markdown <https://en.wikipedia.org/wiki/Markdown>`_, it is a common format for writing technical documentation for software. "rst" stands for `reStructuredText <https://en.wikipedia.org/wiki/ReStructuredText>`_. The content in the :ref:`docstrings_ref` after the comment symbol "%" is also written in rst format.

For examples of how to write rst files, you can use look at the `raw source <https://github.com/bnel1201/LCD-CT/edit/main/docs/source/contributing.rst>`_ of this page. More complete references on writing rst files and code documentation can be found here:

- `basics of restructured text (rst files) <https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html>`_
- `writing docstrings in rst format <https://sphinx-rtd-tutorial.readthedocs.io/en/latest/docstrings.html>`_
