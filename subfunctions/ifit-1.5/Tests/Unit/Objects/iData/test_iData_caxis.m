function result=test_iData_caxis

  a=iData(peaks);  plot(a);
  b=caxis(del2(a));
  
  if ishandle(b)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
