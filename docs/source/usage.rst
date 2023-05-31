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

.. autoscript:: demo_01_singlerecon_LCD.m

.. autoscript:: demo_02_tworecon_LCD.m

.. autoscript:: demo_03_tworecon_dosecurve_LCD.m

.. image:: https://sandbox.zenodo.org/badge/DOI/10.5072/zenodo.1150650.svg
   :target: https://sandbox.zenodo.org/record/1150650
