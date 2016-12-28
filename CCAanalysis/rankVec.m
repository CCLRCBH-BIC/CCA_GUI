function R = rankVec(X,mode)
%% R = rankVec(X,mode)
% the purpose of this function is to get the rank-based correlation
% example:
% temp =  1 8
%         3 7
%         2 6
% R = rankVec(temp)
% R =      1     3
%          3     2
%          2     1
if nargin == 1
    mode = 'ascend';
end
[~, ind] = sort(X,mode);
R = zeros(size(X));

for i=1:size(X,2)
    R(ind(:,i),i) = 1:size(X,1);
end

end