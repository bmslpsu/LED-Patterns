function [] = MakePattern_FourierBar(barwidth,root,playPat,savePat)
%---------------------------------------------------------------------------------------------------------------------------------
% MakePattern_FourierBar: creates pattern of vertical bars with varying widths
% stimulus
%   INPUTS:
%       barwidth    :	width of bars
%       root        :	folder to save pattern
%       playPat     :   boolean to play pattern (1 is on, 0 is off): if any other number >>> playback at that frequency 
%       savePat     :   boolean to save pattern (1 is on, 0 is off)
%   OUTPUTS:
%
%---------------------------------------------------------------------------------------------------------------------------------
%   This program creates one structure ('pattern').  The relevant components of
%   this structure are as follows:
%
%       pattern     -  the parent structure
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
%
%   FIGWIDTH        -    width of figure in pixels
%% DEBUGGING %%
% ONLY UNCOMMENT & RUN THIS SECTION IF DEBUGGING %
%---------------------------------------------------------------------------------------------------------------------------------
% barwidth = 6;
% root = 'C:\';
% playPat = 1;
% savePat = 0;
%% Setup Parameters %%
%---------------------------------------------------------------------------------------------------------------------------------
%GENERAL PARAMETERS
pattern.x_num       = 96;   % # of frames in 'x' channel
pattern.y_num       = 96;   % # of frame in 'y' channel
pattern.x_panels    = 4;
pattern.y_panels    = 12;
pattern.num_panels  = pattern.x_panels*pattern.y_panels;   %number of unique panel IDs required; NOTE: this is a standard size for the 12*4 arena
pattern.x_size      = 8;
pattern.y_size      = 8;
pattern.gs_val      = 1;
pattern.row_compression = 1;

%MAKE 'pattern.Pats'
% (L,M,N,O)
% L = # of pixel rows(8); M = # of pixel cols(96); N = frames in x dir(96);
% O = frames in y dir(96)
Pats = zeros(4, 96, pattern.x_num, pattern.y_num);
%---------------------------------------------------------------------------------------------------------------------------------
% SPECIFIC PARAMETERS
pattern.name = 'Fourier_bar';    % define name of file for varying fig width
pattern.params.Figwidth = barwidth;
pattern.name = strcat(pattern.name,...
    '_barwidth=', num2str(pattern.params.Figwidth));

% Initialize Pattern
A = 0;
while A == 0
    % Band-pass filter pattern
    % make sure background contrast at 50%
    C = 1;
    while C == 1
        pattern_back = round(repmat(rand(1,96),[4 1])); % create random background
        % if overall contrast of background and figure = 50%
        if (sum(pattern_back(1,:)) == 96/2) && (sum(pattern_back(1,1:barwidth)) == barwidth/2)
            wc = diff(pattern_back(1,:));
            mm = 1;
            for jj = 1:length(wc)-1
                if (abs(wc(jj)) == 1) && (abs(wc(jj+1)) == 1)  % 1 pixel column
                    mm = mm + 1;
                end
            end
            if mm <= 10 % allow only 5 elements with widths = 3.75deg
                C = 0;
            end
        end
    end
    figure; imagesc(pattern_back);
    A = input('Accept pattern?'); % 1 yes, 0 no
    
    close all
end

pattern_fig = pattern_back;  % same for fig pattern
[x, y] = meshgrid(1:96,1:4);

% main loop
kk = 0;
mm = 0;

for ii = 1:pattern.y_num 
    fig_mask = x <= barwidth;
    for jj = 1:pattern.x_num
        fig_mask_temp = circshift(fig_mask,[0 kk]); % rotate fig mask 1 pix
        pattern_fig_temp = circshift(pattern_fig,[0 kk]); % rotate fig 1 pix
        %pattern_back_temp=circshift(pattern_back,[0 mm]); % rotate background 1 px while figure is fixed
        Pats(:,:,jj,ii) = pattern_back.*(1-fig_mask_temp)+...
            fig_mask_temp.*pattern_fig_temp;

        kk = kk + 1;

    end
end
%% Play Pattern %%
%---------------------------------------------------------------------------------------------------------------------------------
if playPat
    h = figure (1) ; clf % pattern window
    for jj = 1:3 % how many time to loop pattern
        for kk = 1:size(Pats,4) % play y-channel
            imagesc(Pats(:,:, kk, 1)) % display frame
            if 1==playPat % 
                pause % user clicks to move to next frame
            else      
                pause(1/playPat) % automatic frame rate
            end
        end
    end
    close(h)
end
%% Save Pattern %%
%---------------------------------------------------------------------------------------------------------------------------------
if savePat
    pattern.Pats = Pats; % store pattern data
    pattern.Panel_map = [12 8 4 11 7 3 10 6 2  9 5 1;...  % store arena panel layout
                         24 20 16 23 19 15 22 18 14 21 17 13;...
                         36 32 28 35 31 27 34 30 26 33 29 25;...
                         48 44 40 47 43 39 46 42 38 45 41 37];
    pattern.BitMapIndex = process_panel_map(pattern);
    pattern.data = make_pattern_vector(pattern);
    str = [root '\Pattern_RandomGround_48Pan.mat'];
    save(str, 'pattern');
end
disp('DONE')
end