% function result = PDB_Geometry(fname)
%
%       Compute SAXS characteristics of molecule described in file fname.
%       Input -     fname --> valid PDB file.
%       Output      result --> structure with fields describing SAXS profile.
%
%       result.Rg_charge = Radius of gyration of molecule weighting
%           each residue by its charge.
%       result.Rg_volume = Rg weighting residues by their volume.
%       result.Rg_contrast = Rg weighting by their contrast above the
%       solvent density (eg. charge - volume * rho_water).
%       result.Rg_sphere = Rg if protein were densely packed into a sphere;
%       result.Ne = Total charge of protein.
%       result.Ne_excess =  Excess charge relative to solvent. 
%       result.Protein_Density= Density of protein relative to solvent.
%       result.Protein_Volume= Total volume of protein.
%
%       result.pofr = Pair correlation function of protein p(r)
%                       p(|r|) = integral of rho(r+r')rho(r') for all r' and averaged over 
%                           all diretions r.  Normalized so integral of
%                           p(|r|) is one.
%                           r  - pofr(:,1)
%                           p(r) - pofr(:,2)
%
%       result.Ivq = Intensity versus q for protein I(q)
%                       q = Ivq(:,1); I = Ivq(:,2)
    
% **********************  Number of Electrons ***********************************
% From a PDB file, we can calculate the number of electrons by adding up the amino 
% acid residues.  We need to be a little careful because there are often prosthetic 
% groups to be considered.  However, most of the charge in these comes from C,N and O % so if we just consider the amino acid residues + the C,N and O in the prosthetic 
% groups then we should get a pretty good estimate (although not perfect).  
% A quick back of the envelope method of calculation is to count the number of 
% residues.  The average number of electrons in the amino acids is 64.  Or, you can 
% take the weight of the protein and note that the number of electrons is roughly half% the weight of the protein in daltons.  The really interesting feature for X-ray 
% scattering is the number of excess electrons over an equivalent volume of water. 
% This number is also reported, and its square is proportional to the X-ray signal. 
% at small angles.

% *********************  Volume of Protein  ************************************
% Not nearly as easy is an attempt to estimate the volume of the protein.  One could 
% take an envelope and wrap the protein up in it.  However, water is pretty cunning 
% and will try to fill as many nocks and crannies as it can manage.  Svergun's 
% approach is to assign each functional group an excluded region of water (Journal of
% Applied Crystallography, 28, p768).  This is probably not too good, but it shouldn't% be any worse than the bounding envelope.  In the file, amino_details.txt, the volume% and charge of each amino group is stored in  colums of "name", "charge", 
% "volume (cubic Angstroms)".  The carbon, nitrogen and oxygen atoms in prosthetic 
% groups are treated in the same fashion.

% ********************  Radius of Gyration ************************************
% Next, we need the radius of gyration of the protein.  If the protein were in a 
% vacuum, we should merely weight each part by its charge.  This radius of gyration
% is calculated.
% If the protein were of uniform density, then we should only need to calculate the 
% radius of gyration based on the volume of each functional group.  
% In truth, we should calculate it on the density difference of each piece of the 
% protein from the surrounding fluid.  
% Because this is a rough calculation, we simply average the different atoms in each
% residue to estimate the residue's position.  This cannot be right, but it works 
% okay and should only induce a systematic offset of all radii of gyration.
% We calculate all three radii of gyration.  If they are all similar, then the 
% standard "uniform density" approximation is okay and the solvent density's main
% effect on the x-ray signal will be to alter the contrast.
% If they differ wildly then life is not nearly so rosy.
% A final estimated radius of gyration is added purely for comparison purposes.
% If all the protein residues were stuffed into a sphere, this would give the 
% minimal possible radius of gyration.  This result is also reported for comparison
% purposes.

% ****************** Summary ************************************************
% PDB format information can be found at http://www.rcsb.org/pdb/

% ***************** The Actual Function *************************************
function result = read_pdb(name)

