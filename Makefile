deploy:
	@echo "Deploying all artifacts..."
	kubectl apply -f namespace
	kubectl apply -f configmap
	kubectl apply -f secrets
	kubectl apply -f persistentvolumeclaims
	kubectl apply -f services
	kubectl apply -f statefulsets
	@echo "Done"

clean:
	kubectl delete namespace besu
