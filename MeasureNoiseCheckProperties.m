% MeasureNoiseCheckProperties.m
%
% function to loop through Noise Check images (used in Incomplete Letter generation) to
% find a likely ConInc (contrast increment) for a patch of noise with given dimensions to later be sampled for incomplete letter generation
%
% code by J Greenwood
% v1, June 2023

%% get started

clear all;

% take a datestamp to begin
datestamp.Start = datestr(now,'dd.mm.yyyy-HH.MM.SS'); %take datestamp for timing of function

SaveOutput = 1; %0/1 to save file at the end

%% parameters
ImWidth = 275;
CheckSize = 11;
NumImages = 100; %how many images per ConInc value

ConIncVals = -1.5:0.001:1.5;
NumConInc  = numel(ConIncVals);

% set up baseline value for image size
TotalPix    = numel(randn(ImWidth,ImWidth));

%% loop through Contrast Increment Values and measure Completeness Proportions (proportion white pixels)

for cc=1:NumConInc
    for ii=1:NumImages
        NoiseIm = MakeCheckNoiseFun(ImWidth,ConIncVals(cc),CheckSize); %generate a new noise image with desired check size
        NoiseWhitePixNum = sum(All(NoiseIm==1)); %work out total number of pixels within the incomplete letter
        FinalCompVal(cc,ii)  = NoiseWhitePixNum./TotalPix; %PropComp = fragletter pixels / original letter pixels
    end
end

%% summary values
MeanCompleteness = mean(FinalCompVal,2);
MinCompleteness  = min(FinalCompVal,[],2); %highest completeness level at each ConIncVal etc
MaxCompleteness  = max(FinalCompVal,[],2);

%% plot and fit psychometric function since relationship between ConInc and completeness looks sigmoidal
figure
%plot completeness
plot(ConIncVals,MeanCompleteness,'k-');
hold on;
plot(ConIncVals,MinCompleteness,'k--');
plot(ConIncVals,MaxCompleteness,'k--');
title('Completeness Values for Noise Images');
xlabel('Contrast Increment');
ylabel('Completeness');

figure
plot(ConIncVals,MeanCompleteness,'k-','LineWidth',2);
hold on;
%fit and draw psychometric function
xfine            = min(ConIncVals(:)):0.0001:max(ConIncVals(:));
[psyfun_u,psyfun_v,psyfun_kp,cuts,fb] = FitCumuGaussian(ConIncVals,MeanCompleteness',NumImages,0,0,[1 1 0],0,0.5,1); %curve fit 
yfit             = DrawCumuGaussian(xfine,psyfun_u,psyfun_v,psyfun_kp,0,1); %draw the weighted curve
plot(xfine,yfit,'r-','LineWidth',2);
title('Completeness Values for Noise Images');
xlabel('Contrast Increment');
ylabel('Completeness');


%% check time (for optimisation)
datestamp.End = datestr(now,'dd.mm.yyyy-HH.MM.SS');
datestamp.MinsTaken = etime(datevec(datestamp.End,'dd.mm.yyyy-HH.MM.SS'),datevec(datestamp.Start,'dd.mm.yyyy-HH.MM.SS'))/60;
datestamp.HoursTaken = datestamp.MinsTaken/60;
fprintf('Done! Analysis completed in %3.2f mins (%3.2f hours)\n',datestamp.MinsTaken,datestamp.HoursTaken);

if SaveOutput
    thisFile='MeasureNoiseCheckProperties.m'; %store the filename
    ThisDirectory=which(thisFile);
    ThisDirectory=ThisDirectory(1:end-length(thisFile)); %get the directory where our file is

    fName=sprintf('%s/%s_%1dImW_%1dCheckSize_%1dNumIm_%s.mat',ThisDirectory,'NoiseCheckValOutput',ImWidth,CheckSize,NumImages,datestr(now,'yyyy.mm.dd-HH.MM.SS')); %generate file name with time stamp
    save(fName,'ConIncVals','FinalCompVal','MeanCompleteness','MinCompleteness','MaxCompleteness','psyfun_u','psyfun_v','psyfun_kp','xfine','yfit'); %save variables into .mat file to be re-loaded later
end
