function result=test_iData_label

  a=iData(peaks);

  label(a,1,'X'); label(a,2,'Y');
  
  if strcmp(label(a,1), 'X') && strcmp(label(a,2), 'Y')
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
