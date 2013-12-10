function stlwrite(filename, varargin)
%STLWRITE   Write STL file from patch or surface data.
%
%   STLWRITE(FILE,fv) writes a stereolithography (STL) file to FILE for a triangulated
%   patch defined by FV (a structure with fields 'vertices' and 'faces').
%
%   STLWRITE(FILE,FACES,VERTICES) takes faces and vertices separately, rather than in an FV struct
%
%   STLWRITE(FILE,X,Y,Z) creates an STL file from surface data in X, Y, and Z. STLWRITE triangulates
%   this gridded data into a triangulated surface using triangulations options specified below. X, Y
%   and Z can be two-dimensional arrays with the same size. If X and Y are vectors with length equal
%   to SIZE(Z,2) and SIZE(Z,1), respectively, they are passed through MESHGRID to create gridded
%   data. If X or Y are scalar values, they are used to specify the X and Y spacing between grid
%   points.
%
%   STLWRITE(...,'PropertyName',VALUE,'PropertyName',VALUE,...) writes an STL file using the
%   following property values:
%
%   MODE          - File is written using 'binary' (default) or 'ascii'.
%
%   TITLE         - Header text (max 80 characters) written to the STL file.
%
%   TRIANGULATION - When used with gridded data, TRIANGULATION is either:
%                       'delaunay'  - (default) Delaunay triangulation of X, Y
%                       'f'         - Forward slash division of grid quadrilaterals
%                       'b'         - Back slash division of quadrilaterals
%                       'x'         - Cross division of quadrilaterals
%                   Note that 'f', 'b', or 't' triangulations require FEX entry 28327, "mesh2tri".
%
%   FACECOLOR     - (not currently implemented) When used with face/vertex input, specifies the
%                   colour of each triangle face. If users request this feature, I will attempt to
%                   implement it.
%
%   Example 1:
%       % Write binary STL from face/vertex data
%       tmpvol = zeros(20,20,20);       % Empty voxel volume
%       tmpvol(8:12,8:12,5:15) = 1;     % Turn some voxels on
%       fv = isosurface(tmpvol, 0.99);  % Create the patch object
%       stlwrite('test.stl',fv)         % Save to binary .stl
%
%   Example 2:
%       % Write ascii STL from gridded data
%       [X,Y] = deal(1:40);             % Create grid reference
%       Z = peaks(40);                  % Create grid height
%       stlwrite('test.stl',X,Y,Z,'mode','ascii')

%   Original idea adapted from surf2stl by Bill McDonald. Huge speed
%   improvements implemented by Oliver Woodford. Non-Delaunay triangulation
%   of quadrilateral surface input requires mesh2tri by Kevin Moerman.
%
%   Author: Sven Holcombe, 11-24-11


% Check valid filename path
error(nargchk(2, inf,nargin));
path = fileparts(filename);
if ~isempty(path) && ~exist(path,'dir')
    error('Directory "%s" does not exist.',path);
end

% Get faces, vertices, and user-defined options for writing
[faces, vertices, options] = parseInputs(varargin{:});
asciiMode = strcmp( options.mode ,'ascii');

