function result = test_Models_gauss

  a= load(iData, [ ifitpath 'Data/sv1850.scn' ]);
  p= fits(a, 'gauss', [ 0.5 1 0.003 0 ],'fminimfil');   % specify the starting parameters for the model function
  b= a(gauss, p);
  plot([ a b ]);
  
  if max(a-b)/mean(get(a,'Monitor')) < 0.1
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end 
