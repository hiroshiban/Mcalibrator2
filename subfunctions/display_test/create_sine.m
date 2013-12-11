function Y = create_sine(wl,step)

% Creats sine waves for testing display flicker (gradual spatial-frequency changes).
% function Y = create_sine(wl,step)
%
% creating sine value
%
% May 2004 Hiroshi Ban
 
    % grating 1 to 5
    i=1;
    
    for omega=0:step:359
	    y(i)=10*sin(wl*omega*pi/180);
	    i=i+1;
    end

    for omega=0:step:359
	    y(i)=10*sin(wl*2*omega*pi/180);
	    i=i+1;
    end

    for omega=0:step:359
	    y(i)=10*sin(wl*3*omega*pi/180);
	    i=i+1;
    end

    for omega=0:step:359
	    y(i)=10*sin(wl*4*omega*pi/180);
	    i=i+1;
    end

    for omega=0:step:359
	    y(i)=10*sin(wl*5*omega*pi/180);
	    i=i+1;
    end
    
    Y=[];
    for j=1:1:2
	    Y=[y;y];
    end
