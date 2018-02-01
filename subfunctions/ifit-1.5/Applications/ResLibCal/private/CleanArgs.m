function [len,varargout]=CleanArgs(varargin)
%===================================================================================
%  function [N,X,Y,Z,..]=CleanArgs(X,Y,Z,..)
%  ResLib v.3.4
%===================================================================================
%
%  Reshapes input arguments to be row-vectors. N is the length of the longest 
%  input argument. If any input arguments are shorter than N, their first values 
%  are replicated to produce vectors of length N. In any case, output arguments
%  are row-vectors of length N.
%
% A. Zheludev, 1999-2006
% Oak Ridge National Laboratory
%===================================================================================

varargout=varargin;
lengths=zeros(1,nargin);
for ind=1:nargin
    varargout{ind}=varargout{ind}(:)';
    lengths(ind)=length(varargout{ind});
end
len=max(lengths);
bad=find(lengths==1);
for ind=1:length(bad)
    varargout{bad(ind)}=repmat(varargout{bad(ind)}(1),1,len);
    lengths(bad(ind))=len;
end
if ~isempty(find(lengths<len)), error('Fatal error: All input vectors must have the same lengths.'); end;
