function result=test_iData_peaks

  a = iData(gauss);
  [half_width, center, amplitude, baseline] = peaks(a);
  
  if abs(std(a)/2 - half_width) < 0.1 && abs(max(a) - amplitude) < 0.1 ...
    && abs(center) < 0.2
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
