function [Sxx,Sxy,Syx,Syy]=corrCombo(X,Y,flag)
% [Sxx,Sxy,Syx,Syy]=corrCombo(X,Y,flag)
% flag = MIC, Pearson, dcor, ranked dcor
if exist('flag','var')==0 || isempty(flag)==1
    flag = 'Pearson';
end
%% remove const vector first
ind_x = find(range(X)>0);
ind_y = find(range(Y)>0);
p_x = size(X,2);p_y = size(Y,2);
Sxx = zeros(p_x);
Syy = zeros(p_y);
Sxy = zeros(p_x,p_y);
Syx = zeros(p_y,p_x);
X = X(:,ind_x);
Y = Y(:,ind_y);

%% calculate correlation
if strcmpi(flag,'MIC')==1
    [Sxx(ind_x,ind_x),Sxy(ind_x,ind_y),Syx(ind_y,ind_x),Syy(ind_y,ind_y)]=corrMIC(X,Y);
elseif strcmpi(flag,'noparMIC')==1
    [Sxx(ind_x,ind_x),Sxy(ind_x,ind_y),Syx(ind_y,ind_x),Syy(ind_y,ind_y)]=corrMICnoParfor(X,Y);
elseif strcmpi(flag,'Pearson')==1
    [Sxx(ind_x,ind_x),Sxy(ind_x,ind_y),Syx(ind_y,ind_x),Syy(ind_y,ind_y)]=corrPearson(X,Y);
elseif strcmpi(flag,'dcor')==1||strcmpi(flag,'ranked dcor')==1
    [Sxx(ind_x,ind_x),Sxy(ind_x,ind_y),Syx(ind_y,ind_x),Syy(ind_y,ind_y)]=corrDcor(X,Y,flag);
elseif strcmpi(flag,'nopardcor')==1||strcmpi(flag,'ranked nopardcor')==1
    [Sxx(ind_x,ind_x),Sxy(ind_x,ind_y),Syx(ind_y,ind_x),Syy(ind_y,ind_y)]=corrnoParDcor(X,Y,flag);
else
    err('err in corrCombo: please specify correct flag');
end

end