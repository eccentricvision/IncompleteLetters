%MakeFragLetterSloan
%code to generate fragmented letters, similar to the VOSP test
%here using Sloan letters, loaded from image files
%specify image size, IntactProp (proportion letter intact = 1/fragmentation) and checksize under image parameters below
%
%code by Keir Yong, modified J Greenwood
%v2.1, June 2022

clear all;
%close all;
CodeStart = datestr(now,'dd.mm.yyyy-HH.MM.SS');

%% file locations

comp          = Screen('Computer'); %gets username as comp.processUserShortName (on macs)
LetterFileDir = strcat('/Users/',comp.processUserShortName,'/Documents/MATLAB/Stimuli/Letters/Sloan/'); %folder where the letter images are - change as needed!

%% image parameters

%TestChars = {'H','O','T','V'}; %4AFC
%TestChars = {'H','O','T','V','U','X'}; %6AFC
%TestChars = {'C','D','H','K','N','O','R','S','V','Z'};%10AFC
TestChars = {'P'};%{'C','D','E','F','H','K','N','P','R','U','V','Z'}; %12AFC - matched to visual acuity testing in UK Biobank
%TestChars = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}; %26AFC

ImWidth  = 275;%30;%500; %pixels
ImHeight = ImWidth;
ImBorder = 0;%round(ImWidth/3); %add white pixels to border for display image?

IntactProp   = 0.15;%0.20;%proportion intact - where 0=fully fragmented and 1 is fully intact
CheckSize    = 11;%11;%2;%20; %each 'check' in the noise image (that becomes the 'fragments') is X pixels wide - with 500 pixel width, stroke width = 100pix so 20pix checks gives 5/stroke
NoiseImSize  = round(ImWidth./CheckSize); %initial size to generate noise image before downsampling to match image size

NumLetters    = numel(TestChars);

%% load the relevant letter and re-size the image as needed

for ll=1:NumLetters
    LetterFile       = strcat(TestChars{ll},'_Sloan.tif'); %make the filename
    LetterTemp       = imread(strcat(LetterFileDir,LetterFile));%load the relevant file (note letter is white on grey BG)
    LetterIm(:,:,ll) = imresize(LetterTemp,[ImHeight ImWidth],'nearest'); %resize letter image to desired size
end

LetterIm = single(LetterIm)./255; %convert values to 0-1
LetterIm(LetterIm<1)=0; %convert to black-and-white (NB white letter on black BG for now - convert later)

for ll=1:NumLetters
    LetterPixNum(ll) = sum(All(LetterIm(:,:,ll)==1)); %work out total number of pixels within each letter
    TotalPixNum(ll)  = numel(LetterIm(:,:,ll)); %total number of pixels in each image
end

%% make a noise background and get it to the desired proportion intact

ContrastInc = 0; %where ~ -1.5 is full black and ~ +1.5 is full white - used to alter balance of white vs black pixels in noise image

for ll=1:NumLetters
    Tol             = 0.001; %how much variation we're comfortable with in the difference between desired and actual IntactProp (prev 0.001)
    ContrastIncStep = 0.001; %size of the contrast inc step (prev 0.01)
    KeepGoing   = 1;
    cnt=0;
    %NB. use ContrastInc of last letter as a likely starting point for subsequent letters

    while KeepGoing
        if IntactProp==1 %for whole letters just make a black image to be quick about it
            NoiseIm   = ones(ImHeight,ImWidth);
            KeepGoing = 0; %no need to keep checking
        else %generate noise
            NoiseIm     = randn(NoiseImSize,NoiseImSize); %generate random noise image centred on 0
            NoiseIm     = imresize(NoiseIm,[ImHeight ImWidth],'nearest'); %resize noise image to have same size as letter
            NoiseIm     = (NoiseIm./max(abs(NoiseIm(:))))+ContrastInc; %convert to -1 to 1 and add contrast increment/decrement to shift mean balance
            NoiseIm     = round((NoiseIm./2)+0.5);
        end
        %combine the letter image and the noise image
        LetterTemp       = LetterIm(:,:,ll).*NoiseIm;
        FragLetterPixNum = sum(All(LetterTemp==1)); %work out total number of pixels within the fragmented letter
        ActualIntactProp   = FragLetterPixNum./LetterPixNum(ll); %IntactProp = fragletter pixels / original letter pixels
        %work out divergence from desired value
        if abs(IntactProp-ActualIntactProp)<Tol %if actual value is close enough to desired value
            KeepGoing = 0; %then stop
        else %keep going but alter ContrastInc
            if (ActualIntactProp-IntactProp)>0 %then need more fragmentation (IntactProp needs to be lower)
                ContrastInc = ContrastInc - ContrastIncStep; %take a small step downwards (prev 0.01)
            else
                ContrastInc = ContrastInc + ContrastIncStep; %take a small step upwards (prev 0.01)
            end
        end
        cnt=cnt+1; %keep track of how long it takes
        if cnt>10000 %code taking too long
            Tol = Tol*1.5; %increase tolerance to avoid code freezing up
        end
    end
    %store the final image
    FragLetIm(:,:,ll) = LetterTemp;
    FinalIntactProp(ll) = ActualIntactProp;
end

FragLetIm = 1-FragLetIm; %convert to black letters on white BG

%add image border if needed
if ImBorder>0 %if border is added
    for ll=1:NumLetters
        FinalIm(:,:,ll) = PadIm(FragLetIm(:,:,ll),[ImWidth+ImBorder ImHeight+ImBorder],1);
    end
else %no border
    FinalIm = FragLetIm; %just pass the image along - no border
end

%% display letters

figure
for ll=1:NumLetters
    if NumLetters==4
        subplot(2,2,ll) %setup for 4AFC
    elseif NumLetters==10
        subplot(2,5,ll) %setup for 10AFC
    elseif NumLetters==12
        subplot(3,4,ll) %setup for 12AFC
    elseif NumLetters==26
        subplot(4,7,ll) %setup for 26AFC
    else
        subplot(2,round(NumLetters/2),ll) %setup for whateverAFC
    end
    imshow(FinalIm(:,:,ll));
end

%% report values to workspace
disp(' ');
disp(strcat('Desired Proportion Intact:',num2str(IntactProp))); disp(' ');
disp('Actual Proportions Intact:'); disp(' ');
for ll=1:NumLetters
    disp(strcat(TestChars{ll},': ',num2str(FinalIntactProp(ll))));
end

CodeEnd = datestr(now,'dd.mm.yyyy-HH.MM.SS');
CodeMinsTaken = etime(datevec(CodeEnd,'dd.mm.yyyy-HH.MM.SS'),datevec(CodeStart,'dd.mm.yyyy-HH.MM.SS'))/60;
CodeHoursTaken = CodeMinsTaken/60;
fprintf('Done! Code completed in %3.2f mins (%3.2f hours)\n',CodeMinsTaken,CodeHoursTaken);

%% save image (uncomment if desired)
ThisDir = which('MakeFragLetterSloan.m'); %find this file
ThisDir = ThisDir(1:end-length('MakeFragLetterSloan.m')); %get the directory where files are (cutting off filename and matlab folder)
SaveDir = strcat(ThisDir,'Images/'); %where images will be saved
for ll=1:NumLetters
fName = sprintf('%s%s-%2.2fIntact-%s.png',SaveDir,'DemoLetter',IntactProp*100,TestChars{ll});
imwrite(FinalIm(:,:,ll),fName,'png','BitDepth',8); %save the image
end