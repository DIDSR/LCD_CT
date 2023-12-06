.. image:: https://zenodo.org/badge/DOI/10.5281/zenodo.7996580.svg
   :target: https://doi.org/10.5281/zenodo.7996580

Low Contrast Detectability for CT Toolbox
=========================================
**Low Contrast Detectability for CT (LCD-CT) Toolbox** provides a common interface to evaluate the low contrast detectability (LCD) performance of advanced nonlinear CT image reconstruction and denoising algorithms. The toolbox uses model observers (MO) to evaluate the LCD of targets with known locations in test images obtained with the `MITA-LCD phantom <https://www.phantomlab.com/catphan-mita>`_. The model oberver detection accuracy is measured by the area under the receiver operating characteristic curve (AUC) and the detectability signal-to-noise ratio (d’_{snr}).  The LCD-CT toolbox can be used by CT developers to perform initial evaluation on image quality impprovement or dose reduction potential of their reconstruction and denoising algorithms.

.. image:: diagram.png
        :width: 800
        :align: center

- **Regulatory Science Tool:** Check the FDA website for a description of the LCD-CT toolbox in the Regulatory Science Tool catalog:  https://www.fda.gov/medical-devices/science-and-research-medical-devices/lcd-ct-low-contrast-detectability-lcd-test-assessing-advanced-nonlinear-ct-image-reconstruction-and
- **How to cite** 
   (*for paper*) Vaishnav, J.Y., Jung, W.C., Popescu, L.M., Zeng, R. and Myers, K.J. (2014), Objective assessment of image quality and dose reduction in CT iterative reconstruction. Med. Phys., 41: 071904. https://doi.org/10.1118/1.4881148

   (*for tool*) LCD-CT: Low-contrast detectability (LCD) test for assessing advanced nonlinear CT image reconstruction and denoising methods. https://www.fda.gov/medical-devices/science-and-research-medical-devices/lcd-ct-low-contrast-detectability-lcd-test-assessing-advanced-nonlinear-ct-image-reconstruction-and

   (*for data*)  Nelson, B., Zeng, R., CT Simulations of MITA Low Contrast Detectability Phantom for Model Observer Assessments. Published online June 1st, 2023. doi:10.5281/zenodo.7996580 

*Toolbox developers: Brandon Nelson, PhD, Rongping Zeng, PhD*

Disclaimer
--------
This software and documentation (the "Software") were developed at the Food and Drug Administration (FDA) by employees of the Federal Government in the course of their official duties. Pursuant to Title 17, Section 105 of the United States Code, this work is not subject to copyright protection and is in the public domain. Permission is hereby granted, free of charge, to any person obtaining a copy of the Software, to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, or sell copies of the Software or derivatives, and to permit persons to whom the Software is furnished to do so. FDA assumes no responsibility whatsoever for use by other parties of the Software, its source code, documentation or compiled executables, and makes no guarantees, expressed or implied, about its quality, reliability, or any other characteristic. Further, use of this code in no way implies endorsement by the FDA or confers any advantage in regulatory decisions. Although this software can be redistributed and/or modified freely, we ask that any derivative works bear some notice that they are derived from it, and any modified versions bear some notice that they have been modified.

Features
--------

- Creating digital replica of the background and signal modules of the MITA-LCD phantom https://www.phantomlab.com/catphan-mita.  
- Simuating sinogram and generate fan-beam CT scans of the digital phantoms based on the publicly available Michigan Image Reconstruction Tolbox (MIRT) https://github.com/JeffFessler/mirt.
- Estimating low contrast detectability performance from the MITA-LCD phantom CT images using channelized Hoteling model observer with Laguerre-Gauss (LG) channels and two options of Difference-of-Gaussian (DOG) channels and Gabor channels.

.. _installation:

Installation
------------

- Install Low Contrast Detectability for CT Toolbox by running:

    git clone https://github.com/DIDSR/LCD_CT

Then open the LCD_CT directory in Matlab (**version > R2016a**) or Octave (**version > 4.4**) and run `demo_01_singlerecon_LCD.m` to test the LCD estimation code.

If neither Matlab or Octave are installed, or you do not have an appropriate version please see `install.sh` to prepare an environment

.. code-block:: shell

        source install.sh

- Note that the LCD Phantom Creation code uses functions from `Michigan Image Reconstruction Toolkit (MIRT) <https://github.com/JeffFessler/mirt>`_. If it is not already installed, it will be downloaded and installed automatically when 'demo_test_phantomcreation.m' is run. If the automatic download does not work (possibly due to matlab upzip() function did not successfully extracted all the files), this can be done manually: 
1) download MIRT from https://github.com/JeffFessler/mirt; 
2) Upzip MIRT to a local directory; 
3) In Matlab, Run the file "setup.m" in the MIRT local directory to add all the MIRT subdirectories to the MATLAB workspace;  

To test whether the setup is successful, run **demo_test_phantomcreation.m**.

- LCD_CT is compatible with Octave, however some functions such as `medfilt2` are not loaded by default, follow the command line instructions, e.g.: `pkg load image` to have `medfilt2` available, this only needs to be done once for a given Octave session.

Getting Started
---------------

After installing review the LCD RST Documentation https://lcd-ct.readthedocs.io/en/latest/ and the demos to learn how to use the tool to assess low contrast detectability:

- **demo_01_singlerecon_LCD.m**
- **demo_02_tworecon_LCD.m**
- **demo_03_tworecon_dosecurve_LCD.m**

Additional demos of tool usage can be found in additional_demos.

The following AUC-vs-dose curves were generated by demo_03_tworecon_dosecurve_LCD.m using the large data set saved in zonodo (https://zenodo.org/record/7996580) and the LG channelized Hoteling model observer.

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

Additional resources
------------

- DIDSR/IQModelo: https://github.com/DIDSR/IQmodelo

  - Statistical Software for Task-Based Image Quality Assessment with Model (or Human) Observers

- DIDSR/VICTRE_MO: https://github.com/DIDSR/VICTRE_MO
- Example of CT image noise insertion code: https://github.com/prabhatkc/ct-recon/tree/main/error_analysis/cho_lcd#readme
