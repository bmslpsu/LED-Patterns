function [pattern] = MakePattern_Bar(barwidth,root)
%% MakePattern_FourierBar: creates pattern of vertical bars with varying widths & a moving bar
%   INPUTS:
%       barwidth    :	width of bars
%       root        :	folder to save pattern
%   OUTPUTS:
%       pattern     : pattern structure
%
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
%       barwidth  	-    width of figure in pixels
%

% Parameters
pattern.x_num       = 96;
pattern.y_num       = 96;
pattern.x_panel     = 96;
pattern.y_panel     = 4;
pattern.num_panels  = 48;
pattern.x_size      = 8;
pattern.y_size      = 8;
pattern.gs_val      = 1;
pattern.row_compression = 1;

pattern.name = 'Fourier_bar'; % define name of file for varying fig width
pattern.params.Figwidth = barwidth;
pattern.name = strcat(pattern.name,...
    '_barwidth=', num2str(pattern.params.Figwidth));

% Initialize Pattern
Pats = zeros(4, 96, pattern.x_num, pattern.y_num);
pattern_back = round(repmat(zeros(1,96),[4 1])); % create random background

pattern_fig = pattern_back;  % same for fig pattern
pattern_fig(:,1:barwidth) = 1;
[x, ~] = meshgrid(1:96,1:4);

kk = 0;
for ii = 1:pattern.y_num 
    fig_mask = x <= barwidth;
    for jj = 1:pattern.x_num
        fig_mask_temp = circshift(fig_mask,[0 kk]); % rotate fig mask 1 pix
        pattern_fig_temp = circshift(pattern_fig,[0 kk]); % rotate fig 1 pix
        Pats(:,:,jj,ii) = pattern_back.*(1-fig_mask_temp)+...
            fig_mask_temp.*pattern_fig_temp;

        kk = kk + 1;

    end
end

pattern.Pats = Pats; % store pattern data

pattern.Panel_map = [12 8 4 11 7 3 10 6 2  9 5 1;...  % store arena panel layout
                     24 20 16 23 19 15 22 18 14 21 17 13;...
                     36 32 28 35 31 27 34 30 26 33 29 25;...
                     48 44 40 47 43 39 46 42 38 45 41 37];
                 
pattern.BitMapIndex = process_panel_map(pattern);

pattern.data = Make_pattern_vector(pattern);

% Save Pattern %
if nargin==2
    str = [root '\Pattern_Bar_48Pan.mat'];
    save(str, 'pattern');
end

disp('DONE')
end