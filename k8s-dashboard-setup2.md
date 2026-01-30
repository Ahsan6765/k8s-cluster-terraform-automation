🖥️ Deploy Kubernetes Dashboard on K3s

1. Apply the Dashboard Manifest
Run this on your master node:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

==============================================================
==============================================================

2. Create an Admin User
Create a file admin-user.yaml:

apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard


Apply it:
kubectl apply -f admin-user.yaml

==============================================================
==============================================================

Create a Secret for the ServiceAccount

Make a file admin-user-token.yaml

apiVersion: v1
kind: Secret
metadata:
  name: admin-user-token
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: "admin-user"
type: kubernetes.io/service-account-token


Apply it:
kubectl apply -f admin-user-token.yaml


==============================================================
==============================================================

Get the Token

kubectl -n kubernetes-dashboard describe secret admin-user-token


==============================================================
==============================================================

3. Get the Login Token
Run:
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')


==============================================================
==============================================================

4. Access the Dashboard
Start a proxy:
kubectl proxy
Open in your browser (from the master VM or via SSH tunnel):
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
Login using the token from step 3.


==============================================================
==============================================================





eyJhbGciOiJSUzI1NiIsImtpZCI6ImZ6ZWFpWXlfZ1dBQXZWWlJXdzZxcUY1aWpmVGZTcEl3dFBjcVg5cmExSTAifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI0ZDc1ZTVjYi0yNTZiLTRiODYtYTk1Yi1hM2UwMWM3YjcxNDEiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.xEwPdDDwK7CK0wgtIVCthQ0Bhyx51jz5AAACpulF7KKcPrPPnLe9laahjH-HAli4N_MST3QVYGUiYOTVn_qQTzScXfoNu38UOGZuGe62XJWOjOmb1JdoRPLaE8-KXM34kmhtA8HbfjBrXjrGAchbTb97ZsNJr4CthJmONBWi0zbWizJ_EFLMcMNvbPwtTm5r9hRILlcta45W8tLxCGJqZcJ26WW4L2ObRa8WV3OsPOG-kGdL1i9QY429jaWNhxrEwOF-bKVrm6afl5VvjNjtlrwhxdUX6JF8FXttFt964V0BwknfzHARDKuzXWWDfJ-audboX7Uw2c1Yt_U87r89Vg