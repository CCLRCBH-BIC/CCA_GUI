function A_X = distanceMatrix1D(X)
%% distanceMatrix() is used to calculated distance matrix in 1D
% X is a column vector
% A_X is a N X N matrix
N = size(X,1);
X = repmat(X,1,N);

A_X = abs(X - X');
X_row = mean(A_X,2);
X_col = mean(A_X,1);

A_X = A_X - diag(X_row)*ones(N) - ones(N)*diag(X_col)+mean(X_row);
A_X = A_X(:);
end