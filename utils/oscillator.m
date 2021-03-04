function [F, IC] = oscillator(N, nTraj)
% Example dynamical system
% Oscillator chain
% Returns the anonynous evolution function and initial conditions

mass = 1;
stiffness = 1;
damping = 0.006;
M = mass*eye(N);
K = stiffness*(2*eye(N) - diag(ones(1,N-1),-1) - diag(ones(1,N-1),1));
C = K; C(1,1) = 4; C(end,end) = 3; C = damping*C;

% nonlinearities
F2 = sptensor(zeros(2*N, 2*N, 2*N));
F2(1,N+1,N+1) = 0.33;    % q1dot^2
F3 = sptensor(zeros(2*N, 2*N, 2*N, 2*N));
F3(1,1,1,1) = 2;         % q1^3
F3(1,1,1,N+1) = 0.3;     % q1^2*q1dot^2 
F3(1,N+1,N+1,N+1) = 0.5; % q1dot^3
fnl = {F2, F3};
f = @(q,qdot) [F2(1,N+1,N+1)*qdot(1).^2 + F3(1,1,1,1)*q(1).^3 + F3(1,1,1,N+1)*q(1).^2.*qdot(1) + F3(1,N+1,N+1,N+1)*qdot(1).^3;
               zeros(N-1,1)];
           
A = [zeros(N), eye(N);
    -M\K,     -M\C];
G = @(x) [zeros(N,1);
         -M\f(x(1:N),x(N+1:2*N))];
F = @(t,x) A*x + G(x);

DS = DynamicalSystem();
set(DS, 'M', M, 'C', C, 'K', K, 'fnl', fnl);
set(DS.Options,'Emax',5,'Nmax',10,'notation','multiindex')
S = SSM(DS);
set(S.Options, 'reltol', 0.1,'notation','multiindex')
S.choose_E([1,2]);
mfd = S.compute_whisker(20);

IC = zeros(2*N, nTraj);
for iTraj = 1:nTraj
    z = 0.4*(-1)^(2*iTraj/nTraj);
    IC(:,iTraj) = real(getIC(mfd, [z; conj(z)]));
end