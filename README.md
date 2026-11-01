# sentiment-app – Sentiment Analysis DevOps Pipeline

Continuous packaging and deployment of NLP sentiment workers onto Kubernetes, with declarative health validation and infrastructure orchestration.

```
sentiment-app/
├── sentiment.properties   # Task 1  (BATCH=500)
├── Jenkinsfile            # Task 3
├── Dockerfile             # Task 4
├── k8s/
│   ├── deployment.yaml    # Task 5  (2 replicas, tier: analytics, readiness/liveness probes)
│   ├── service.yaml       # Task 5  (NodePort 30096)
│   └── kind-config.yaml   # Task 5  (maps NodePort 30096 to localhost)
├── terraform/main.tf      # Task 6  (creates sentiment.env)
└── ansible/inventory.ini  # Task 6
```

## 1. Git [2 marks]
```bash
git init sentiment-app && cd sentiment-app && git checkout -b main
# initial commit on main ...
git checkout -b release-v4.0
echo "BATCH=500" > sentiment.properties
git add sentiment.properties && git commit -m "Add sentiment.properties with BATCH=500"
git checkout main
git merge --no-ff release-v4.0 -m "Merge release-v4.0 into main"
git tag -a v4.0.0-final -m "Sentiment app v4.0.0 final release"
```
Verify:
```bash
git log --oneline --graph --all --decorate
git branch && git tag && cat sentiment.properties
```

## 2. Jira [1 mark]
Done in Jira: SOC-101 and SOC-102 moved to **Done**, sprint **Sprint-Sentiment-v4** completed, burndown chart reviewed.

## 3. Jenkins [2 marks]
New Item → **Pipeline** → paste `Jenkinsfile` → **Build Now**.
Stages: `Checkout Code` → `Sentiment Test Suite` → `Package Container`.
Verify: Stage View at http://localhost:8090/job/sentiment-pipeline/ (all green, `Finished: SUCCESS`).

## 4. Docker [2 marks]
```bash
docker build -t sentiment-worker:latest .
docker run -d --name sentiment-worker -p 8086:80 sentiment-worker:latest
docker ps --filter name=sentiment-worker     # STATUS Up, 0.0.0.0:8086->80/tcp
docker logs sentiment-worker                  # Sentiment Engine Ingesting
curl http://localhost:8086                    # Sentiment Engine Ingesting
```

## 5. Kubernetes [2 marks]
```bash
kind create cluster --name sentiment --config k8s/kind-config.yaml
kubectl apply -f k8s/deployment.yaml -f k8s/service.yaml
kubectl get pods -l tier=analytics -o wide    # 2 pods, 1/1 Running
kubectl get svc sentiment-service             # 80:30096/TCP
curl http://localhost:30096                   # nginx welcome page
```

## 6. IaC – Terraform + Ansible [1 mark]
```bash
cd terraform && terraform init && terraform apply -auto-approve && cd ..
ansible localhost -i ansible/inventory.ini -m stat  -a "path=$PWD/terraform/sentiment.env" -e ansible_python_interpreter=auto_silent
ansible localhost -i ansible/inventory.ini -m shell -a "cat $PWD/terraform/sentiment.env" -e ansible_python_interpreter=auto_silent
```
Expected: `"exists": true`, and the contents include `BATCH=500`.

## Restart after a reboot
```bash
docker start sentiment-worker sentiment-jenkins sentiment-control-plane
```