% Create the facets
facets = single(vertices');
facets = reshape(facets(:,faces'), 3, 3, []);

% Compute their normals
V1 = squeeze(facets(:,2,:) - facets(:,1,:));
V2 = squeeze(facets(:,3,:) - facets(:,1,:));
normals = V1([2 3 1],:) .* V2([3 1 2],:) - V2([2 3 1],:) .* V1([3 1 2],:);
clear V1 V2
normals = bsxfun(@times, normals, 1 ./ sqrt(sum(normals .* normals, 1)));
facets = cat(2, reshape(normals, 3, 1, []), facets);
clear normals

% Open the file for writing
permissions = {'w','wb+'};
fid = fopen(filename, permissions{asciiMode+1});
if (fid == -1)
    error('stlwrite:cannotWriteFile', 'Unable to write to %s', filename);
end

% Write the file contents
if asciiMode
    % Write HEADER
    fprintf(fid,'solid %s\r\n',options.title);
    % Write DATA
    fprintf(fid,[...
        'facet normal %.7E %.7E %.7E\r\n' ...
        'outer loop\r\n' ...
        'vertex %.7E %.7E %.7E\r\n' ...
        'vertex %.7E %.7E %.7E\r\n' ...
        'vertex %.7E %.7E %.7E\r\n' ...
        'endloop\r\n' ...
        'endfacet\r\n'], facets);
    % Write FOOTER
    fprintf(fid,'endsolid %s\r\n',options.title);
    
else % BINARY
    % Write HEADER
    fprintf(fid, '%-80s', options.title);             % Title
    fwrite(fid, size(facets, 3), 'uint32');           % Number of facets
    % Write DATA
    % Add one uint16(0) to the end of each facet using a typecasting trick
    facets = reshape(typecast(facets(:), 'uint16'), 12*2, []);
    facets(end+1,:) = 0;
    fwrite(fid, facets, 'uint16');
end

% Close the file
fclose(fid);
fprintf('Wrote %d facets\n',length(facets(:))/3);


%% Input handling subfunctions
function [faces, vertices, options] = parseInputs(varargin)
% Determine input type
if isstruct(varargin{1}) % stlwrite('file', FVstruct, ...)
    if ~all(isfield(varargin{1},{'vertices','faces'}))
        error( 'Variable p must be a faces/vertices structure' );
    end
    faces = varargin{1}.faces;
    vertices = varargin{1}.vertices;
    options = parseOptions(varargin{2:end});
    
elseif isnumeric(varargin{1})
    firstNumInput = cellfun(@isnumeric,varargin);
    firstNumInput(find(~firstNumInput,1):end) = 0; % Only consider numerical input PRIOR to the first non-numeric
    numericInputCnt = nnz(firstNumInput);
    
    options = parseOptions(varargin{numericInputCnt+1:end});
    switch numericInputCnt
        case 3 % stlwrite('file', X, Y, Z, ...)
            % Extract the matrix Z
            Z = varargin{3};
            
            % Convert scalar XY to vectors
            ZsizeXY = fliplr(size(Z));
            for i = 1:2
                if isscalar(varargin{i})
                    varargin{i} = (0:ZsizeXY(i)-1) * varargin{i};
                end                    
            end
            
            % Extract X and Y
            if isequal(size(Z), size(varargin{1}), size(varargin{2}))
                % X,Y,Z were all provided as matrices
                [X,Y] = varargin{1:2};
            elseif numel(varargin{1})==ZsizeXY(1) && numel(varargin{2})==ZsizeXY(2)
                % Convert vector XY to meshgrid
                [X,Y] = meshgrid(varargin{1}, varargin{2});
            else
                error('stlwrite:badinput', 'Unable to resolve X and Y variables');
            end
            
            % Convert to faces/vertices
            if strcmp(options.triangulation,'delaunay')
                faces = delaunay(X,Y);
                vertices = [X(:) Y(:) Z(:)];
            else
                if ~exist('mesh2tri','file')
                    error('stlwrite:missing', '"mesh2tri" is required to convert X,Y,Z matrices to STL. It can be downloaded from:\n%s\n',...
                        'http://www.mathworks.com/matlabcentral/fileexchange/28327')
                end
                [faces, vertices] = mesh2tri(X, Y, Z, options.triangulation);
            end
            
        case 2 % stlwrite('file', FACES, VERTICES, ...)
            faces = varargin{1};
            vertices = varargin{2};
            
        otherwise
            error('stlwrite:badinput', 'Unable to resolve input types.');
    end
    
end

function options = parseOptions(varargin)
IP = inputParser;
IP.addParamValue('mode', 'binary', @ischar)
IP.addParamValue('title', sprintf('Created by stlwrite.m %s',datestr(now)), @ischar);
IP.addParamValue('triangulation', 'delaunay', @ischar);
IP.addParamValue('facecolor',[], @isnumeric)
IP.parse(varargin{:});
options = IP.Results;

function [F,V]=mesh2tri(X,Y,Z,tri_type)

% function [F,V]=mesh2tri(X,Y,Z,tri_type)
% ------------------------------------------------------------------------
%
% This function converts a regular mesh defined by X,Y and Z into a regular
% triangulation. The output is patch data (triangles) in the faces F and
% vertices V format. The quadrilateral mesh faces are converted to
% triangles by splitting the faces into triangles according to the setting
% tri_type:
%   tri_type ='f' -> forward slash division of quadrilateral
%   tri_type ='b' -> back slash division of quadrilateral
%   tri_type ='x' -> Cross division of quadrilateral
%
% The output coordinates "V" are in the form of V=[X(:),Y(:),Z(:)];
% For forward and back slash subdivision no extra coordinates are
% introduced and therefore the original meshgrid formatted coordinates can
% still be used for plotting, see examples below.
% For cross division extra points are created at the centre of each
% quadrilateral face using the mean of the input coordinates. The extra
% coordinates are the last prod(size(X)-1) points (e.g.
% V((numel(X)+1):end,:) )and can therefore be replaced by interpolated
% coordinates if desired, see example.
%
%
% %% EXAMPLE
% clear all; close all; clc;
%
% [X,Y] = meshgrid(linspace(-10,10,25));
% Z = sinc(sqrt((X/pi).^2+(Y/pi).^2));
%
% figure('units','normalized','Position',[0 0 1 1],'Color','w'); colordef('white');
% subplot(2,2,1);
% surf(X,Y,Z); hold on;
% axis tight; axis square; grid on; axis off; view(3); view(-30,70);
% title('Meshgrid','FontSize',20);
%
% [F,V]=mesh2tri(X,Y,Z,'f');
% C=V(:,3); C=mean(C(F),2);
% subplot(2,2,2);
% patch('Faces',F,'Vertices',V,'FaceColor','flat','CData',C); hold on;
% axis tight; axis square; grid on; axis off; view(3); view(-30,70);
% title('Forward slash','FontSize',20);
%
% [F,V]=mesh2tri(X,Y,Z,'b');
% C=V(:,3); C=mean(C(F),2);
% subplot(2,2,3);
% Example of using original meshgrid coordinates instead
% trisurf(F,X,Y,Z);
% axis tight; axis square; grid on; axis off; axis off; view(3); view(-30,70);
% title('Back slash','FontSize',20);
%
% [F,V]=mesh2tri(X,Y,Z,'x');
% Replace Z-coordinates of added points by interpolated values if desired
% IND=(numel(X)+1):size(V,1);
% ZI = interp2(X,Y,Z,V(IND,1),V(IND,2),'cubic');
% V(IND,3)=ZI;
%
% C=V(:,3); C=mean(C(F),2);
% subplot(2,2,4);
% patch('Faces',F,'Vertices',V,'FaceColor','flat','CData',C); hold on;
% axis tight; axis square; grid on; axis off; view(3); view(-30,70);
% title('Crossed','FontSize',20);
%
%
% Kevin Mattheus Moerman
% kevinmoerman@hotmail.com
% 15/07/2010
%------------------------------------------------------------------------

[J,I]=meshgrid(1:1:size(X,2)-1,1:1:size(X,1)-1);

switch tri_type
    case 'f'%Forward slash
        TRI_I=[I(:),I(:)+1,I(:)+1;  I(:),I(:),I(:)+1];
        TRI_J=[J(:),J(:)+1,J(:);   J(:),J(:)+1,J(:)+1];
        F = sub2ind(size(X),TRI_I,TRI_J);
    case 'b'%Back slash
        TRI_I=[I(:),I(:)+1,I(:);  I(:)+1,I(:)+1,I(:)];
        TRI_J=[J(:)+1,J(:),J(:);   J(:)+1,J(:),J(:)+1];
        F = sub2ind(size(X),TRI_I,TRI_J);
    case 'x'%Cross
        TRI_I=[I(:)+1,I(:);  I(:)+1,I(:)+1;  I(:),I(:)+1;    I(:),I(:)];
        TRI_J=[J(:),J(:);    J(:)+1,J(:);    J(:)+1,J(:)+1;  J(:),J(:)+1];
        IND=((numel(X)+1):numel(X)+prod(size(X)-1))';
        F = sub2ind(size(X),TRI_I,TRI_J);
        F(:,3)=repmat(IND,[4,1]);
        Fe_I=[I(:),I(:)+1,I(:)+1,I(:)]; Fe_J=[J(:),J(:),J(:)+1,J(:)+1];
        Fe = sub2ind(size(X),Fe_I,Fe_J);
        Xe=mean(X(Fe),2); Ye=mean(Y(Fe),2);  Ze=mean(Z(Fe),2);
        X=[X(:);Xe(:)]; Y=[Y(:);Ye(:)]; Z=[Z(:);Ze(:)];
end

V=[X(:),Y(:),Z(:)];

