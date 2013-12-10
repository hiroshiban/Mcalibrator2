function result=test_iData_cat

  x=-pi:0.01:pi; a=iData(x,x); 
  a.Error=0;                         % replace default Error=sqrt(Signal) by no-error.
  b=sin(a); c=cos(a); d=exp(-a.*a);  % create new objects by applying operator on the initial linear one
  a{2}=1; b{2}=1.5; c{2}=3; d{2}=5;  % assign a new 2D axis single value to each 1D objects
  
  e=cat(2, [a b c d]);               % catenate 1D objects into a 2D object along 2nd axis 
  f=cat(1, a,b,c,d);
  
  if ndims(e) == 2 && ndims(f) == 1
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
