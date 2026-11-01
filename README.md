# Sentiment Analysis – DevOps Pipeline (10 Marks)

Context: continuous packaging and deployment of NLP sentiment workers onto Kubernetes with declarative health validation and IaC orchestration.

```
sentiment-app/
├── Jenkinsfile              # Task 3
├── Dockerfile               # Task 4
├── k8s/deployment.yaml      # Task 5 (2 replicas, tier: analytics, readiness/liveness probes)
├── k8s/service.yaml         # Task 5 (NodePort 30096)
├── terraform/main.tf        # Task 6 (creates sentiment.env)
├── ansible/inventory.ini    # Task 6 (localhost for ad-hoc check)
└── scripts/task1_git.sh     # Task 1
```

---

## macOS setup (one time)

```bash
# Homebrew (skip if installed): https://brew.sh
brew install git ansible jenkins-lts
brew tap hashicorp/tap && brew install hashicorp/tap/terraform
brew install --cask docker          # Docker Desktop
```

- Open **Docker Desktop** → Settings → **Kubernetes** → tick *Enable Kubernetes* → Apply & Restart. This gives you `kubectl` with no Minikube needed.
- Start Jenkins: `brew services start jenkins-lts`, open http://localhost:8080. Get the unlock password with
  `cat ~/.jenkins/secrets/initialAdminPassword`, then install suggested plugins.

---

## Task 1 – Git [2 Marks]

Run `bash scripts/task1_git.sh` from an empty folder, **or** type the commands:

```bash
git init sentiment-app && cd sentiment-app
git checkout -b main
echo "# sentiment-app" > README.md
git add README.md && git commit -m "Initial commit on main"

git checkout -b release-v4.0
echo "BATCH=500" > sentiment.properties
git add sentiment.properties
git commit -m "Add sentiment.properties with BATCH=500"

git checkout main
git merge --no-ff release-v4.0 -m "Merge release-v4.0 into main"
git tag -a v4.0.0-final -m "Sentiment app v4.0.0 final release"

git log --oneline --graph --all --decorate
git tag
cat sentiment.properties
```

📸 Screenshot: the `git log --graph` output showing the merge commit with `tag: v4.0.0-final`, plus `cat sentiment.properties` → `BATCH=500`.

---

## Task 2 – Jira [1 Mark]

1. Create a Scrum project (e.g. key **SOC**) → create issues so you have **SOC-101** and **SOC-102**
   *(if your project starts at SOC-1, create/rename until keys match, or note the mapping).*
2. Backlog → **Create sprint** → rename to **Sprint-Sentiment-v4** → drag both issues in → **Start sprint**.
3. Active sprint board → drag SOC-101 and SOC-102 to **Done**.
4. **Complete sprint** (top-right of board).
5. Reports → **Burndown Chart** → select Sprint-Sentiment-v4.

📸 Screenshots: board with both tickets in Done, the "Sprint completed" dialog, and the burndown chart.

---

## Task 3 – Jenkins Declarative Pipeline [2 Marks]

1. Jenkins → **New Item** → name `sentiment-pipeline` → **Pipeline** → OK.
2. Pipeline → Definition: **Pipeline script** → paste the `Jenkinsfile` → Save.
3. **Build Now**.

Stages: `Checkout Code` → `Sentiment Test Suite` → `Package Container`.

📸 Screenshots: Stage View (all three green) and Console Output ending in `Finished: SUCCESS`.

---

## Task 4 – Docker [2 Marks]

Run from the folder containing the `Dockerfile`:

```bash
docker build -t sentiment-worker:latest .
docker run -d --name sentiment-worker -p 8086:80 sentiment-worker:latest
docker ps
docker logs sentiment-worker        # prints: Sentiment Engine Ingesting
curl http://localhost:8086          # (or open in browser) → Sentiment Engine Ingesting
```

📸 Screenshots: build success, `docker ps` showing `0.0.0.0:8086->80/tcp` with status **Up**, and `docker logs` output.

---

## Task 5 – Kubernetes [2 Marks]

Works on Minikube or Docker Desktop Kubernetes.

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

kubectl get deployments
kubectl get pods -l tier=analytics -o wide     # 2 pods, STATUS Running, READY 1/1
kubectl get svc sentiment-service              # 80:30096/TCP
```

Access (Docker Desktop Kubernetes on Mac): http://localhost:30096

📸 Screenshots: `get pods` (2/2 Running), `get svc` showing NodePort 30096, nginx page in browser.

---

## Task 6 – IaC: Terraform + Ansible [1 Mark]

```bash
cd terraform
terraform init
terraform apply -auto-approve      # creates terraform/sentiment.env

# Verify with Ansible ad-hoc modules (run from terraform/ folder)
ansible localhost -i ../ansible/inventory.ini -m stat  -a "path=./sentiment.env"
ansible localhost -i ../ansible/inventory.ini -m shell -a "cat ./sentiment.env"
```

Expected: `stat` returns `"exists": true`; `shell` prints `BATCH=500`, `VERSION=v4.0.0-final`, etc.

> macOS: Ansible runs natively (`brew install ansible`). If it warns about the Python interpreter, add `-e ansible_python_interpreter=$(which python3)`.

📸 Screenshots: `terraform apply` → `Apply complete! Resources: 1 added`, and both Ansible outputs (green `SUCCESS`).

---

## Cleanup (optional)

```bash
docker rm -f sentiment-worker
kubectl delete -f k8s/
cd terraform && terraform destroy -auto-approve
```
