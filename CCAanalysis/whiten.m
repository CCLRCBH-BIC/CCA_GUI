%% Whiten(X) is used to get centered random variables with unit variance
% without considering autocorrelation
% It should be the last step for preprocessing
% variables:
%   X is a specific n-dimension gaussian variable with t observations.
%   which means X is t X n matrix
function X_white=whiten(X)
% the first dimension should be number of observations
    siz = size(X);
    if numel(siz)>2
        X = reshape(X,siz(1),[]);
    end
    X_ave=mean(X,1);
    X_std=std(X);

    %bsxfun is used to have an operation which operates diff. column by diff. number
    X_white = X - repmat(X_ave,size(X,1),1);
    X_white = X_white./repmat(X_std,size(X,1),1);
    X_white(isnan(X_white)) = 0;
    X_white = reshape(X_white,siz);
end
