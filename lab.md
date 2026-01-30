1. Add a taint to your worker node

kubectl taint nodes kworker special=true:NoSchedule

2. Verify the taint
kubectl describe node kworker1 | grep Taints


# ================================================================================

File:

# pod-no-toleration.yaml

apiVersion: v1
kind: Pod
metadata:
  name: pod-no-toleration
spec:
  containers:
  - name: nginx
    image: nginx


kubectl apply -f pod-no-toleration.yaml
Check status:
kubectl get pods -o wide

# ================================================================================

4. Create a pod with toleration (it should schedule successfully)

File:

pod-with-toleration.yaml

# pod-with-toleration.yaml

apiVersion: v1
kind: Pod
metadata:
  name: pod-with-toleration
spec:
  tolerations:
  - key: "special"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx


kubectl apply -f pod-with-toleration.yaml
Check:
kubectl get pods -o wide

================================================================================

2. Create a Deployment that tolerates the taint

nginx-special.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-special
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-special
  template:
    metadata:
      labels:
        app: nginx-special
    spec:
      tolerations:
      - key: "special"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80


kubectl apply -f nginx-deploy.yaml

3. Verify scheduling
kubectl get pods -o wide


================================================================================

Deployment with NodeAffinity

# nginx-special.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-special
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-special
  template:
    metadata:
      labels:
        app: nginx-special
    spec:
      tolerations:
      - key: "special"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - node01
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80


Apply and verify

kubectl apply -f nginx-deploy.yaml
kubectl get pods -o wide
