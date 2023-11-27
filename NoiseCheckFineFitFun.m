function [ConInc,FinalCompLevel,err1,datestamp] = NoiseCheckFineFitFun(ImWidth,PropComp,CheckSize,NumImages);
% [ConInc,FinalCompLevel,err1,datestamp] = NoiseCheckFineFitFun(ImWidth,PropComp,CheckSize,NumImages);
%
% function to find a likely ConInc (contrast increment) for a patch of
% noise with given dimensions to later be sampled for incomplete letter generation
% needs inputs of ImWidth (image width in pixels), PropComp (proportion completeness in the letter 0-1, formerly IntactPropt),
% CheckSize (size of the 'checks' for the noise in pixels), and NumImages (how many images to run on each iteration of the finefit to minimise stochastic effects)
%
% code by J Greenwood
% v1, June 2023
%
% e.g. [ConInc,FinalCompLevel,err1,datestamp] = NoiseCheckFineFitFun(275,0.15,11,10); disp(FinalCompLevel); disp(ConInc);


%% get started

% take a datestamp to begin
datestamp.Start = datestr(now,'dd.mm.yyyy-HH.MM.SS'); %take datestamp for timing of function

% set up baseline value for image size
TotalPix    = numel(randn(ImWidth,ImWidth));

%% run fminsearch to generate image with desired completeness level

global ActualComp; %make this a global value to extract it from the fitting function (a little hacky)
ActualComp = [];

opt = optimset(optimset,'MaxFunEvals',1000,'MaxIter',10000,'TolFun',1e-8,'TolX',1e-8,'Display','off'); %options for the fit

guessConInc = 0; %where ~ -1.5 is full black and ~ +1.5 is full white - used to alter balance of white vs black pixels in noise image

[ConInc,err1,exitflag,output] = fminsearch(@gFitFun,guessConInc,opt,PropComp,CheckSize,NumImages,ImWidth,TotalPix);

%extract actual completeness level from image
FinalCompLevel       = ActualComp; %PropComp = fragletter pixels / original letter pixels

%check time (for optimisation)
datestamp.End = datestr(now,'dd.mm.yyyy-HH.MM.SS');
datestamp.MinsTaken = etime(datevec(datestamp.End,'dd.mm.yyyy-HH.MM.SS'),datevec(datestamp.Start,'dd.mm.yyyy-HH.MM.SS'))/60;
datestamp.HoursTaken = datestamp.MinsTaken/60;

%% fine-fitting function

    function ImErr=gFitFun(ConInc,PropComp,CheckSize,NumImages,ImWidth,TotalPix)%,data,WhichFit,fixVals) %just input the parameters as p and the x values as x to make a function which is compared against the input data by lsqcurvefit

    %generate noise
%    NoiseImSize  = round(ImWidth./CheckSize); %initial size to generate noise image before downsampling to match image size
%    NoiseAll     = randn(NoiseImSize,NoiseImSize,NumImages); %generate random noise image centred on 0

    %adjust the noise images and look at error in proportion 'complete' (white)
    for ii=1:NumImages
        NoiseIm = MakeCheckNoiseFun(ImWidth,ConInc,CheckSize); %generate a new noise image with desired check size
%        NoiseIm     = imresize(NoiseAll(:,:,ii),[ImWidth ImWidth],'nearest'); %resize noise image to have same size as letter
%         NoiseIm     = (NoiseIm./max(abs(NoiseIm(:))))+ConInc; %convert to -1 to 1 and add contrast increment/decrement to shift mean balance
%         NoiseIm     = round((NoiseIm./2)+0.5);

        NoiseWhitePixNum = sum(All(NoiseIm==1)); %work out total number of pixels within the incomplete letter
        TempComp(ii)  = NoiseWhitePixNum./TotalPix; %PropComp = fragletter pixels / original letter pixels
        %NoiseComp(ii) = sum(All(NoiseIm==1))./numel(NoiseIm);
        AllErr(ii)      = sum((PropComp-TempComp(ii)).^2);
    end

    %[~,ErrInd]=min(AllErr); %find which image had the lowest error

    %pass through values of best image
    ActualComp = mean(TempComp);%TempComp(ErrInd);

    ImErr      = mean(AllErr);%sum((PropComp-ActualComp).^2);

    end

end