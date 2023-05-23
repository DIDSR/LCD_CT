Low Contrast Detectability for CT Toolbox
=========================================
Low Contrast Detectability for CT (LCD-CT) Toolbox provides a common interface to evaluate the low contrast detectability (LCD) performance of advanced nonlinear CT image reconstruction and denoising algorithms. The toolbox uses model observer (MO) to evaluate the LCD of targets with known locations in test images obtained with the MITA-LCD phantom. The model oberver detection accuracy is measured by the area under the receiver operating characteristic curve (AUC) and the detectability signal-to-noise ratio (d’_{snr}).  The LCD-CT toolbox can be used by CT developers to perform initial evaluation on image quality impprovement or dose reduction potential of their reconstruction and denoising algorithms.

.. image:: diagram.png
        :width: 800
        :align: center

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

After installing review the LCD RST Documentation https://lcd-ct.readthedocs.io/en/latest/ and the demos to learn how to use the tool to assess low contrast detectability and to learn more about selecting and optimizing model observers for your task.

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
