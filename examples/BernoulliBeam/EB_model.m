function [M,C,K,fnl] = EB_model(kappa, nElements)

[M,C,K]=L_Bernoulli_Beam_Model(nElements);

n = length(M);

nDOF = 2*nElements;
subs3 = [nDOF-1,nDOF-1,nDOF-1,nDOF-1];
vals3 = [kappa];
f3 = sptensor(subs3, vals3, [nDOF,nDOF,nDOF,nDOF]);
f2 = sptensor([n,n,n]);

%% 
% first-order tensors

% f2 = sptensor([n,n,n]);
% f3 = sptensor([n,n,n,n]);
% %% 
% % Adding cubic and damper to the middle and end node of the beam 
% 
% dof = [n/2-1, n-1]; % only even number of dofs allowed
% for j = dof
%     f3(j,j,j,j) = kappa;
% end

fnl = {f2,f3};