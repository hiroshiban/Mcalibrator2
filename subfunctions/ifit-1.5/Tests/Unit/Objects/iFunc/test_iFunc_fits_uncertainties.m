function result = test_iFunc_fits_uncertainties

  a=load(iData, [ ifitpath 'Data/sv1850.scn' ]);
  [p,criteria,message,output]= fits(a, 'gauss', [], 'fminimfil');
  sigma = output.parsHistoryUncertainty;
  % p    = [ 0.6264      1.001   -0.00365  0.0002173 ]
  % sigma= [ 0.004565  2.438e-05  3.159e-05  3.785e-05 ]
  
  if abs(max(abs([ 0.6251    1.0008    0.0037   -0.0010 ])-abs(p))) < 0.02 && ...
     all(abs([0.03  1e-03  1e-03  0.01 ]) > abs(sigma))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end 
