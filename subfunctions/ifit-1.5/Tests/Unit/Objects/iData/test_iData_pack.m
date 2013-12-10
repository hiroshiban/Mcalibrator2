function result=test_iData_pack

  a=iData(eye(100));
  b=pack(a);
  
  if getfield(whos('a'),'bytes') > getfield(whos('b'),'bytes')
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