rho_water = 0.334611 ; % Density of electrons per cubic Angstrom in solvent.


% ******************************************
% Load up the description of each amino acid

Amino_Names  = textscan('ALA ARG ASN ASP CYS GLN GLU GLY HIS ILE LEU LYS MET PHE PRO SER THR TRP TYR VAL NOT', '%s');
Amino_Names = char(Amino_Names{1});

Amino_Charge = [ 37    84    59    59    53    67    67    29    72    61    61    69    69    77    52 45    53    97    85    53     0 ];
Amino_Volume = [ 86.6900  184.6800  119.9000  121.3900  106.5500  146.6400  148.1300   59.9500  156.4400 166.9100  166.9100  174.5500  160.0300  205.9300  135.0200   95.8200  122.5600  246.4500 215.0600  140.1700         0 ];

% Initialize all the arrays that hold the protein information.
number_of_residues = 0; % Number of residues sampled.
                        % Not strictly number of residues in protein as
                        % each identifiable atom in prosthetic groups also counts.
Backbone_Charge(1)=0;   % Charge on each residue
Backbone_Size(1)=0;     % Volume of each residue
Backbone_Elements(1)=0; % Number of atoms in the residue
Backbone_Position(1,3)=0; % Location of the residue.
Backbone_Name={};
current_residue = -100; % Current residue number.  -100 is used to mean it doesn't
                        % have a residue.

unknown_residues = {};
FID = fopen(name,'r'); % Open the file
while not(feof(FID))  % read and store PDB co-ordinates line by line

    line = fgetl(FID);

        % The line stores the position of an atom.
        if (strncmp(line,'ATOM',4)==1)

           % The atom is the first in a new residue.  
           clear str; for j=0:3  str(1+j)=line(23+j) ; end
           resnum = sscanf(str,'%d');
           if (resnum~=current_residue) 
   
                current_residue = resnum;
                number_of_residues=number_of_residues+1;  
      	        clear str; for j=0:2 str(1+j)=line(18+j); end;
                restype=1; 
                while((restype<21)&(strcmp(str,Amino_Names(restype,:))==0))
                restype=restype+1; end;
	    
                % No idea what kind of residue this is.
	              if (restype==21) 
	                unknown_residues{end+1} = str;
                end

                % Set up the next residue storage site. 
                Backbone_Size(number_of_residues)=Amino_Volume(restype);
                Backbone_Charge(number_of_residues)=Amino_Charge(restype); 
                Backbone_Position(number_of_residues,:)=[0,0,0];
                Backbone_Elements(number_of_residues) = 0;
                Backbone_Name{number_of_residues}=Amino_Names(restype,:);
           end     

           %Add this atom to the list.
           clear str; for j=31:54; str(j-30)=line(j);end
           x = sscanf(str,'%f %f %f');
           Backbone_Position(number_of_residues,:)=Backbone_Position(number_of_residues,:) + x';
           Backbone_Elements(number_of_residues)=Backbone_Elements(number_of_residues)+1;   
        end        

	% The line stores the position of a prosthetic atom   
        if (strncmp(line,'HETATM',6)==1)
    
            clear str; for j=0:2 str(1+j)=line(18+j); end;
            if (strcmp(str,'HOH')~=1)  % Check that it isn't water of hydration
                  
	               clear str;str=line(13);for j=0:2;if (str==' ') str=line(14+j);end;end
                 if (strcmp(str,'C')==1)|(strcmp(str,'N')==1)|(strcmp(str,'O')==1)                   
                         % We know what type of atom it is
		                     number_of_residues=number_of_residues+1;
                         current_residue = -1;
                         clear str2; for j=31:54; str2(j-30)=line(j);end
                         x = sscanf(str2,'%f %f %f');
                         Backbone_Position(number_of_residues,:)=x';
                         Backbone_Elements(number_of_residues)=1;
                         
                         if (strcmp(str,'C')==1)
                         Backbone_Size(number_of_residues)= 16.44;
                         Backbone_Charge(number_of_residues) = 8;
                         elseif (strcmp(str,'N')==1)
                         Backbone_Size(number_of_residues)=2.5;
                         Backbone_Charge(number_of_residues)=8;
                         elseif (strcmp(str,'O')==1)
                         Backbone_Size(number_of_residues)=9.13;
                         Backbone_Charge(number_of_residues)=9;
                         end
                 elseif length(str) > 1 		 
		                     unknown_residues{end+1} = str;
		             end 
            end 

        end

