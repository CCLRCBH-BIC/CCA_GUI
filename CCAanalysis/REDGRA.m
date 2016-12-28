function [RedObjGra,ObjGra,C,invD,invDC,designindex,stateindex] ...
    = REDGRA(funlist,Xk,designindex,stateindex)
%% 
% funlist: all functions except the last one are active constraint function
%   the last one is the objection function
% variable X = [Y;Z], [(n-l) + (m+l)] x 1
% dG = C*dY+D*dz, 
% Y: design/independent variables, (n-l) x 1
% Z: state/dependent/basic variables, (m+l) x 1
% m: N.O. of inequality constraint
% l: N.O. of equality constraint
% n: N.O. of natural variables
% m: N.O. of slack variables

G = Grad(funlist,Xk);

% to make sure invD exist
if abs(G(1:end-1,stateindex))<1e-4
    [~,stateindex] = max(abs(G(1:end-1,:)));
    designindex = find(1:numel(Xk)~=stateindex);
end

C = G(1:end-1,designindex); % (m+l) x (n-l)
D = G(1:end-1,stateindex); % (m+l) x (m+l)
invD = inv(D);
invDC = D\C; % (m+l) x (n-l)
ObjGra = (G(end,:))';

RedObjGra = ObjGra(designindex)-invDC'*ObjGra(stateindex); % 1 x (n-l)

end
