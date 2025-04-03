# Linearizing PTB Screens

When linearizing a screen that will use PTB functions for display (i.e. 
**Screen**) instead of the VSG/Visage, we use the PsychToolbox calibration 
methods with changes to use our PR650 and associated functions. 

The PR650 toolbox shipped with PTB does not work with our spectrometer. I replaced
the entire suite of PR650 functions found in PTB folder *PsychHardware/PR650Toolbox*
with the functions named **old650***. Each function takes the same parameters and 
returns the same values. 

For the calibration process, the device-specific functions (i.e. those which rely on 
specific hardware functions for the PR650) are isolated in 4 functions: **CMCheckInit**,
**CMClose**, **PR650measspd**, and **CalibrateMonSpd**. The folder containing these
functions (ptbcal folder in this repo) should be in your Matlab path BEFORE the PTB folders,
in order for the calibration to run correctly. 