end

fclose(FID);
fprintf(1, '%s: %s: Read %i Residues\n', mfilename, name, number_of_residues);
if ~isempty(unknown_residues)
  fprintf(1,'  Unknown residues found in PDB file:\n')
  disp(unique(unknown_residues))
end


% Average the position of the elements in each residue
for j=1:number_of_residues
   Backbone_Position(j,:)=Backbone_Position(j,:)/ Backbone_Elements(j);
end


% There are three ways of weighting our residues.  
% One is by volume.  
% The next is by charge.
% The last is by excess charge per residue.
% We calculate all three for completeness.

% Do the least squares sums 
X_centre_q=[0,0,0]; X_centre_v = [0,0,0]; X_q_squared = 0; X_v_squared = 0;
total_charge = 0; total_volume = 0; 
for j=1:number_of_residues
   X_centre_q = X_centre_q + Backbone_Position(j,:)*Backbone_Charge(j);
   X_centre_v = X_centre_v + Backbone_Position(j,:)*Backbone_Size(j);
   X_q_squared = X_q_squared + norm(Backbone_Position(j,:))^2*Backbone_Charge(j);
   X_v_squared = X_v_squared + norm(Backbone_Position(j,:))^2*Backbone_Size(j); 
   total_charge = total_charge+Backbone_Charge(j);
   total_volume = total_volume+Backbone_Size(j);
end

% Charge weighted Rg
Rg_q = X_q_squared / total_charge  - norm( X_centre_q /total_charge )^2;
Rg_q = sqrt(Rg_q);

% Volume weighted Rg
Rg_v = X_v_squared / total_volume - norm( X_centre_v / total_volume )^2;
Rg_v = sqrt(Rg_v);

% Excess Charge weighted.
Excess = total_charge - rho_water * total_volume;
Rg_e = (X_q_squared - rho_water * X_v_squared)/ Excess;
Rg_e = Rg_e - norm( (X_centre_q - X_centre_v* rho_water)/Excess)^2;
Rg_e = sqrt(Rg_e);

% Protein Density 
Prot_Density = total_charge/ (total_volume*rho_water);

% Number of Excess Electrons
Excess = total_charge - total_volume*rho_water;

% Now record results.
    result.Rg_charge = Rg_q;
    result.Rg_volume = Rg_v;
    result.Rg_contrast = Rg_e;
    result.Rg_sphere = (3*total_volume/(4*pi))^0.33333 * 0.7746;
    result.Ne = total_charge;
    result.Ne_excess = Excess;
    result.Protein_Density=Prot_Density;
    result.Protein_Volume=total_volume;
    
    fprintf(1,'  Radius of Gyration by Charge          = %f (Angstroms)\n', Rg_q);
    fprintf(1,'  Radius of Gyration by Volume          = %f (Angstroms)\n',Rg_v);
    fprintf(1,'  Radius of Gyration by Charge Contrast = %f (Angstroms)\n',Rg_e);
    fprintf(1,'  Radius of Gyration by Compact Packing = %f (Angstroms)\n',(3*total_volume/(4*pi))^0.33333 * 0.7746) ;
    fprintf(1,'  Protein Charge                        = %f (electrons)\n', total_charge);
    fprintf(1,'  Protein Excess Charge                 = %f (electrons)\n', Excess);
    fprintf(1,'  Protein Volume                        = %f (Angstroms^3)\n', total_volume);
    fprintf(1,'  Protein Density                       = %f (g/cm^3)\n',Prot_Density);


