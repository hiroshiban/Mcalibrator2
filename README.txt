**************************************************
README.txt on Mcalibrator2

Created    : "2013-05-13 12:30:52 ban"
Last Update: "2013-12-12 17:17:25 ban"
**************************************************

[about]

Mcalibrator2 is a MATLAB-based display luminance/chromaticity
characterization software package. For details, please read
documents in ~/Mcalibrator2/doc directory.

Thank you for using our software. We are happy if Mcalibrator2
can help your research projects.


[System Requirements]

- OS: Windows XP/VISTA/7/8 and Mac OSX
  note 1: Windows is required to use some photometer as their
          drivers are only compatible with Windows.
  note 2: On MacOSX box, an interface to a virtual serial port
          is required (generally implemented by default).
          Please check your environments first.
  note 3: We have not tested Mcalibrator2 on Linux box. But it
          would work once you can get a proper serial or usb
          interfaces with valid drivers to control your photometers.

- MATLAB R2009a or later and "optimization" toolbox
  note 1: Mcalibrator2 works even without optimization toolbox,
          but to use full functionality of the software (e.g.
          automatic non-linear RGB video input estimations),
          the toolbox is required.
  note 2: Mcalibrator2 can not be launched correctly on MATLAB
          R2007 or an older version as GUI control system that
          Mcalibrator2 adopted is quite different from the
          conventions of the older MATLAB's one.


[How to launch Mcalibrator2]

To launch Mcalibrator on MATLAB, please run
>> Mcalibrator2

Please note that when you use MATLAB version 2012 or later,
a tab-related function, "tabselectionfcn", will be disabled
due to incompatibility of this function with the recent MATLAB.
I will sort this problem out soon.


[How to generate/update html-based Mcalibrator2 help files]

Please run
>> update_Mcalibrator2_html_docs

Then, all the html-based help documents will be automatically
generated in ~/Mcalibrator2/doc/html
To read the help documents, please open
~/Mcalibrator2/doc/html/index.html
on your browser.
