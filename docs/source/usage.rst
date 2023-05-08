Usage
=====

Intended Purpose
----------------

The LCD-CT software tool is intended for quantitatively evaluating the Low contrast detectability (LCD) performance of advanced nonlinear CT image reconstruction and denoising products using the MITA-LCD phantom images.

Intended users are CT device developers and  image denoising and processing software developers. Advanced nonlinear CT image reconstruction and denoising methods (products code JAK_, QIH_, LLZ_ among others) includes statistically iterative, model-based iterative and deep learning-based image reconstruction and denoising methods.

.. _JAK: https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfPCD/classification.cfm?id=5631

.. _QIH: https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfPCD/classification.cfm?id=5704

.. _LLZ: https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfPCD/classification.cfm?id=5654

The LCD performance obtained using the LCD-CT tools can help the assessment of image quality imprvoment and quantitative dose reduction potential of advanced nonlinear CT image reconstruction and denoising methods with respect to a reference reconstruction option such as the FBP method. 

Demos
-----
These demos are intended to be run linearly and demonstrate the use of the LCD-CT tool and how it can be used in more sophisticated loops to understand LCD relationships with different imaging conditions, lesions, and model observer types.

0. Images from a Directory
^^^^^^^^^^^^^^^^^^^^^^^^^^

`demo_00_images_from_directory.m <./_static/demo_00_images_from_directory.html>`_

- demonstrates basics of loading signal-absent and signal-present image series in a 3D array to run a single model-observer study using provided small dataset
- This script also demonstrates how to load up multiple different types of Model Observer

1. Repeated Studies
^^^^^^^^^^^^^^^^^^^

`demo_01_repeat_studies.m <./_static/demo_01_repeat_studies.m>`_

- builds upon `demo_00_images_from_directory.m <./_static/demo_00_images_from_directory.html>`_ by demonstrating how to perform repeat studies to get a uncertainty estimates and export results to a csv file

2. Multiple Dose Levels
^^^^^^^^^^^^^^^^^^^^^^^

`demo_02_multiple_dose_levels.m <./_static/demo_02_multiple_dose_levels.m>`_

- builds upon `demo_01_repeat_studies.m <./_static/demo_01_repeat_studies.m>`_ by demonstrating how to perform repeat studies at multiple dose levels to get detectability (e.g. auc or snr) as a function of dose level for multiple different observers

3. Accessing a large dataset
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

`demo_03_access_large_dataset.m <./_static/demo_03_access_large_dataset.m>`_

- builds upon `demo_02_multiple_dose_levels.m <./_static/demo_02_multiple_dose_levels.m>`_ by demonstrating how to perform repeat studies at multiple dose levels to get detectability (e.g. auc or snr) as a function of dose level for multiple different observers
- The large dataset used can be downloaded here:

.. image:: https://sandbox.zenodo.org/badge/DOI/10.5072/zenodo.1150650.svg
   :target: https://sandbox.zenodo.org/record/1150650
