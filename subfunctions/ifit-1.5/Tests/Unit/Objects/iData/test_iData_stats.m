function result = test_iData_stats

  a = iData([ ifitpath 'Data/sv1850.scn' ]);
  [w,x]=std(a); % w=0.036 x=1.0007
  m=[ min(a) max(a) median(a) mean(a) ];
  % 0         7387          119       1630.7
  p=fits(a,'','','fminimfil');
  
  if abs(w-0.0036) < 1e-4 && abs(x-1.0007) < 1e-4 && ...
   norm(abs(m-[0         7387          119       1630.7])) < 5e-2 && ...
   abs(p(2)-x) < 5e-4 && abs(abs(p(3))-w) < 1e-4
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
