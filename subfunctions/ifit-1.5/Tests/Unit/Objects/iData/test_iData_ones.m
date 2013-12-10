function result=test_iData_ones

  d=[5 5];
  a=ones(iData,d);
  if numel(a) == prod(d) && all(all(isempty(zeros(iData,5,5))))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
