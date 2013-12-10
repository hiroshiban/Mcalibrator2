function result=test_iData_jacobian

  a=iData(peaks); x=linspace(1,2,size(a,1));
  g=jacobian(a, x, [],'half X');
  
  if abs(trapz(a,0) - trapz(g,0)) < 1e-3
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
