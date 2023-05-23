Low Contrast Detectability for CT Toolbox
=========================================
**Low Contrast Detectability for CT (LCD-CT) Toolbox** provides a common interface to evaluate the low contrast detectability (LCD) performance of advanced nonlinear CT image reconstruction and denoising algorithms. The toolbox uses model observer (MO) to evaluate the LCD of targets with known locations in test images obtained with the MITA-LCD phantom. The model oberver detection accuracy is measured by the area under the receiver operating characteristic curve (AUC) and the detectability signal-to-noise ratio (d’_{snr}).  The LCD-CT toolbox can be used by CT developers to perform initial evaluation on image quality impprovement or dose reduction potential of their reconstruction and denoising algorithms.

.. image:: diagram.png
        :width: 800
        :align: center

**Regulatory Science Tool:** Check the FDA website for a description of the LCD-CT toolbox in the Regulatory Science Tool catalog.

*LCD-CT team: Brandon Nelson, PhD, Prabhat Kc, PhD, Rongping Zeng, PhD*

Disclaimer
--------
This software and documentation (the "Software") were developed at the Food and Drug Administration (FDA) by employees of the Federal Government in the course of their official duties. Pursuant to Title 17, Section 105 of the United States Code, this work is not subject to copyright protection and is in the public domain. Permission is hereby granted, free of charge, to any person obtaining a copy of the Software, to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, or sell copies of the Software or derivatives, and to permit persons to whom the Software is furnished to do so. FDA assumes no responsibility whatsoever for use by other parties of the Software, its source code, documentation or compiled executables, and makes no guarantees, expressed or implied, about its quality, reliability, or any other characteristic. Further, use of this code in no way implies endorsement by the FDA or confers any advantage in regulatory decisions. Although this software can be redistributed and/or modified freely, we ask that any derivative works bear some notice that they are derived from it, and any modified versions bear some notice that they have been modified.

Features
--------

- Creating digital replica of the background and signal modules of the MITA-LCD phantom https://www.phantomlab.com/catphan-mita.  
- Simuating sinogram and generate fan-beam CT scans of the digital phantoms based on the publicly available Michigan Image Reconstruction Tolbox (MIRT) https://github.com/JeffFessler/mirt.
- Estimating low contrast detectability performance from the MITA-LCD phantom CT images using model observer.

.. _installation:

Installation
------------

- Install Low Contrast Detectability for CT Toolbox by running:

    git clone https://github.com/DIDSR/LCD_CT

Then open the LCD_CT directory in Matlab and run "demo_00_test_smalldata.m" to test the LCD estimation code .

- Note that the LCD Phantom Creation code uses functions from Michigan Image Recosntruction Toolkit (MIRT). Following the following steps to make the MIRT functions ready in Matlab path to support the run of LCD phantom creation code: 
1) download MIRT from https://github.com/JeffFessler/mirt; 
2) Upzip MIRT to a local directory; 
3) In Matlab, Run the file "setup.m" in the MIRT local directory to add all the MIRT subdirectories to the MATLAB path;  

Then test whether the setup is successful by runing "demo_test_phantomcreation.m".

- LCD_CT is compatible with Octave, however some functions such as `medfilt2` are not loaded by default, follow the command line instructions, e.g.: `pkg load image` to have `medfilt2` available, this only needs to be done once for a given Octave session.

Getting Started
---------------

After installing review the LCD RST Documentation https://lcd-ct.readthedocs.io/en/latest/ and the demos to learn how to use the tool to assess low contrast detectability:

- demo_xx
- demo_xx

Contribute
----------

- Issue Tracker: https://github.com/DIDSR/LCD_CT/issues
- Source Code: https://github.com/DIDSR/LCD_CT

This project uses sphinx <https://www.sphinx-doc.org/en/master/tutorial/narrative-documentation.html>, and specific details for the Matlab Domain: <https://github.com/sphinx-contrib/matlabdomain>

More resources on documentation: https://www.writethedocs.org/guide/

Support
-------

If you are having issues, please let us know.
brandon.nelson@fda.hhs.gov

License
-------

The project is licensed under the BSD license.

Alternatives
------------

- Duke CVIT Observer Models: https://cvit.duke.edu/resource/observer_model/

  - Inputs: simulated image data from Duke's CVIT Pipeline
  - Outputs: detectability indices for different signal-known-exactly model observers:
     1. Non-prewhitening matched filter
     2. Prewhitened matched filter

- DIDSR/IQModelo: https://github.com/DIDSR/IQmodelo

  - Statistical Software for Task-Based Image Quality Assessment with Model (or Human) Observers

- DIDSR/VICTRE_MO: https://github.com/DIDSR/VICTRE_MO
