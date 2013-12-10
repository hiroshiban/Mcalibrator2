function result=test_iData_rmaxis

  a=iData(peaks);
  a{1} = linspace(-5,5,size(a,1));
  b=copyobj(a);
  rmaxis(b, 1);
  
  if isempty(getaxis(b, '1')) && ~isempty(getaxis(a, '1')) && length(a{1}) == length(b{1})
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
