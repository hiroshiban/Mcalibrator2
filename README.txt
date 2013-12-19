**************************************************
README.txt on Mcalibrator2

Created    : "2013-05-13 12:30:52 ban"
Last Update: "2013-12-19 09:56:10 ban"
**************************************************

[About]

Mcalibrator2 is a MATLAB-based GUI display luminance and
chromaticity characterization software package for visual
neuroscience and psychology studies. The package is
especially focusing on 1. providing accurate gamma-correction
and 2. finding the best RGB video inputs to produce the
required CIE1931 xyY values using several goal-seeking
optimization algorithms.
(Matlab is a registered trademark of The Mathworks Inc.)

For details, please read
documents in ~/Mcalibrator2/doc directory.
Also please see the link below.
http://www.cv.jinkan.kyoto-u.ac.jp/site/mcalibrator/

The details of the algorithms we developed are described below.
http://www.journalofvision.org/content/13/6/20.long

Thank you for using our software. We are happy if Mcalibrator2
can help your research projects.


[System Requirements]

- OS: Windows XP/VISTA/7/8 or Mac OSX
  note 1: Windows OS is required to use some photometers with
          Mcalibrator2 as only Windows drivers are distributed
          for them.
  note 2: On a Mac OSX box, an interface to a virtual serial
          port is required (generally implemented by default).
          Please check your environments first.
  note 3: We have not tested Mcalibrator2 on any Linux box. But
          it would work once you can get a proper serial or usb
          interface with valid drivers to control your photometers.

- MATLAB R2009a or later, and "optimization" and "statistics" toolboxes
  note 1: Mcalibrator2 works even without optimization/statistics
          toolboxes, but to use full functionality of the software
          (e.g. automatic non-linear RGB video input estimations),
          the toolboxes are required.
  note 2: Mcalibrator2 can not be launched correctly on MATLAB
          R2007 or older since the GUI control system that
          Mcalibrator2 adopted is quite different from the
          conventions of the older MATLABs.


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
