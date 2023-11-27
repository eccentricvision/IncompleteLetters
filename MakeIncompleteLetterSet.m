%MakeIncompleteLetterSet
%
%formerly MakeFragLetterSloan.m
%code to generate incomplete letters, similar to the VOSP 'incomplete letters test'
%here using Sloan letters, loaded from image files
%specify image size, PropComp (proportion letter intact = 1/fragmentation) and checksize under image parameters below
%
%code by Keir Yong & J Greenwood
%new in v3 - letters now generated via function MakeIncompleteLetterFun that uses fminsearch
%v3, June 2023

clear all;
%close all;
CodeStart = datestr(now,'dd.mm.yyyy-HH.MM.SS');

%% setup stimulus parameters as structure = sp

%sp.WhichLetter = {'H','O','T','V'}; %4AFC
%sp.WhichLetter = {'H','O','T','V','U','X'}; %6AFC
%sp.WhichLetter = {'C','D','H','K','N','O','R','S','V','Z'};%10AFC
WhichLetter = {'E'};%{'C','D','E','F','H','K','N','P','R','U','V','Z'}; %12AFC - matched to visual acuity testing in UK Biobank
%sp.WhichLetter = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}; %26AFC
 
ImWidth    = 275;%30;%500; %pixels
ImBorder   = 0;%round(sp.ImWidth/3); %add white pixels to border for display image?
PropComp   = 0.15;%0.20;%proportion complete/intact - where 0=fully incomplete/absent and 1 is fully complete/intact
CheckSize  = 11;%11;%2;%20; %each 'check' in the noise image (that becomes the 'fragments') is X pixels wide - with 500 pixel width, stroke width = 100pix so 20pix checks gives 5/stroke

NumLetters    = numel(WhichLetter);

%% load the relevant letter and re-size the image as needed

for ll=1:NumLetters
    [FinalIm(:,:,ll),ConInc,FinalPropComp(ll),err1,datestamp] = IncompleteLetterFineFitFun(ImWidth,ImBorder,PropComp,CheckSize,WhichLetter{ll}); %call to the function - input stimulus parameters and letter as a character e.g. 'S'
    fprintf('Done! Analysis completed in %3.2f mins (%3.2f hours)\n',datestamp.MinsTaken,datestamp.HoursTaken);
end


%% make a noise background and get it to the desired proportion intact

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
disp(strcat('Desired Proportion Intact:',num2str(PropComp))); disp(' ');
disp('Actual Proportions Intact:'); disp(' ');
for ll=1:NumLetters
    disp(strcat(WhichLetter{ll},': ',num2str(FinalPropComp(ll))));
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
fName = sprintf('%s%s-%2.2fIntact-%s.png',SaveDir,'DemoLetter',PropComp*100,sp.WhichLetter{ll});
imwrite(FinalIm(:,:,ll),fName,'png','BitDepth',8); %save the image
end