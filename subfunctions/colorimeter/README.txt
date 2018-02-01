**************************************************
README.txt on colorimeter settings

Created    : "2013-12-10 14:44:07 ban"
Last Update: "2017-06-30 10:03:53 ban"
**************************************************

[About general notes on colorimeter settings]
1. We have tested Mcalibrator2 with the colorimeters listed below. The other devices are under developing.
   Photo Research PR-650 Photometer
   Konica-Minolta CS-100A
   Admesy Brontes-LL
   Cambridge Research Systems ColorCAL MK2
   Cambridge Research Systems OptiCAL (gamma-correction only)

2. In addition to the colorimeter listed above, you can easily add your own devices so that it works
    with Mcalibrator2. For details, please see ~/Mcalibrator2/subfunctions/colorimeter/colorimeter_list.m

[About Admesy Brontes-LL]
1. The Brontes colorimeter makes use of standard VISA drivers. VISA drivers for use with the Brontes application
   can be found on the National Instruments website. To run the software, the VISA runtime engine for your platform
   will be needed.

2. To use Admesy Brontes-LL colorimeter with Mcalibrator2 (Windows only), you need to get a runtime
   1. admesy_usbtmc.dll (with the "brontesLL_win32_with_old_driver" class)
   or
   1. libusbtmc_x{86|64}.dll (with the "brontesLL" class)
   2. libusbtmc.h
   and to place the file in this directory. You can download the latest driver from Admesy website.

[About Cambridge Research Systems ColorCAL/Optical]
1. Mcalibrator2 can communicate with CRS ColorCAL2/OptiCAL through a virtual serial port via USB connections (Windows only).
   To use those apparatus, please download the valid drivers (both 32 and 64 bit drivers are available with Mcalibrator2)
   distributed by Cambridge Research Systems.
