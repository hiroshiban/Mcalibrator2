function result=test_iData_zeros

  d=[5 5];
  a=zeros(iData,d);
  if numel(a) == prod(d) && all(all(isempty(zeros(iData,5,5))))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
