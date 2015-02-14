
function Y_pred = runAdaBoost(X, classifier)
%% INPUT: 
% X: n x 2 matrix where n is the number of training samples
% classifier.alpha : weights of each weak classifier 
% classifier.tau   : threshold of each weak classifier
% classifier.p     : sign of each weak classifier
% classifier.idx   : index of feature that the weak classifier applies
%% OUTPUT:
% Y_pred: n x 1 vector containing predicted labels of X, in {-1, 1}
%%
disp(X);
m=size(X,1);
T=size(classifier,2);
Y_pred=zeros(m,1);
for i=1:m
    tot=0;
    for t=1:T
        h=1;
        if (X(i,classifier(t).axis)<classifier(t).tau && classifier(t).p==1) || (X(i,classifier(t).axis)>classifier(t).tau && classifier(t).p==-1)
            h=-1;
        end
        tot=tot + classifier(t).alpha*h;
    end
    Y_pred(i)=sign(tot);
end

