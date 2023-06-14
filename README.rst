.. image:: https://zenodo.org/badge/DOI/10.5281/zenodo.7996580.svg
   :target: https://doi.org/10.5281/zenodo.7996580

Low Contrast Detectability for CT Toolbox
=========================================
**Low Contrast Detectability for CT (LCD-CT) Toolbox** provides a common interface to evaluate the low contrast detectability (LCD) performance of advanced nonlinear CT image reconstruction and denoising algorithms. The toolbox uses model observers (MO) to evaluate the LCD of targets with known locations in test images obtained with the `MITA-LCD phantom <https://www.phantomlab.com/catphan-mita>`_. The model oberver detection accuracy is measured by the area under the receiver operating characteristic curve (AUC) and the detectability signal-to-noise ratio (d’_{snr}).  The LCD-CT toolbox can be used by CT developers to perform initial evaluation on image quality impprovement or dose reduction potential of their reconstruction and denoising algorithms.

.. image:: diagram.png
        :width: 800
        :align: center

- **Regulatory Science Tool:** Check the FDA website for a description of the LCD-CT toolbox (*a link to be added*) in the Regulatory Science Tool catalog.
- **How to cite** 
   (*for paper*) Vaishnav, J.Y., Jung, W.C., Popescu, L.M., Zeng, R. and Myers, K.J. (2014), Objective assessment of image quality and dose reduction in CT iterative reconstruction. Med. Phys., 41: 071904. https://doi.org/10.1118/1.4881148

   (*for code*) ... the LCD-CT RST tool...

   (*for data) Nelson, Brandon, Zeng, Rongping. CT Simulations of MITA Low Contrast Detectability Phantom for Model Observer Assessments. Published online May 31, 2023. doi:10.5281/zenodo.7991067

*LCD-CT tool developers: Brandon Nelson, PhD, Prabhat Kc, PhD, Rongping Zeng, PhD*

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

Then open the LCD_CT directory in Matlab or Octave and run `demo_01_singlerecon_LCD.m` to test the LCD estimation code .

- Note that the LCD Phantom Creation code uses functions from `Michigan Image Reconstruction Toolkit (MIRT) <https://github.com/JeffFessler/mirt>`_. If it is not already installed, it will be downloaded and installed automatically. If the automatic download does not work, this can be done manually: 
1) download MIRT from https://github.com/JeffFessler/mirt; 
2) Upzip MIRT to a local directory; 
3) In Matlab, Run the file "setup.m" in the MIRT local directory to add all the MIRT subdirectories to the MATLAB workspace;  

To test whether the setup is successful, run `demo_test_phantomcreation.m`.

- LCD_CT is compatible with Octave, however some functions such as `medfilt2` are not loaded by default, follow the command line instructions, e.g.: `pkg load image` to have `medfilt2` available, this only needs to be done once for a given Octave session.

Getting Started
---------------

After installing review the LCD RST Documentation https://lcd-ct.readthedocs.io/en/latest/ and the demos to learn how to use the tool to assess low contrast detectability:

- demo_01_singlerecon_LCD.m
- demo_02_tworecon_LCD.m
- demo_03_tworecon_dosecurve_LCD.m

Additional demos of tool usage can be found in additional_demos

.. image:: lcd_v_dose.png
        :width: 800
        :align: center

Contribute
----------

- Issue Tracker: https://github.com/DIDSR/LCD_CT/issues
- Source Code: https://github.com/DIDSR/LCD_CT
- Contributing Guide: https://lcd-ct.readthedocs.io/en/latest/contributing.html

Support
-------

If you are having issues, please let us know.
brandon.nelson@fda.hhs.gov; rongping.zeng@fda.hhs.gov

License
-------

The project is licensed under `Creative Commons Zero v1.0 Universal LICENSE`_.

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
- to be added: noise insertion code from Prabhat's GitHub site
