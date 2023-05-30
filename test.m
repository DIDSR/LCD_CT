% This is the test script where all functionality of LCD-CT is tested. If the script runs to completion without error the tool is ready for use

use_large_dataset = false

demo_test_phantomcreation

demo_00_images_from_directory

demo_01_singlerecon_LCD

demo_02_tworecon_LCD

demo_03_tworecon_dosecurve_LCD

plot_results(res_table)

disp("tests complete, if no errors were raised LCD-CT installed correctly and is ready for use.")
delete *.csv

