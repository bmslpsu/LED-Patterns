function [pattern] = make_pattern_wave(wave, res, h, rc, root)
%% make_pattern_wave: makes pattern with two channels
%  Channel-X: changes spatial wavelength
%  Channel-Y: rotates ground
%
%   INPUTS:
%       wave    :       row vector containing spatial wavelength's [�]
%       res     :       spatial resolution of arena [�]
%       h       :      	arena height (# of panels not pixels)
%       rc      :       row compression on or off (boolean)
%       root    :       directory to save pattern file
%
%   OUTPUTS:
%       pattern :       parent structure
%           .x_num          -   xpos limits
%                               by convention, xpos relates to translation and
%                               rotations of a static pattern
%           .y_num          -   ypos limits
%                               by convention, ypos relates to non-length
%                               conserving transformations
%           .x_panels       -   number of panels in x direction
%           .y_panels       -   number of panels in y directions
%           .num_panels     -   number of panels in array
%                               (.x_panels*.y_panels)
%           .panel_size     -   '0' gives default 8x8, '1' allows user specific
%           .gs_val         -   gray scale value (1-4)
%           .Pats           -   data for the panels...a 4D array where
%                               (x_panels*x_size,y_panels*y_size,xpos,ypos)
%           .Panel_map      -   a 2x2 array specifying the location of the
%                               named panels indexed from '1'
%           .BitMapIndex	-   output generated by executing
%                               'process_panel_map(pattern);'
%           .data           -   output generated by executing
%                               'make_pattern_vector(pattern);'

% wave = 3.75*[0,2,4,6,8,12,16,24,32,48,96,inf];

if nargin < 5
    root = []; % don't save
    if nargin < 4
        rc = false; % default is row compression off
        if nargin < 3
            h = 2; % default is 2 panels high
            if nargin < 2
                res = 3.75; % default arena resolution [�]
            end
        end
    end
end

% Set panel variables
pattern.gs_val = 1; % pattern will use 2 intensity levels
pattern.row_compression = rc; % row compression flag
pattern.pixel_per_panel = 8; % pixels per panel
pattern.res = res; % spatial resolution of arena
pattern.height = h; % arena height (# panels)
pattern.x_pixel = 360/pattern.res;	% # of x-pixels
pattern.y_pixel = pattern.height;	% # of y-pixels

if ~pattern.row_compression % if row compression is off
    pattern.y_pixel = pattern.y_pixel * pattern.pixel_per_panel;
end

% Ensure arena resolution is attainable
assert(round(pattern.x_pixel) == pattern.x_pixel, ...
    'Arena resolution must yield an integer number of pixels')

% Set pattern channel variables
pattern.x_num = pattern.x_pixel; % pattern will move trhough each x-pixel in x-channel
pattern.y_num = length(wave); % # of spatial wavelength's for y-channel
pattern.num_panel = (pattern.x_pixel/pattern.pixel_per_panel)*pattern.height; % # of unique panel IDs required

% Calculate bar widths for each wavelength
barwidth = pattern.x_num*(wave./360);

% Calculate # of cycle repetitions for each wavelength
reps = 360./wave;
reps(reps==inf) = 96;

% Ensure wavelengths yield integer barwidths, barwidths are less
% than the total number of x-pixels, & wavelength are factors of 360
waveTest = round(barwidth)==barwidth & (barwidth<=pattern.x_pixel | barwidth==inf) ...
    & round(360./wave)==(360./wave);
badWave = find(~waveTest);
if any(~waveTest)
	err = '';
    for kk = 1:length(badWave)
        err = [err,sprintf(['%1.1f' char(176) ' invalid \n'],wave(badWave(kk)))];
    end
   error([err,'Valid wavelengths are factors of 360� & divisible by 7.5�'])    
end

% Make y-channel: spatial wavelengths
Int.High = 1; % high intensity value (0-15)
Int.Low  = 0; % low intensity value (0-15)
Pats = zeros(pattern.y_pixel, pattern.x_pixel, pattern.x_num, pattern.y_num);
for jj = 1:pattern.y_num
    if barwidth(jj) == 0 % for all panels low
        Pats(:,:, 1, jj) = Int.Low*ones(pattern.y_pixel, pattern.x_pixel);
    elseif barwidth(jj) == inf % for all panels high
        Pats(:,:, 1, jj) = Int.High*ones(pattern.y_pixel, pattern.x_pixel);        
    else % for any grating
        Pats(:,:, 1, jj) = repmat( [ Int.Low*ones(pattern.y_pixel,barwidth(jj)/2) , ...
                                     Int.High*ones(pattern.y_pixel,barwidth(jj)/2) ], 1, reps(jj) );
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
Panel_map = [12 8  4  11 7  3  10 6  2  9  5  1 ;...    
                     24 20 16 23 19 15 22 18 14 21 17 13;...
                     36 32 28 35 31 27 34 30 26 33 29 25;...
                     48 44 40 47 43 39 46 42 38 45 41 37];
pattern.Panel_map = Panel_map(1:pattern.height, :);

% Make BitMap
pattern.BitMapIndex = process_panel_map(pattern);

% Make data
pattern.data = Make_pattern_vector(pattern);

% Save pattern
if ~isempty(root)
    % Name file
    strWave = '';
    for kk = 1:length(wave)
       strWave = [strWave  num2str(wave(kk)) '_'];
    end
    strWave = strtrim(strWave);
	str = ['pattern_wave_' strWave 'gs=' num2str(pattern.gs_val) '_cont=' num2str(Int.High) ...
        '-' num2str(Int.Low) '_' num2str(pattern.num_panel) 'pannel.mat'];
    
    save(fullfile(root,str), 'pattern');
end

end