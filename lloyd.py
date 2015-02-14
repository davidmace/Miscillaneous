""" Experiments with Lloyd's algorithm """

import numpy as np
from sklearn.cluster import KMeans
from sklearn.linear_model import Perceptron
from sklearn import svm

sum=0
for i in range(250) :

	x=np.random.rand(100,2)*2-1
	y=np.sign(x[:,1]-x[:,0]+0.25*np.sin(np.pi*x[:,0]))

	#lloyd
	numclusters=12
	kmeans=KMeans(numclusters)
	kmeans.fit(x,y)
	centers=np.array( kmeans.cluster_centers_ )
	g=1.5
	inputs = np.array( [np.exp( -g*np.sum( (x-centers[i])**2, axis=1) ) for i in range(numclusters) ] )
	perceptron=Perceptron()
	perceptron.fit(inputs.T, y)
	w=np.array(perceptron.coef_); b=perceptron.intercept_
	ypred = np.sign( np.dot(w, inputs)+b )
	err=np.sum(ypred!=y)
	#print err

	# svm
	clf = svm.SVC(C=10000, coef0=1.0, gamma=1.5, kernel='rbf')
	clf.fit(x, y) 
	y_pred = clf.predict(x)
	err=np.sum(y_pred!=y)
	#print err


	#test
	x=np.random.rand(100,2)*2-1
	y=np.sign(x[:,1]-x[:,0]+0.25*np.sin(np.pi*x[:,0]))

	#lloyd
	inputs = np.array( [np.exp( -g*np.sum( (x-centers[i])**2, axis=1) ) for i in range(numclusters) ] )
	ypred = np.sign( np.dot(w, inputs)+b )
	err1=np.sum(ypred!=y)

	#svm
	y_pred = clf.predict(x)
	err2=np.sum(y_pred!=y)
	print err1,err2

	if err1>err2 :
		sum+=1

print sum # instances where lloyd's outperforms svm
