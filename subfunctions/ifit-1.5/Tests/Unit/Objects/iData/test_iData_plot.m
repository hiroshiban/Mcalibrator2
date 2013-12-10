function result=test_iData_plot

  h1= [ plot(iData(1:100)) plot(iData(peaks)) plot(iData(flow)) ];
  
  % expicit overlay
  x=-pi:0.01:pi; a=iData(x,x); 
  a.Error=0;                         % replace default Error=sqrt(Signal) by no-error.
  b=sin(a); c=cos(a); d=exp(-a.*a);  % create new objects by applying operator on the initial linear one
  
  a{2}=1; b{2}=1.5; c{2}=3; d{2}=5;  % assign a new 2D axis single value to each 1D objects
  h2 = plot([a b c d]);                 % overlay all objects
  
  h6 = plot([a b c d],'surf');  
  
  e=cat(2, [a b c d]);               % catenate 1D objects into a 2D object along 2nd axis 
  
  h7 = plot(e);
  
  % waterfall stuff
  [x,y,z]=peaks; a=iData(x,y*10,z); 
  c  = linspace(a,-a+50,10);            % continuously go from 'a' to a '-a+50' in 10 steps
  h3 = plot(c);
  
  h4 = colormap(c);
  
  if numel(h1) == 3 && numel(h2) == 4 && numel(h3) == 10 ...
    && numel(h4) == 10 && numel(h6) == 4 && numel(h7) == 1
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
