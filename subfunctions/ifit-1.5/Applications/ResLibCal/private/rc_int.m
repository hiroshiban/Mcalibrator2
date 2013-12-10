function [r,mp]=rc_int(index,r0,m)
%
% MATLAB function that takes a matrix and performs a Gaussian integral
% over the row and column specified by index and returns
% a new matrix. Tested against maple integration.
%
% ResCal5/A.T.

r=sqrt(2*pi/m(index,index))*r0;

% remove columns and rows from m
% that contain the subscript "index".

mp=m;
b=m(:,index)+m(index,:)';
b(index)=[];
mp(index,:)=[];
mp(:,index)=[];
mp=mp-1/(4*m(index,index))*b*b';

return
