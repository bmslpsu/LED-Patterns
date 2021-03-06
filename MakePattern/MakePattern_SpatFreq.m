function [pattern] = MakePattern_SpatFreq(wavelength,root,res)
%---------------------------------------------------------------------------------------------------------------------------------
% MakePattern_SpatFreq: makes pattern with two channels
%  Channel-X: changes spatial frequency
%  Channel-Y: rotates ground
%   INPUTS:
%       freq    :       row vector containing spatial frequencies in degress
%       root    :       directory to save file
%   OUTPUTS:
%       pattern :       pattern structure
%---------------------------------------------------------------------------------------------------------------------------------
%   This program creates one structure ('pattern').  The relevant components of
%   this structure are as follows:
%
%       pattern  -  the parent structure
%               .x_num          -   xpos limits
%                                   by convention, xpos relates to translation and
%                                   rotations of a static pattern
%               .y_num          -   ypos limits
%                                   by convention, ypos relates to non-length
%                                   conserving transformations
%               .x_panels       -   number of panels in x direction
%               .y_panels       -   number of panels in y directions
%               .num_panels     -   number of panels in array
%                                   (.x_panels*.y_panels)
%               .panel_size     -   '0' gives default 8x8, '1' allows user specific
%               .gs_val         -   gray scale value (1-4)
%               .Pats           -   data for the panels...a 4D array where
%                                   (x_panels*x_size,y_panels*y_size,xpos,ypos)
%               .Panel_map      -   a 2x2 array specifying the location of the
%                                   named panels indexed from '1'
%               .BitMapIndex	-   output generated by executing
%                                   'process_panel_map(pattern);'
%               .data           -   output generated by executing
%                                   'make_pattern_vector(pattern);'
%---------------------------------------------------------------------------------------------------------------------------------
% freq = 3.75*[0,2,4,6,8,12,16,24,32,48,96];
% root = 'Q:\Box Sync\Git\Arena\Patterns\';
%---------------------------------------------------------------------------------------------------------------------------------
if nargin<3
    res = 1;
end

% Set up panel variables 
pattern.x_num = res*96;                                 % pixels around the display (12x8)
pattern.y_num = length(wavelength);                 	% # of spatial frequencies
pattern.num_panels = (pattern.x_num/8)*4;           	% # of unique panel IDs required
pattern.gs_val = 1;                                     % pattern will use 2 intensity levels
pattern.row_compression = 1;                            % columns are symmetric
pattern.x_panel = pattern.x_num;                        % x-led's
pattern.y_panel = pattern.num_panels*8/pattern.x_num;   % y-led's
Int.High = 1;                                           % high intensity value (0-15)
Int.Low  = 0;                                          	% low intensity value (0-15)

% Calculate bar widths
barwidth = pattern.x_num*(wavelength./360);

% Calculate # of cycle repetitions for each frequency
reps = 360./wavelength;
reps(reps==inf) = 96;

% Test if spatial frequencies yield integer barwidths, barwidths are less
% than the total number of x-leds, & spatial frequencies are factors of 360
freqTest = round(barwidth)==barwidth & (barwidth<=pattern.x_panel | barwidth==inf) & round(360./wavelength)==(360./wavelength);
badFreq = find(~freqTest);
if any(~freqTest)
	err = '';
    for kk = 1:length(badFreq)
        err = [err,sprintf(['%1.1f' char(176) ' invalid \n'],wavelength(badFreq(kk)))];
    end
   error([err,'Valid frequencies are factors of 360' char(176) ' & divisible by 7.5' char(176)])    
end

% Make y-channe: spatial frequencies
Pats = zeros(pattern.y_panel,pattern.x_panel,pattern.x_num,pattern.y_num);
for jj = 1:pattern.y_num
    if barwidth(jj)==0 % for all panels low
        Pats(:,:, 1, jj) = Int.Low*ones(pattern.y_panel,pattern.x_panel);
    elseif barwidth(jj)==inf % for all panels high
        Pats(:,:, 1, jj) = Int.High*ones(pattern.y_panel,pattern.x_panel);        
    else % for any grating
        Pats(:,:, 1, jj) = repmat( [ Int.Low*ones(pattern.y_panel,barwidth(jj)/2) , ...
                                     Int.High*ones(pattern.y_panel,barwidth(jj)/2) ], 1,reps(jj) );
    end
end

% Make x-channe: yaw rotation
for jj = 1:pattern.y_num
    for ii = 2:pattern.x_num
        Pats(:,:,ii,jj) = ShiftMatrix(Pats(:,:,ii-1,jj), 1, 'r', 'y'); % shift one bit to right
    end
end

% Store pattern data
pattern.Pats = Pats;

% Store arena panel layout
pattern.Panel_map = [12 8  4  11 7  3  10 6  2  9  5  1 ;...    
                     24 20 16 23 19 15 22 18 14 21 17 13;...
                     36 32 28 35 31 27 34 30 26 33 29 25;...
                     48 44 40 47 43 39 46 42 38 45 41 37];

% Make BitMap
pattern.BitMapIndex = process_panel_map(pattern);

% Make data
pattern.data = Make_pattern_vector(pattern);

% Save pattern
if nargin==2 && ~isempty(root)
    % Name file
    strFreq = '';
    for kk = 1:length(wavelength)
       strFreq = [strFreq  num2str(wavelength(kk)) '_'];
    end
    strFreq = strtrim(strFreq);
	str = ['Pattern_SpatFreq_' strFreq 'gs=' num2str(pattern.gs_val) ...
            '_Cont=' num2str(Int.High) '-' num2str(Int.Low) '_48Pan.mat'];
    
    save(fullfile(root,str), 'pattern');
end
% disp('DONE')
end