function result=test_iData_ind2sub

  a=iData(peaks);
  if isa(a(1),'iData') && isfloat(ind2sub(a,1))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
