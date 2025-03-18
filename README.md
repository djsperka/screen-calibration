# screen-calibration

Usrey Lab screen calibration steps. 
Notes about [restoring PR650 ICM card here](pr650.md).

## Install PsychToolbox

Check if already installed. If not installed, follow instructions [here](http://psychtoolbox.org/download). You will be directed to install GStreamer first, then PsychToolbox. 

```
>> PsychtoolboxVersion

ans =

    '3.0.17 - Flavor: beta - Corresponds to SVN Revision 12087
     For more info visit:
     https://github.com/Psychtoolbox-3/Psychtoolbox-3'
```

## Install CRS Toolbox

CRS has a toolbox for Matlab. Here is the [download link](https://www.crsltd.com/tools-for-vision-science/visual-stimulation/crs-toolbox-for-matlab/) 
(may require login to myCRS account). 

## Install USB drivers for spectrometer

On Usrey machines this is already done. Here is a [link to the installer](https://ucdavis.box.com/s/oideee2qbi4ef4kfd761zd7dngkis5kd) (from my box acct). 
If the COM port does not appear when you power on the spectrometer and connect it to USB, then the drivers may not be installed. See step NNN below. 

## Setup spectrometer, gather information

Set approx same distance as subject, eye level. Gather information...
1. Get the COM port being used by the spectrometer driver. Open Windows Device Manager (W-x M), then open *Ports (COM & LPT)*. You should see something like this:

![Image of Device Manager](./images/devmgr.PNG)

2. Measure screen distance in m. 
3. Check VSG monitor setup in VSG Desktop, note the *VSG S/N, refresh rate, resolution*

## Calibrate!

This whole process takes approximately 45 minutes. Most of that is in the color measurements. The ambient step takes just a couple of minutes. 

### Initialize spectrometer

This step depends on the spectrometer. For the newer PR670, the PTB functions will work fine:

```
>> PR670init

ans =

    ' REMOTE MODE'
```

For the PR650, the PTB functions do not work (there is a folder of PR650 functions under PsychHardware/, but they appear to be copies of PR670 functions and do not work. The communication protocol seems to have changed with the PR655 and subsequent models. So, I have rewritten a subset of the PTB functionality and spliced it into our calibration function. To initialize the PR650:

```
>> old650init('com1');
>>
```

### Run main calibration

The argument below specifies the spectrometer type. Here are the types as of my version of PTB (3.0.17):

Meter type | argument
---------- | --------
PR650      | 1
PR655      | 4
PR670      | 5
PR705      | 6

```
>> cal = CalibrateVSGDrvr(5);
photometer distance (m): .52
Rig: bigal
Monitor: Barco
VSG s/n7212-407e
Refresh rate (Hz): 120
Initializing VSG, turn off gamma correction...
Focus radiometer on box and hit Enter when ready...
Pausing for 10 seconds ... done
Monitor device 1
making measurement 1..., color (0, 0, 0)
making measurement 1..., color (0.75, 0, 0)
making measurement 2..., color (0.375, 0, 0)
making measurement 3..., color (0.875, 0, 0)
making measurement 4..., color (1, 0, 0)
making measurement 5..., color (0.625, 0, 0)
making measurement 6..., color (0.125, 0, 0)
making measurement 7..., color (0.25, 0, 0)
making measurement 8..., color (0.5, 0, 0)
making measurement 1..., color (0, 0, 0)
Monitor device 2
making measurement 1..., color (0, 0, 0)
making measurement 1..., color (0, 1, 0)

... (more measurements here, depends on settings in initial calibration struct)

making measurement 8..., color (0, 0.875, 0)
making measurement 1..., color (0, 0, 0)
Monitor device 3
making measurement 1..., color (0, 0, 0)
making measurement 1..., color (0, 0, 0.625)
making measurement 2..., color (0, 0, 0.25)
making measurement 3..., color (0, 0, 0.125)
making measurement 4..., color (0, 0, 0.875)
making measurement 5..., color (0, 0, 0.75)
making measurement 6..., color (0, 0, 1)
making measurement 7..., color (0, 0, 0.375)
making measurement 8..., color (0, 0, 0.5)
making measurement 1..., color (0, 0, 0)
CalibrateMonDrvr measurements took 45.5881 minutes
Computing linear models
Fitting with simple power function
Exponent for device 1 is 1.89518
Exponent for device 2 is 1.92071
Exponent for device 3 is 1.89616
Simple power function fit, RMSE: 0.0160455
Fitting with extended power function
Extended power function fit, RMSE: 0.0160455
```

### Run Ambient calibration

This one is simpler, will take just a couple of minutes. 

```
>> cal = CalibrateVSGAmbDrvr(cal, 5);
Initializing VSG, turn off gamma correction...
Focus radiometer on box and hit Enter when ready...
Pausing for 10 seconds ... done
making measurement 1..., color (0, 0, 0)
making measurement 1..., color (0, 0, 0)
CalibrateAmbDrvr measurements took 1.55238 minutes
```

#### Warning messages during calibration with PR650

The PR650 doesn't do as well as the PR670 in low light conditions. In particular, the sync frequency is harder to obtain, and it often fails during the calibration. The measurement function old650measspd will turn off sync when this happens and still makes the measurement. The warnings look like this:

```
making measurement 8..., color (0, 0, 0.25)
Got bad quality code (20) getting sync freq.
Cannot sync, will measure without sync
Warning: The specified amount of data was not returned within the Timeout period for 'readline'.
'serialport' unable to read any data. For more information on possible reasons, see serialport Read Warnings. 
```

The _"Cannot sync"_ error has to do with the low light conditions. 

The timeout warning happens on some of the serial reads and can be ignored. TODO - these can be fixed so they don't happen. 

### Save calibration file

This should be saved in the 'vsg' folder inside this repo's code. 

```
>> SaveCalFile(cal, 'bigal-05072021', 'd:\work\screen-calibration\vsg');
```

### Generate inverse gamma table for Visage programs

The Visage requires the inverse gamma table, specified as _short int, -32768 <= x <= 32767_. This script computes it and 
saves the data in a file alongside the calibration file (with extension _.vsg_). 

```
>> writeVSGGamma('d:\work\screen-calibration\vsg\bigal-05072021');

Loading cal "bigal-05072021" from folder d:\work\screen-calibration\vsg
Calibration:
  * Computer: bigal
  * Screen: 0
  * Monitor: Barco
  * Video driver: 7212-407e
  * Dac size: 14
  * Frame rate: 120 hz
  * Calibration performed by whoever
  * Calibration performed on 07-May-2021 10:40:52
  * Calibration program: tbd
  * Comment: no comment
  * Calibrated device has 3 primaries
  * Gamma fit type crtGamma

Enter gamma method [0]:
Luminance range in isoluminant plane is 28.33 to 28.33
```
