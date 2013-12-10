Version: $Revision: 1035 $  

All functions here are meant to minimize an objective scalar function (usually 
down to zero). The general syntax is the same as the one of fminsearch, 
including standard Matlab optimizer options.

  fmin<method> (objFun, pars, options)
  
A usual 'options' structure is 
        Display: 'iter'
    MaxFunEvals: 2000
        MaxIter: 400
         TolFun: 1.0000e-06
           TolX: 1.0000e-06
    FunValCheck: []
      OutputFcn: 'fminplot'
       PlotFcns: []

The 'fminplot' show the optimization procedure criteria and first 1-3 parameter
values during the optimization.


Credits: all obtained on Matlab Central except CMA-ES and solvopt
-------
hPSO by Alexandros Leontitsis leoaleq@yahoo.com Ioannina, Greece 2004 
  used in fminswarmhybrid and fminswarm
  modified to handle a no-hybrid optimization (pure swarm in fminswarm)
  modified to use standard Matlab optimization fminsearch syntax and options
Simplex by F. Sigworth, 15 March 2003, S. H. Heinemann, 1987 and M. Caceci 
    and W. Cacheris, Byte, p. 340, May 1984.
  used in fminsimplex
  modified to use standard Matlab optimization fminsearch syntax and options
powell by Argimiro R. Secchi (arge@enq.ufrgs.br) 2001
  used in fminpowell
  modified to use standard Matlab optimization fminsearch syntax and options
ossrs by Sheela V. Belur(sbelur@csc.com) 1998
  used in fmingradrand
  modified to use standard Matlab optimization fminsearch syntax and options
ga/gaconstrain by Javad Ivakpour javad7@gmail.com, May 2006
  used in fminga
  modified to use standard Matlab optimization fminsearch syntax and options
cmaes by Nikolaus Hansen, 2001-2007. e-mail: hansen@bionik.tu-berlin.de
  used in fmicmaes (CMA-ES)
  modified to use standard Matlab optimization fminsearch syntax and options
anneal by joachim.vandekerckhove@psy.kuleuven.be 2006/04/26 12:54:04
  used in fminanneal
  modified to use standard Matlab optimization fminsearch syntax and options
solvopt by Alexei Kuntsevich and Franz Kappel , Graz (Austria) 1997
  used in fminralg
  modified to use standard Matlab optimization fminsearch syntax and options
hooke by Kelley, 1998, Iterative Methods for Optimization
  used in fminhooke
  modified to use standard Matlab optimization fminsearch syntax and options
imfil by Kelley, 1998, Iterative Methods for Optimization
  used in fminimfil
  modified to use standard Matlab optimization fminsearch syntax and options
PSO by Brecht Donckels, BIOMATH, brecht.donckels@ugent.be 2006 
  used in fminpso
  modified to use standard Matlab optimization fminsearch syntax and options
psa by Brecht Donckels, BIOMATH, brecht.donckels@ugent.be 2006
  used in fminpsa
  modified to use standard Matlab optimization fminsearch syntax and options
sce by Brecht Donckels, BIOMATH, brecht.donckels@ugent.be 2006
  used in fminsce
  modified to use standard Matlab optimization fminsearch syntax and options
LMFsolve by Miroslav Balda, balda AT cdm DOT cas DOT cz 2009
  used in fminlm
  modified to use standard Matlab optimization fminsearch syntax and options
anneal by Joachim Vandekerckhove, 2006
  use in fminanneal
  modified to use standard Matlab optimization fminsearch syntax and options
bfgswopt by Kelley, 1998, Iterative Methods for Optimization, SIAM Frontier in Applied Mathematics 18
  used in fminbfgs
  modified to use standard Matlab optimization fminsearch syntax and options
ntrust by Kelley, 1998, Iterative Methods for Optimization, SIAM Frontier in Applied Mathematics 18
  used in fminnewton
  modified to use standard Matlab optimization fminsearch syntax and options
ukfopt by Yi Cao at Cranfield University, 08 January 2008
  used in fminkalman
  modified to use standard Matlab optimization fminsearch syntax and options
buscarnd by Argimiro R. Secchi (arge@enq.ufrgs.br) and Giovani Tonel(giovani.tonel@ufrgs.br) on September 2006
  used in fminrand
  modified to use standard Matlab optimization fminsearch syntax and options
 
