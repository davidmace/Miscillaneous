
function new_bboxes = consolidate_bboxes(bboxes)
%% Consolidate multiple bounding boxes to one and assigns it a likelihood 
% INPUT 
%  anno:     n x 7 matrix where each row contains information on a 
%            bounding box: [image_id worker_id x y width height confidence] 
% OUTPUT 
%  new_anno: m x 7 matrix where each row contains information on the 
%            consolidated bounding box: [image_id -1 x y width height likelihood] 


% Do k-means clustering on the starting points and ending
% points of the bounding box separately, with the number of seeds being the
% mean (seems to work better than median) number of bounding boxes chosen by annotators.

% initialize output
new_bboxes=[];
count = 0;

% find unique image ids
im_ids = unique(bboxes(:,1));
for i=1:numel(im_ids)
    im_id = im_ids(i);
    %if im_id ~= 2
    %    continue;
    %end
    
    % store all annotations for this image
    inds = bboxes(:,1)==im_id;
    tmp_anno = bboxes(inds,:);
    
    disp(tmp_anno);
    
    % find mean number of bounding boxes chosen
    numBoxes=size(tmp_anno,1);
    worker_ids = unique(tmp_anno(:,2));
    numPeople=size(worker_ids);
    meanBoxes= int64(numBoxes/numPeople(1));
    
    % determine clusters with kmeans
    startxs=tmp_anno(:,3);
    startys=tmp_anno(:,4);
    endxs=tmp_anno(:,3)+tmp_anno(:,5);
    endys=tmp_anno(:,4)+tmp_anno(:,6);
    startpts=[startxs,startys];
    endpts=[endxs,endys];
    [idx1,scenters,blank,d1]=kmeans(startpts,meanBoxes);
    [idx2,ecenters,blank,d2]=kmeans(endpts,meanBoxes);
    
    %likelihood is indirectly proportional to the distance between actual
    %bounding boxes and the chosen clusters. Ideally this would be
    %normalized so right now it just prints very low probabilities and is 
    %dependent on image size, but the relative probabilites should still 
    %be a valid metric
    
    likelihood=[];
    alpha=10000;
    sz=size(d1)
    for j=1:sz(2)    
        likelihood=[likelihood, alpha/(mean2(d1(:,j))+mean2(d2(:,j)))];
    end
    
    %group each starting point to the closest ending point 
    %(it would be better to do maximal matching across a bipartite graph 
    %between start and end points where the edge weighting is the number of 
    %times that point pair was chosen by an annotator)
    match=zeros(meanBoxes);
    for s=1:meanBoxes
        largest=0;
        for e=1:meanBoxes
            dx=(startpts(s,1)-endpts(e,1));
            dy=(startpts(s,2)-endpts(e,2));
            if dx*dx+dy*dy>largest
                largest=dx*dx+dy*dy;
                match(s)=e;
            end
        end
    end
    
    %append everything together
    for j=1:meanBoxes
        newrow=[im_id,-1,scenters(j,1),scenters(j,2),ecenters(j,1)-scenters(j,1),ecenters(j,2)-scenters(j,2),likelihood(j)];
        new_bboxes=[new_bboxes;newrow];        
    end
    
end


%%%%%%%%%%%%%%%%%%%%%%     

end