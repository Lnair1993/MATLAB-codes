%%% HRI 7633 CODE FOR SALIENCY MODEL %%%
%AUTHOR: LAKSHMI NAIR

global Key_Press
Key_Press = 0;
gcf
set(gcf, 'KeyPressFcn', @myKeyPressFcn)
threshold = 0.3; %Color detection threshold
red_count = 0;
blue_count = 0;
green_count = 0;
null_count = 0;
videoObj = videoinput('winvideo',1);
set(videoObj,'ReturnedColorSpace','rgb');
set(videoObj,'FramesPerTrigger',1);
set(videoObj,'TriggerRepeat',Inf);
triggerconfig(videoObj,'Manual');
start(videoObj);
while ~Key_Press
trigger(videoObj);
frames = getdata(videoObj,1,'uint8');
map = signatureSal(frames);
mapbig = mat2gray(imresize(map,[size(frames,1) size(frames,2)])); 
maxValue = max(mapbig(:));
[rowsOfMaxes colsOfMaxes] = find(mapbig == maxValue);
a = randsample(size(rowsOfMaxes),1);
x_coord = rowsOfMaxes(a);
y_coord = colsOfMaxes(a); %Randomly picking one of the white patches
[rr cc] = meshgrid(1:size(frames,1),1:size(frames,2));
C = sqrt((rr-x_coord).^2+(cc-y_coord).^2)<=50;

cir1 = frames(:,:,1);
cir2 = frames(:,:,2);
cir3 = frames(:,:,3);
img1 = cir1(C);
img2 = cir2(C);
img3 = cir3(C);

red = sum(img1(:));
blue = sum(img2(:));
green = sum(img3(:));
total = red + blue + green;
if (red/total) > threshold
    red_count = red_count + 1;
elseif (blue/total) > threshold
    blue_count = blue_count + 1;
elseif (green/total) > threshold
    green_count = green_count + 1;
else    
    null_count = null_count + 1;
end
%imshow(mapbig);
imshow(frames);
hold on;
plot(y_coord, x_coord, 'o', 'MarkerEdgeColor','y', 'MarkerSize', 50);
hold off;
end

delete(videoObj)
clear videoObj

total_count = red_count + blue_count + green_count + null_count;

display('% of time the blue objects were focussed upon: ')
blue_count*100/total_count
display('% of time the red objects were focussed upon: ')
red_count*100/total_count
display('% of time the green objects were focussed upon: ')
green_count*100/total_count
display('% of time focus was elsewhere: ')
null_count*100/total_count

