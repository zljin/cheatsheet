https://kubernetes.io/docs/reference/kubectl/quick-reference/

https://kubernetes.io/docs/reference/kubectl/cheatsheet/#kubectl-output-verbosity-and-debugging

```sh
# 应用部署,-v=8 debug模式
kubectl get pods -A -o wide

kubectl apply/delete -f deployment.yaml
kubectl create deployment tomcat6 --image=tomcat:6.0.53-jre8 --dry-run -o yaml > tomcat6-deploy.yaml


kubectl exec -it pod-name -c contain-name -- /bin/bash

kubectl logs nginx-ingress-controller-4f2h4 -n ingress-nginx -f
kubectl describe pod <pod-name>


kubectl rollout restart deployment/java-app (无需停机,滚动更新)
kubectl rollout undo deployment/java-app (回滚)
```