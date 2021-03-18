clearvars
close all

nTraj = 2;
nTrajsOnMfd = 1;
indTest = [1];
indTrain = setdiff(1:nTraj, indTest);
SSMDim = 2;
ICRadius = 0.2;
c1 = 1000000;
c2 = 0.4;

nElements = 5;
kappa = 4; % cubic spring
gamma = 0; % cubic damping
[M,C,K,fnl] = build_model(kappa, gamma, nElements);
n = size(M,1); % mechanical dofs
[ICOnMfd, mfd, DS, SSM] = getSSMIC(M, C, K, fnl, nTrajsOnMfd, ICRadius, SSMDim, 1);
ICOffMfd = ICRadius * pickPointsOnHypersphere(nTraj-nTrajsOnMfd, 2*n, 1);
IC = [ICOnMfd, ICOffMfd];
lambda = DS.spectrum.Lambda;

Minv = inv(M);
f = @(q,qdot) [zeros(n-2,1); kappa*q(n-1).^3; 0];

A = [zeros(n), eye(n);
    -Minv*K,     -Minv*C];
G = @(x) [zeros(n,1);
         -Minv*f(x(1:n),x(n+1:2*n))];

F = @(t,x) A*x + G(x);

observable = @(x) x(9,:);
tEnd = 100;
nSamp = 15000;

tic
xSim = integrateTrajectories(F, observable, tEnd, nSamp, nTraj, IC);
toc
% load bernoulli4dfull
%%
overEmbed = 0;
SSMOrder = 3;

% xData = coordinates_embedding(xSim, SSMDim, 'ForceEmbedding', 1);
xData = coordinates_embedding(xSim, SSMDim, 'OverEmbedding', overEmbed);

[V, SSMFunction, mfdInfo] = IMparametrization(xData(indTrain,:), SSMDim, SSMOrder, 'c1', c1, 'c2', c2);
%%
yData = getProjectedTrajs(xData, V);
plotReducedCoords(yData(indTest,:));

RRMS = getRMS(xData(indTest,:), SSMFunction, V)
%%
xLifted = liftReducedTrajs(yData, SSMFunction);
plotReconstructedTrajectory(xData(indTest(1),:), xLifted(indTest(1),:), 1)
%%
plotSSMWithTrajectories(xData(indTest,:), SSMFunction, [1,3,5], V, 50, 'SSMDimension', SSMDim)
% axis equal
view(50, 30)

%% Reduced dynamics
cutoff = 1;
for iTraj = indTrain
    yData{iTraj,1} = yData{iTraj,1}(:,cutoff:end);
    xData{iTraj,1} = xData{iTraj,1}(:,cutoff:end);
    yData{iTraj,2} = yData{iTraj,2}(:,cutoff:end);
    xData{iTraj,2} = xData{iTraj,2}(:,cutoff:end);
end
[R,iT,N,T,Maps_info] = IMdynamics_map(yData(indTrain,:), 'R_PolyOrd', 3, 'style', 'modal', 'c1', c1, 'c2', c2);

[yRec, xRec] = iterateMaps(R, yData, SSMFunction);

[reducedTrajDist, fullTrajDist] = computeRecDynErrors(yRec, xRec, yData, xData);

RMSE = mean(reducedTrajDist(indTest))
RRMSE = mean(fullTrajDist(indTest))

plotReducedCoords(yData(indTest(1),:), yRec(indTest(1),:))
plotReconstructedTrajectory(xData(indTest(1),:), xRec(indTest(1),:), 1, 'g')
plotReconstructedTrajectory(xData(indTrain(1),:), {0,0}, 1, 'g')
hold on
plot(0:tEnd,max(xData{indTrain(1),2}(1,:))*timeWeighting(c1,c2,0:tEnd), 'r', 'DisplayName', 'weighting')

reconstructedEigenvalues = computeEigenvaluesMap(Maps_info, yRec{1,1}(2)-yRec{1,1}(1))
DSEigenvalues = lambda(1:SSMDim)