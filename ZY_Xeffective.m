function [X_eff,X_ortho] = ZY_Xeffective(X,C,flag)
    [~,X_eff,X_ortho] = ZY_Xeffective_internal(X,C);
    corr_temp = triu(abs(corr(X_ortho)),1);
    ind = find(corr_temp(:)>0.95);ind_remove = [];
    for i = 1:numel(ind)
        [ix,iy] = ind2sub([size(X_ortho,2),size(X_ortho,2)],ind(i));
        ind_remove = [ind_remove,iy];
    end
    X_ortho(:,ind_remove) = [];
end
function [X_new,X_eff,X_ortho]=ZY_Xeffective_internal(X,C)
% decompose X into Xeff to a specific C and X_rest that each colume in X_rest 
% is orthogonal to Xeff;
[NX1,NX2] = size(X);
XtX = X'*X;
Xeff = X*pinv(XtX)*C'*(pinv(C*pinv(XtX)*C'));
X_new = zeros(NX1,NX2);
for i = 2:NX2+1
    X_tmp = X(:,i-1);
    proj = (X_tmp'*Xeff/norm(Xeff))*(Xeff/norm(Xeff));
    X_new(:,i) = X_tmp - proj;
end
X_new(:,1) = Xeff;
% mean and std normalization;
X_new = zscore(X_new);
X_eff = X_new(:,1);
X_ortho = X_new(:,2:end);
end

function [Xeff] = reparameterization(X,C)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get Xeff from design matrix X with contrast C;
% from Xeff_Smith_Stephen et al: Meaningful design and contrast
% estimability in FMRI;

% X should not be variance normalized~~!!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XtX = X'*X;
Xeff = X*pinv(XtX)*C'*(pinv(C*pinv(XtX)*C'));
end