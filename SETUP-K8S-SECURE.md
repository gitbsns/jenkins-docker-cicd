# Jenkins → Kubernetes: Secure Setup Guide

Ye guide un 3 cheezon ko cover karta hai jo Jenkinsfile chalne se pehle
ek baar manually setup karni hain.

## 1. Rotate the leaked secret

Agar `secret.yaml` kabhi git mein commit hui thi (chahe private repo mein),
uski value ab compromised maani jaati hai — history se delete karna kaafi
nahi, naya value banao:

```bash
openssl rand -hex 32
# output ko Jenkins credential "session-secret" mein daalo (step 3 dekho)
```

## 2. Jenkins ke liye limited Kubernetes access (RBAC)

Poora `cluster-admin` kubeconfig Jenkins ko mat do. Ye manifest ek
ServiceAccount banata hai jo sirf `default` namespace ke andar
Deployments/Services/Secrets/ConfigMaps manage kar sakta hai:

```yaml
# jenkins-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-deployer
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deploy-role
  namespace: default
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "update", "patch"]
  - apiGroups: [""]
    resources: ["services", "configmaps", "secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deploy-binding
  namespace: default
subjects:
  - kind: ServiceAccount
    name: jenkins-deployer
    namespace: default
roleRef:
  kind: Role
  name: jenkins-deploy-role
  apiGroup: rbac.authorization.k8s.io
```

Apply karo:
```bash
kubectl apply -f jenkins-rbac.yaml
```

Ab is ServiceAccount ka token nikaal kar ek kubeconfig file banao
(Kubernetes version ke hisaab se command thoda alag ho sakta hai —
agar minikube/kind use kar rahe ho to poocho, main exact command de dunga).

## 3. Jenkins Credentials add karo

**Manage Jenkins → Credentials → System → Global credentials → Add Credentials**

| ID                | Type              | Value                                    |
|-------------------|-------------------|-------------------------------------------|
| `dockerhub-creds` | Username/Password | Docker Hub login (already ho ga)          |
| `kubeconfig-cred` | Secret file        | Step 2 wala limited kubeconfig file       |
| `session-secret`  | Secret text        | Step 1 wala naya rotated value            |

Iske baad naye `Jenkinsfile` ko commit kar ke build chalao — pipeline ab
khud secret banayega, ConfigMap apply karega, aur naye image ko
Kubernetes pe rolling update karega.

## 4. Verify

```bash
kubectl get pods -n default -w        # naye pods "Running" hote dekho
kubectl rollout history deployment/myapp-deployment -n default
kubectl logs -l app=myapp -n default  # agar kuch fail ho to yahan dikhega
```
