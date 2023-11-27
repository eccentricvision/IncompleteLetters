function [FinalIm,ActualComp,datestamp] = MakeIncompleteLetterFun(ImWidth,ImBorder,ConInc,CheckSize,WhichLetter);
% [FinalIm,ActualComp,datestamp] = MakeIncompleteLetterFun(ImWidth,ImBorder,ConInc,CheckSize,WhichLetter);
%
% function to draw a single incomplete letter
% needs inputs of ImWidth (image width in pixels), ImBorder (gap between letter and image boundaries - best at 0),
% ConInc (the contrast increment applied to the image before rounding, which drives the completeness level, usually ±1),
% CheckSize (size of the 'checks' for the noise in pixels) and WhichLetter as a string e.g. 'S'
%
% code by Keir Yong & J Greenwood
% formerly part of MakeFragLetterSloan.m
% new in v3 - letters now generated via function below that uses fminsearch
% v3, June 2023
%
% e.g. [FinalIm,ActualComp,datestamp] = MakeIncompleteLetterFun(275,0,-0.3,11,'P');imshow(FinalIm);

% take a datestamp to begin
datestamp.Start = datestr(now,'dd.mm.yyyy-HH.MM.SS'); %take datestamp for timing of function

%% file locations

comp            = Screen('Computer'); %gets username as comp.processUserShortName (on macs)
LetterFileDir   = strcat('/Users/',comp.processUserShortName,'/Documents/MATLAB/Stimuli/Letters/Sloan/'); %folder where the letter images are - change as needed!

%% set up baseline letter image (black letter on white BG)

ImHeight        = ImWidth; %make square images
LetterFile      = strcat(WhichLetter,'_Sloan.tif'); %make the filename
LetterTemp      = imread(strcat(LetterFileDir,LetterFile));%load the relevant file (note letter image begins as white on grey BG)
LetterIm(:,:,1) = imresize(LetterTemp,[ImHeight ImWidth],'nearest'); %resize letter image to desired size

LetterIm = single(LetterIm)./255; %convert values to 0-1
LetterIm(LetterIm<1)=0; %convert to black-and-white (NB white letter on black BG for now - convert later)
LetterPixNum        = sum(All(LetterIm(:,:,1)==1)); %work out total number of pixels within each letter

%generate noise
NoiseImSize = round(ImWidth./CheckSize); %initial size to generate noise image before downsampling to match image size

NoiseIm     = randn(NoiseImSize,NoiseImSize); %generate random noise image centred on 0
NoiseIm     = imresize(NoiseIm,[ImHeight ImWidth],'nearest'); %resize noise image to have same size as letter
NoiseIm     = (NoiseIm./max(abs(NoiseIm(:))))+ConInc; %convert to -1 to 1 and add contrast increment/decrement to shift mean balance
NoiseIm     = round((NoiseIm./2)+0.5);

%combine the letter image and the noise image
FinalIm  = LetterIm(:,:,1).*NoiseIm;

%derive properties
IncLetterPixNum = sum(All(FinalIm==1)); %work out total number of pixels within the incomplete letter
ActualComp      = IncLetterPixNum./LetterPixNum; %PropComp = fragletter pixels / original letter pixels

%now final coversion of image
FinalIm = 1-FinalIm; %convert to black letters on white BG

%add image border if needed
if ImBorder>0 %if border is added
    FinalIm = PadIm(FinalIm,[ImWidth+ImBorder ImHeight+ImBorder],1);
end

%check time
datestamp.End = datestr(now,'dd.mm.yyyy-HH.MM.SS');
datestamp.MinsTaken = etime(datevec(datestamp.End,'dd.mm.yyyy-HH.MM.SS'),datevec(datestamp.Start,'dd.mm.yyyy-HH.MM.SS'))/60;
datestamp.HoursTaken = datestamp.MinsTaken/60;

end