% Compute Pair Correlation function and I versus q.
% Note we are just weighting it by charge per residue.
% A better measure would be Backbone_Charge - Backbone_Volume*rho_water;
[r, p, q, I] = Compute_SAXS(Backbone_Position,Backbone_Charge - Backbone_Size*rho_water);

% Save results
    pofr = [r', p];
    Ivq = [q',I'];
    result.PairCorrelationFunction = p;
    result.Radius_Angs     = r';
    result.StructureFactor = I';
    result.Momentum_invAngs   = q';
    result.Backbone_Charge   = Backbone_Charge;
    result.Backbone_Position = Backbone_Position;
    result.Backbone_Elements = Backbone_Elements;
    result.Backbone_Name     = Backbone_Name;
    
    
% private functions ============================================================


% function [r, p, q, I] = Compute_SAXS(positions, charges)
%
%      Computes the scattering pattern for a molecule.
%
%                   positions(j,:) = [x,y,z] coordinates of j-th scatterer
%                   in molecule.
%                   charges(j) = number of charges/scatterer strength of
%                   j-th scatterer in molecule.
%
%       Output information
%           Pair Correlation Function - p(r) --->  p(j) versus r(j).
%           Scattering Pattern - I(q) ---> I(j) versus q(j)
%

function [r, p, q, I] = Compute_SAXS(positions, charges);

R = positions'; % R(:,j) are the 3-d coordinates of the j-th scattering object.
charge =charges'; % charge(j) is the charge associated with the j-th scattering object.

% Make a histogram of pair-pair distances weighted by charge..

%  Set up the bins for the histogram.
r_min = 0; % Minimum allowed pair correlation length.
r_max = 2*sqrt(3)*max(max(R)) ; % Maximum pair correlation length.
Nbins = 300; % Number of bins in our histogram.
r = ([1:Nbins]-0.5)/Nbins*(r_max-r_min)+r_min;
g = zeros(Nbins,1);

% Treat the scatterers as gaussian balls with a size "sigma" Angstroms.
sigma = 1.0;
sf = -1.0/(4*sigma*sigma);

% Sum all atom-atom pairs.
for j=1:length(charge)
    for k=1:length(charge);

        % Compute distance and weight of this pair of scatterers
        dist = norm(R(:,j)-R(:,k));
        wt = charge(j)*charge(k);

        % Distribute this pair into the histogram bins.
        if (dist>0.1*sigma)
            wt = wt*sigma*sigma;
            for m=1:Nbins
                 d1=r(m)-dist; d2 = r(m)+dist;
                 g(m)=g(m)+wt * (exp(sf*d1*d1) - exp(sf*d2*d2)) * ( r(m)/dist ) ;     
            end
        else
            for m=1:Nbins
                 g(m)=g(m)+wt * exp(sf*r(m)*r(m)) * r(m)* r(m) ;     
             end 
        end
    
    end
end
 
% Normalize the pair correlation function to one.
g = g/ sum(g);

% When we return the pair correlation function we wish to normalize it so 
% Integral(g(r).dr)=1
p = g / (r(2)-r(1));

% Now convolve g(r) with sinc(qr) to determine I as a function of q.
% Initialize the q-range
q_min = 0 ; 
Rg = sqrt(sum(g.* r'.*r')/2); % Natural size of protein 
q_max = 8/Rg;
Nqbins = 500;

q = ([1:Nqbins]-1)/Nqbins * (q_max-q_min) + q_min;
I = zeros(size(q));

for j=1:Nqbins
    for k=1:Nbins
        I(j) = I(j) + g(k) * sinc( q(j) * r(k)/pi);
    end
end

function y=sinc(x)
  y=zeros(size(x));
  i=find(x == 0); y(i) = 1;
  i=find(x ~= 0); y(i) = sin(x)./x;
  
