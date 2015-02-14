%%
% This function takes in an image and detects red traffic lights.
% INPUTS:
%   img: RGB image
% OUTPUTS: 
%   DETS: An Nx3 matrix where N is the number of detections, the first two
%         columns contain the (x,y) locations of the detections, and the
%         third column contains the score of the detections (which should
%         be in the range [0 1], where high scores correspond to detections
%         more likely to succeed).
%%
function DETS = detect_red_trafficlights(img)

% set a limit on the number of detections that can be output for one image
MAX_DETECTIONS = 1000;

%get rid of everything below half
[width,height]=size(img(1,:,1));
img = img(1:height/2,:,:);

% pick the red color channel to work with
R = double(img(:,:,1));
G = double(img(:,:,2));
B = double(img(:,:,3));

% blur the image by convolving it n times in each dimension
kernel = [1 2 1]/4; % smooth kernel
blur_steps = 8;
for i=1:blur_steps
    R = conv2([R(:,1) R R(:,end)],kernel,'valid'); 
    R = conv2([R(1,:); R; R(end,:)],kernel','valid'); 
    G = conv2([R(:,1) G G(:,end)],kernel,'valid'); 
    G = conv2([R(1,:); G; G(end,:)],kernel','valid'); 
    B = conv2([R(:,1) B B(:,end)],kernel,'valid'); 
    B = conv2([R(1,:); B; B(end,:)],kernel','valid'); 
end

% find local maxima
diff_E = R(2:end-1,2:end-1) > R(3:end,2:end-1);
diff_W = R(2:end-1,2:end-1) > R(1:end-2,2:end-1);
diff_N = R(2:end-1,2:end-1) > R(2:end-1,3:end);
diff_S = R(2:end-1,2:end-1) > R(2:end-1,1:end-2);
diff_NE = R(2:end-1,2:end-1) > R(3:end,3:end);
diff_NW = R(2:end-1,2:end-1) > R(3:end,1:end-2);
diff_SE = R(2:end-1,2:end-1) > R(1:end-2,3:end);
diff_SW = R(2:end-1,2:end-1) > R(1:end-2,1:end-2);
diffr = diff_E & diff_W & diff_N & diff_S & ...
             diff_NE & diff_NW & diff_SE & diff_SW;
         
% set candidates to be pixels that are in a local maxima         
candidates = zeros(size(R));
candidates(2:end-1,2:end-1) = diffr;
candidates = candidates==1;       

% set score to be the "redness" of the pixel at the local maxima
scoresR = R(candidates);
scoresB = B(candidates);
scoresG = G(candidates);

% we want high red values and low green values
scores = (scoresR-scoresG)/255;

% output pixel locations and scores
[Y,X] = find(candidates);
DETS = [X Y scores];

% output only the top two candidates
max_lights=10;
if size(DETS,1) > max_lights
    [~,sort_inds] = sort(scores,'descend');
    scores = scores(sort_inds(1:max_lights));
    first=DETS(sort_inds(1),:);
    second=DETS(sort_inds(1),:);
    for i=1:10
        second=DETS(sort_inds(i),:);
        dx=second(2)-first(2);
        dy=second(1)-first(1);
        if sqrt(dx*dx+dy*dy)>100
            break;
        end
    end
    %first(3)=max(first(3),.96);
    %second(3)=max(second(3),.96);
    DETS=[first;second];
end




end