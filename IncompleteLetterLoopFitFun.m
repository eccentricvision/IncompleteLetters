function [FinalIm,ConInc,FinalCompLevel,datestamp,NumAttempts] = IncompleteLetterLoopFitFun(ImWidth,ImBorder,PropComp,CheckSize,WhichLetter,NumImages,Tol,MaxAttempts);
% [FinalIm,ConInc,FinalCompLevel,datestamp,NumAttempts] = IncompleteLetterLoopFitFun(ImWidth,ImBorder,PropComp,CheckSize,WhichLetter,NumImages,Tol,MaxAttempts);
%
% code to generate an Incomplete Letter at a desired Completeness level
% uses a brute-force looping approach - starts from a likely contrast increment value (ConInc) and generates x images from which the best match is taken
% needs inputs of ImWidth (image width in pixels), ImBorder (gap between letter and image boundaries on each side - best at 0),
% PropComp (proportion completeness in the letter 0-1, formerly IntactPropt),
% CheckSize (size of the 'checks' for the noise in pixels),  WhichLetter as a string e.g. 'S', NumImages (the number of images generated to find best match),
% Tol (the tolerance between desired and actual Proportion Completeness that is allowed), and MaxAttempts (how many times to try and reach desired tolerance level)
%
% code by J Greenwood, based on code with Keir Yong - formerly part of MakeFragLetterSloan.m
% v1.1, November 2023
%
% e.g. [FinalIm,ConInc,FinalCompLevel,datestamp,NumAttempts] = IncompleteLetterLoopFitFun(275,0,0.15,11,'P',100,0.001,10); imshow(FinalIm);

%% parameters to begin
datestamp.Start = datestr(now,'dd.mm.yyyy-HH.MM.SS'); %take datestamp for timing of function

%NumImages = 1000; %how many letter images to generate to try and find a close match - now input parameter
%Tol       = 0.001; %tolerance for the difference between desired and actual Proportion Complete - now input parameter

%% file locations

comp             = Screen('Computer'); %gets username as comp.processUserShortName (on macs)
thisFile='IncompleteLetterLoopFitFun.m'; %the filename
ThisDirectory=which(thisFile);
ThisDirectory=ThisDirectory(1:end-length(thisFile)); %get the directory where our file is

LetterFileDir    = strcat('/Users/',comp.processUserShortName,'/Documents/MATLAB/Stimuli/Letters/Sloan/'); %folder where the letter images are - change as needed!
ConIncLUTFileDir = strcat(ThisDirectory,'/ConIncLUTs/'); %folder where the Lookup Tables for ConInc vals are - change as needed!

%% set up baseline letter image (black letter on white BG)

ImHeight     = ImWidth; %make square images

LetterFile      = strcat(WhichLetter,'_Sloan.tif'); %make the filename
LetterTemp      = imread(strcat(LetterFileDir,LetterFile));%load the relevant file (note letter image begins as white on grey BG)
LetterIm(:,:,1) = imresize(LetterTemp,[ImHeight ImWidth],'nearest'); %resize letter image to desired size

LetterIm = single(LetterIm)./255; %convert values to 0-1
LetterIm(LetterIm<1)=0; %convert to black-and-white (NB white letter on black BG for now - convert later)
LetterPixNum        = sum((LetterIm(:,:,1)==1),'all'); %work out total number of pixels within each letter

%% load LUT for ConInc values to find ConInc value to aim for in letter generation

load(strcat(ConIncLUTFileDir,'NoiseCheckValOutput_275ImW_11CheckSize_100NumIm_2023.06.22-11.06.08.mat')); %best file thus far - NB includes yfit values from psychometric function fit

[~,ConIncInd] = min(abs(yfit-PropComp)); %find index for ConInc val in the yfit values that corresponds on average to desired PropComp
ConInc = xfine(ConIncInd);

%% generate a set of images and find the one with the closest match

if PropComp<1 % need to generate incomplete letter - otherwise just return the letter
    %generate noise
    ImHeight    = ImWidth; %to make square images
    NoiseImSize = round(ImWidth./CheckSize); %initial size to generate noise image before downsampling to match image size

    %combine the letter image and the noise image
    %StopTheLoop = 0; %flag to loop or keep going
    %while StopTheLoop==0
    for aa=1:MaxAttempts %generate a new set of noise images and try again each time
        NoiseAll    = randn(NoiseImSize,NoiseImSize,NumImages); %generate random noise image centred on 0
        clear NoiseIm; clear TempIm; clear TempComp; clear AllErr; %clear relevant values for each iteration
        for ii=1:NumImages
            NoiseIm     = imresize(NoiseAll(:,:,ii),[ImHeight ImWidth],'nearest'); %resize noise image to have same size as letter
            NoiseIm     = (NoiseIm./max(abs(NoiseIm(:))))+ConInc; %convert to -1 to 1 and add contrast increment/decrement to shift mean balance
            NoiseIm     = round((NoiseIm./2)+0.5);

            TempIm(:,:,ii)  = LetterIm(:,:,1).*NoiseIm;
            IncLetterPixNum = sum((TempIm(:,:,ii)==1),'all'); %work out total number of pixels within the incomplete letter
            TempComp(ii)    = IncLetterPixNum./LetterPixNum; %PropComp = fragletter pixels / original letter pixels
            AllErr(ii)      = abs((PropComp-TempComp(ii))); %absolute error between real and desired propcomp
        end

        [minErr,ErrInd]=min(AllErr); %find which image had the lowest error
        if minErr<=Tol
            %StopTheLoop = 1; %tolerance value reached
            NumAttempts = aa;
            break;%aa=MaxAttempts; %fast-forward the loop
            fprintf('Tolerance reached\n');
        else
            if aa==MaxAttempts %print warning to screen
                fprintf('Warning!! Max. attempts reached for Incomplete Letter Generation: Letter %s PropComp %1.2f \n',WhichLetter,PropComp);
                %disp('***');disp(strcat('Warning: Max. attempts reached for Incomplete Letter Generation: Letter_',WhichLetter,'_PropComp_',num2str(PropComp)));disp('***');
                NumAttempts=MaxAttempts;
                StopTheLoop = 1; %give up
            end
        end
        %    end
    end
    %work out best-fitting values and get image
    FinalCompLevel = TempComp(ErrInd);

    FinalIm        = 1-(TempIm(:,:,ErrInd));
else %just return the letter with propcomp=1
    FinalIm = 1-LetterIm;

    FinalCompLevel = 1.000;
    NumAttempts    = NaN;
end

%add image border if needed
if ImBorder>0 %if border is added
    FinalIm        = PadIm(FinalIm,[ImWidth+(ImBorder*2) ImHeight+(ImBorder*2)],1);
end

%check time (for optimisation)
datestamp.End = datestr(now,'dd.mm.yyyy-HH.MM.SS');
datestamp.SecsTaken  = etime(datevec(datestamp.End,'dd.mm.yyyy-HH.MM.SS'),datevec(datestamp.Start,'dd.mm.yyyy-HH.MM.SS'));
datestamp.MinsTaken  = datestamp.SecsTaken/60;
datestamp.HoursTaken = datestamp.MinsTaken/60;

end