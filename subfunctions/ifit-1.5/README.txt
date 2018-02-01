                       Welcome to the iFit/iData package
                              <ifit.mccode.org>
                              
                        E. Farhi, ILL/CS <farhi@ill.fr>
                           Version 1.5 - Sep. 27, 2013

** Purpose:
  This library aims at providing basic functionality to achieve some of the 
  general tasks needed for scientific data analysis:
    Load, Plot, Save, Fit, Math operations, define and use Models

** License: EUPL
  Basically this is open-source. Use it if you find it useful, and enrich it.
  If you do produce new methods, please send them back to me so that they are 
  added in the software and thus benefit to the community.

  In short, you can use, copy, distribute and modify the Code. However, a number 
  of restrictions apply, especially when producing derived work (that is modify 
  and redistribute the code in other products). In particular, the derived work 
  must be licensed under the EUPL or a Compatible License, label all modifications 
  explicitly, distribute the Source Code, and cite the Original work.
  The Source code of iFit is freely available at <http://ifit.mccode.org>

  A number of additions, included in the software, where obtained from the Matlab 
  Central contributions, and are BSD licensed.
  
  Matlab is a registered trademark of The Mathworks Inc.

  Contributions are listed in the iFit/Docs/Credits.html page.

** Disclaimer:
  This is not a professional tool, and there is no Dev team to actively take care
  of it. Expect occasional failures and bugs. However, I try my best to make the 
  software efficient and reliable. 

****************************** Requirements ************************************

** Requirements for standalone (binary) package: NONE
  Stand-alone versions do not require a Matlab license, and have no dependency
  except the Matlab Compiler Runtime (MCR).
  You can get the MCR installer at 
    http://ifit.mccode.org/Downloads/binary

** Requirements for Source package:
  Matlab (any version from 7.x, R2007a), possibly a C compiler for the looktxt  
  and the cbf_uncompress MeX.

****************************** Installation ************************************

** Installation for Source package:
  Copy the library directories where-ever you want or in MALTAB/toolbox/local:
    /home/joe/Matlab/iFit
  or
    /usr/local/matlab/toolbox/local/iFit
  
  Then start Matlab and type in, e.g.:
    >> addpath(genpath('/home/joe/Matlab/iFit'))
  or
    >> addpath(genpath('/usr/local/matlab/toolbox/local/iFit'))
  
** Installation for standalone (binary) package:
  Install the MCR (see above, prefer /opt/MATLAB location on Linux systems), then 
  extract the iFit binary package and launch 'ifit'.

** Quick start:
  type at matlab prompt:
    >> addpath(genpath('/path/to/iFit'))
    >> doc(iData)

  Then refer to the Quick Start tutorial (in iFit/Docs/QuickStart.html).

** Contacts:
  You can register to the iFit mailing list at <http://mail.mccode.org/cgi-bin/mailman/listinfo/ifit-users>
  Send messages to the ifit-users@mail.mccode.org.
  Help pages are available at <http://ifit.mccode.org>

--------------------------------------------------------------------------------
$Revision: 1146 $ - $Date: 2013-09-06 10:27:32 +0200 (Fri, 06 Sep 2013) $
