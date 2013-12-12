**************************************************
README.txt on colorimeter settings

Created    : "2013-12-10 14:44:07 ban"
Last Update: "2013-12-10 14:54:49 ban"
**************************************************

[About general notes on colorimeter settings]
1. We have tested Mcalibrator2 with the colorimeters listed below. The other devices are under developing.
   Photo Research PR-650 Photometer
   Konica-Minolta CS-100A
   Admesy Brontes-LL
   Cambridge Research Systems ColorCAL MK2
   Cambridge Research Systems OptiCAL (gamma-correction only)

2. You can easily add your own devices so that it works with Mcalibrator2. For details, please see
   ~/Mcalibrator2/subfunctions/colorimeter/colorimeter_list.m

[About Admesy Brontes-LL]
1. The Brontes colorimeter makes use of standard VISA drivers. VISA drivers for use with the Brontes application
   can be found on the National Instruments website. To run the software, the VISA runtime engine for your platform
   will be needed.

2. To use Admesy Brontes-LL colorimeter with Mcalibrator2 (Windows only), you need to get a runtime "admesy_usbtmc.dll"
   and to place the file in this directory. You can download the latest driver from Admesy website.

[About Cambridge Research Systems ColorCAL/Optical]
1. Mcalibrator2 can communicate with CRS ColorCAL/OptiCAL with "Calibrator.dll" runtime engine (Windows only) distributed
   by Cambridge Research Systems. After you get it from Cambridge Research Systems, please put the file in this directory.
