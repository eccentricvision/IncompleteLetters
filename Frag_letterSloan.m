%code by Keir Yong

clear all
close all
%% Setup figure and image matrix
width_height = [500 500]; % should result in A being 400 x 400
FontSize = 180; % chosen to fit 'W' and 'Q' (largest letters)
fig1 = figure('Color', 'White', 'Position', [100 100 width_height]);
fig2 = figure('Color', 'White', 'Position', [100 100 width_height]);

%copyfile('C:\Users\yong\AppData\Local\Microsoft\Windows\Fonts\Sloan.ttf', fullfile(java.lang.System.getProperty('java.home').toCharArray', 'lib', 'fonts')) % Replace 'path\to\font\file\font.ttf' with the location of the font file.


axis equal, axis on
fr = getframe; A = zeros(size(fr.cdata, 1), size(fr.cdata, 2));
set(gca,'fontname','Sloan')


test_chars = char([65:90 48:57]);

M = length(test_chars);
dis = zeros(1, M);


    cla(fig1)
    text(0.5, 0.5, test_chars(3), ...
        'HorizontalAlignment', 'Center', 'FontSize', FontSize,'fontname','Sloan');
        fr = getframe;
        im = fr.cdata;
    pause
        im = double(rgb2gray(im));
    % imwrite(B, fullfile('images', ['image_' test_chars(m) '.png']));



ind_black = find(im==0);
N_ind_black = length(ind_black)
pause

%Create rectangles

numrects = 8;         %choose your own value
minx = -6; maxx = 6;  %choose your own values
miny = -8; maxy = 8;    %choose your own values
rectpos = rand(numrects, 4) .* repmat([maxx - minx, maxy - miny], numrects, 2) + repmat([minx, miny], numrects, 2);  %get random corner coordinates
rectpos = [min(rectpos(:, [1, 2]), rectpos(:, [3, 4])), abs(rectpos(:, [3, 4]) - rectpos(:, [1, 2]))];  %transform in [x, y, width, height]
rectcolour = rand(numrects, 3);
xlim([minx, maxx]);
ylim([miny, maxy]);

    cla(fig2)
    text(0.5, 0.5, test_chars(3), ...
        'HorizontalAlignment', 'Center', 'FontSize', FontSize,'fontname','Sloan');
    % imwrite(B, fullfile('images', ['image_' test_chars(m) '.png']));
for row = 1:numrects
    rectangle('Position', rectpos(row, :), 'FaceColor', [1 1 1],'EdgeColor',[1 1 1])
end
        fr2 = getframe;
        im2 = fr2.cdata;
        im2 = double(rgb2gray(im2));

ind_black2 = find(im2==0);
N_ind_black2 = length(ind_black2)

ratio = N_ind_black2 /N_ind_black