function [NoiseIm] = MakeCheckNoiseFun(ImWidth,ConInc,CheckSize);
% [NoiseIm] = MakeCheckNoiseFun(ImWidth,ConInc,CheckSize);
% function to draw a patch of random noise 'checks' with a given balance between black and white in the image 
% needs inputs of ImWidth (image width in pixels), ConInc (the contrast increment applied to the image before rounding, which drives the completeness level, usually ~ ±1.5),
% and CheckSize (size of the 'checks' for the noise in pixels)
%
% code by J Greenwood
% v1, June 2023
%
% e.g. [NoiseIm] = MakeCheckNoiseFun(275,-0.3,11);imshow(NoiseIm);

%generate noise
NoiseImSize  = round(ImWidth./CheckSize); %initial size to generate noise image before downsampling to match image size
NoiseIm     = randn(NoiseImSize,NoiseImSize); %generate random noise image centred on 0

%adjust the noise image and look at error in proportion 'complete' (white)
NoiseIm     = imresize(NoiseIm,[ImWidth ImWidth],'nearest'); %resize noise image to have same size as letter
NoiseIm     = (NoiseIm./max(abs(NoiseIm(:))))+ConInc; %convert to -1 to 1 and add contrast increment/decrement to shift mean balance
NoiseIm     = round((NoiseIm./2)+0.5);