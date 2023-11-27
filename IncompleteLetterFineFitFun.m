function [FinalIm,ConInc,FinalCompLevel,err1,datestamp] = IncompleteLetterFineFitFun(ImWidth,ImBorder,PropComp,CheckSize,WhichLetter);
% LetterIm = IncompleteLetterFineFitFun(ImWidth,ImBorder,PropComp,CheckSize,WhichLetter);
%
% needs inputs of ImWidth (image width in pixels), ImBorder (gap between letter and image boundaries - best at 0),
% PropComp (proportion completeness in the letter 0-1, formerly IntactPropt),
% CheckSize (size of the 'checks' for the noise in pixels) and WhichLetter as a string e.g. 'S'
%
% code by Keir Yong & J Greenwood
% formerly part of MakeFragLetterSloan.m
% new in v3 - letters now generated via function below that uses fminsearch
% v3, June 2023
%
% e.g. [FinalIm,ConInc,FinalCompLevel,err1,datestamp] = IncompleteLetterFineFitFun(275,0,0.15,11,'P'); imshow(FinalIm);
%

%% parameters to begin
datestamp.Start = datestr(now,'dd.mm.yyyy-HH.MM.SS'); %take datestamp for timing of function

NumImages = 5; %how many letter images to generate on each iteration of the function below (reduces effects of stochasticity in the image generation)

%% file locations

comp            = Screen('Computer'); %gets username as comp.processUserShortName (on macs)
LetterFileDir   = strcat('/Users/',comp.processUserShortName,'/Documents/MATLAB/Stimuli/Letters/Sloan/'); %folder where the letter images are - change as needed!

%% set up baseline letter image (black letter on white BG)

ImHeight     = ImWidth; %make square images

LetterFile      = strcat(WhichLetter,'_Sloan.tif'); %make the filename
LetterTemp      = imread(strcat(LetterFileDir,LetterFile));%load the relevant file (note letter image begins as white on grey BG)
LetterIm(:,:,1) = imresize(LetterTemp,[ImHeight ImWidth],'nearest'); %resize letter image to desired size

LetterIm = single(LetterIm)./255; %convert values to 0-1
LetterIm(LetterIm<1)=0; %convert to black-and-white (NB white letter on black BG for now - convert later)
LetterPixNum        = sum(All(LetterIm(:,:,1)==1)); %work out total number of pixels within each letter

%% run fminsearch to generate image with desired completeness level

global FitIm; %set FitIm as a global variable so it can be returned after the fminsearch (a bit hacky)
FitIm = []; %start with a clear image;

opt = optimset(optimset,'MaxFunEvals',1000,'MaxIter',10000,'TolFun',1e-8,'TolX',1e-8,'Display','off'); %options for the fit

guessConInc = 0; %where ~ -1.5 is full black and ~ +1.5 is full white - used to alter balance of white vs black pixels in noise image

[ConInc,err1,exitflag,output] = fminsearch(@gFitFun,guessConInc,opt,LetterIm,ImWidth,PropComp,CheckSize,LetterPixNum,NumImages);

%extract actual completeness level from image
IncLetterPixNumFinal = sum(All(FitIm(:,:,1)==1)); %work out total number of pixels within the incomplete letter
FinalCompLevel       = IncLetterPixNumFinal./LetterPixNum; %PropComp = fragletter pixels / original letter pixels

%now final coversion of image
FragLetIm = 1-FitIm; %convert to black letters on white BG

%add image border if needed
if ImBorder>0 %if border is added
    for ll=1:NumLetters
        FinalIm(:,:,ll) = PadIm(FragLetIm(:,:,ll),[ImWidth+ImBorder ImHeight+ImBorder],1);
    end
else %no border
    FinalIm = FragLetIm; %just pass the image along - no border
end

%check time (for optimisation)
datestamp.End = datestr(now,'dd.mm.yyyy-HH.MM.SS');
datestamp.MinsTaken = etime(datevec(datestamp.End,'dd.mm.yyyy-HH.MM.SS'),datevec(datestamp.Start,'dd.mm.yyyy-HH.MM.SS'))/60;
datestamp.HoursTaken = datestamp.MinsTaken/60;

%% fine-fitting function

    function ImErr=gFitFun(ConInc,LetterIm,ImWidth,PropComp,CheckSize,LetterPixNum,NumImages)%,data,WhichFit,fixVals) %just input the parameters as p and the x values as x to make a function which is compared against the input data by lsqcurvefit

    %generate noise
    ImHeight    = ImWidth; %to make square images
    NoiseImSize = round(ImWidth./CheckSize); %initial size to generate noise image before downsampling to match image size

    NoiseAll     = randn(NoiseImSize,NoiseImSize,NumImages); %generate random noise image centred on 0

    %combine the letter image and the noise image
    for ii=1:NumImages
        NoiseIm     = imresize(NoiseAll(:,:,ii),[ImHeight ImWidth],'nearest'); %resize noise image to have same size as letter
        NoiseIm     = (NoiseIm./max(abs(NoiseIm(:))))+ConInc; %convert to -1 to 1 and add contrast increment/decrement to shift mean balance
        NoiseIm     = round((NoiseIm./2)+0.5);

        TempIm(:,:,ii)  = LetterIm(:,:,1).*NoiseIm;
        IncLetterPixNum = sum(All(TempIm(:,:,ii)==1)); %work out total number of pixels within the incomplete letter
        TempComp(ii)  = IncLetterPixNum./LetterPixNum; %PropComp = fragletter pixels / original letter pixels
        NoiseComp(ii) = sum(All(NoiseIm==1))./numel(NoiseIm);
        AllErr(ii)      = sum((PropComp-TempComp(ii)).^2);
    end

    [~,ErrInd]=min(AllErr); %find which image had the lowest error

    %pass through values of closest image
    FitIm           = TempIm(:,:,ErrInd);%LetterIm(:,:,1).*NoiseIm;
    ActualComp      = TempComp(ErrInd);
    %IncLetterPixNum = sum(All(FitIm==1)); %work out total number of pixels within the incomplete letter
    %ActualComp      = IncLetterPixNum./LetterPixNum; %PropComp = fragletter pixels / original letter pixels

    ImErr = sum((PropComp-ActualComp).^2);

    end

end