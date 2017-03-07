% The response of V1 and MT neurons for a sequence of images presented in succession
%AUTHOR: LAKSHMI NAIR

%Step 1: Compute x, y image derivatives for each frame: Ix, Iy
%Step 2: Compute temporal image (frame at time t+1 - frame at time t): It
%Step 3: Compute matrix A = [Ix^2 Ix*Iy; Ix*Iy Iy^2]
%Step 4: Compute matrix B = [Ix*It Iy*It]
%Step 5: Solve Ax = B to find x, the matrix of velocities, indicating areas
%of movement in input images

%INPUT: Read successive image frames
%OUTPUT: Image indicating areas of motion 

%Specify folder path here
folder_loc = '';    %<------- Specify the path to the image frames

%Read the .jpg files in the directory
files = dir(fullfile(folder_loc,'*.tif'));
num_images = length(files);

%Read and obtain size of first image
img = imread(files(1).name);
[rows,cols,channels] = size(img);

%Convert RGB images to gray and save first image to image at t = 0
if channels == 3
    img = rgb2gray(img);
end

It0 = img;
It0 = imgaussfilt(It0,2);
%Initialize output arrays
It_array = zeros(rows,cols,num_images-1);
Ix_array = zeros(rows,cols,num_images-1);
Iy_array = zeros(rows,cols,num_images-1);

%Read the second image onwards
for i = 2:num_images
    img = imread(files(i).name);
    if size(img,3) == 3
        img = rgb2gray(img);
    end
    
    %Filter with gaussian
    img = imgaussfilt(img,2); 
    
    %Obtain temporal image
    It1 = img;
    imshow(It1)
    It = It1 - It0;  %Temporal image
    It0 = It1;
    It_array(:,:,i-1) = double(It); %Save temporal image onto array
    
    %Gabor filter in X direction
    orientation = 0;
    wavelength = 4;
    [Ix,] = imgaborfilt(img,wavelength,orientation); %X derivative of img
    %Gabor filter in Y direction
    orientation = 90;
    [Iy,] = imgaborfilt(img,wavelength,orientation); %Y derivative of img
    
    %Saving the sequences onto an array
    Ix_array(:,:,i-1) = Ix;
    Iy_array(:,:,i-1) = Iy;

end

%%
patch_size = 10; %Size of image patches to be extracted for global integration in MT
vel_x = zeros(rows,cols,num_images-1); %Initialize final velocity matrices
vel_y = zeros(rows,cols,num_images-1);

%Computing requisites for optic flow computation
Ix2 = Ix_array.*Ix_array;     %Squaring the derivative images
IxIy = Ix_array.*Iy_array;    %Multiply x and y derivatives
Iy2 = Iy_array.*Iy_array;
IxIt = Ix_array.*It_array;    %Multiply x derivative and temporal image
IyIt = Iy_array.*It_array;

for i = 1:num_images-1
    for j = 1:patch_size:rows-patch_size
        for k = 1:patch_size:cols-patch_size
            %Extract patches from the computed requisites of patch_size
            im_x2 = Ix2(j:j+patch_size,k:k+patch_size,i);
            im_y2 = Iy2(j:j+patch_size,k:k+patch_size,i);
            im_tx = IxIt(j:j+patch_size,k:k+patch_size,i);
            im_xy = IxIy(j:j+patch_size,k:k+patch_size,i);
            im_ty = IyIt(j:j+patch_size,k:k+patch_size,i);
            
            %Sum up and concatenate each of the above values to a 2x2 matrix A and 2x1 matrix B
            A = [sum(sum(im_x2)) sum(sum(im_xy));sum(sum(im_xy)) sum(sum(im_y2))];
            B = [sum(sum(im_tx));sum(sum(im_ty))];
          
            %Solve AX = B where X is a vector of x and y velocity 
            X = pinv(A)*B;

            %Concatenate and save velocity values to result matrix
            vel_x(j:j+patch_size,k:k+patch_size,i) = X(1);
            vel_y(j:j+patch_size,k:k+patch_size,i) = X(2);
            
        end
    end
end

%Threshold very low velocity values to remove some noisy detections
for i = 1:num_images-1
     velx = vel_x(:,:,i);
     vely = vel_y(:,:,i);
     max_vel_x = max(max(velx));
     max_vel_y = max(max(vely));
     velx(velx < 0.15*max_vel_x) = 0;
     vely(vely < 0.15*max_vel_x) = 0;
     figure,quiver(velx,vely); %Display the quiver plots
end
