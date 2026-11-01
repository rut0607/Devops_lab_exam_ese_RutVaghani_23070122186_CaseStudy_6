#!/usr/bin/env bash
# One-shot runner for Tasks 1, 3, 4, 5, 6 on macOS.
# Usage (from this folder):   bash run_all.sh
# Everything is also saved to logs/run_all.log
cd "$(dirname "$0")"
ROOT="$(pwd)"
mkdir -p logs
exec > >(tee -a logs/run_all.log) 2>&1

banner() { printf '\n\033[1;36m==================== %s ====================\033[0m\n' "$1"; }
ok()     { printf '\033[1;32m✔ %s\033[0m\n' "$1"; }
fail()   { printf '\033[1;31m✘ %s\033[0m\n' "$1"; }

# ---------------------------------------------------------------- prerequisites
banner "Prerequisites"
if ! command -v brew >/dev/null; then
  fail "Homebrew not found. Install it from https://brew.sh, then re-run: bash run_all.sh"; exit 1
fi
for t in git terraform ansible kubectl kind; do
  if ! command -v $t >/dev/null; then
    echo "Installing $t ..."
    case $t in
      terraform) brew tap hashicorp/tap >/dev/null && brew install hashicorp/tap/terraform ;;
      kubectl)   brew install kubernetes-cli ;;
      *)         brew install $t ;;
    esac
  fi
done
if ! command -v docker >/dev/null; then
  echo "Installing Docker Desktop ..."; brew install --cask docker
fi
if ! docker info >/dev/null 2>&1; then
  echo "Starting Docker Desktop (first start can take a minute; accept any prompt it shows) ..."
  open -a Docker
  for i in $(seq 1 90); do docker info >/dev/null 2>&1 && break; sleep 2; done
fi
docker info >/dev/null 2>&1 && ok "Docker is running" || { fail "Docker did not start. Open Docker Desktop, then re-run."; exit 1; }

# ---------------------------------------------------------------- Task 1: Git
banner "TASK 1 - GIT"
git config user.name  >/dev/null 2>&1 || git config --global user.name  "$(whoami)"
git config user.email >/dev/null 2>&1 || git config --global user.email "$(whoami)@localhost"
if [ ! -d .git ]; then
  git init
  git checkout -b main
  printf 'logs/\n.terraform/\n*.tfstate*\n.terraform.lock.hcl\nterraform/sentiment.env\njenkins/Jenkinsfile\n' > .gitignore
  git add .
  git commit -m "Initial commit: sentiment-app pipeline files"
  git checkout -b release-v4.0
  echo "BATCH=500" > sentiment.properties
  git add sentiment.properties
  git commit -m "Add sentiment.properties with BATCH=500"
  git checkout main
  git merge --no-ff release-v4.0 -m "Merge release-v4.0 into main"
  git tag -a v4.0.0-final -m "Sentiment app v4.0.0 final release"
else
  echo "Repository already initialised - showing state."
fi
git log --oneline --graph --all --decorate
echo "--- branches ---"; git branch
echo "--- tags ---";     git tag
echo "--- sentiment.properties ---"; cat sentiment.properties
ok "Task 1 done"

# ---------------------------------------------------------------- Task 4: Docker
banner "TASK 4 - DOCKER"
docker build -t sentiment-worker:latest . || fail "docker build failed"
docker rm -f sentiment-worker >/dev/null 2>&1
docker run -d --name sentiment-worker -p 8086:80 sentiment-worker:latest
sleep 3
docker ps --filter name=sentiment-worker
echo "--- docker logs ---";   docker logs sentiment-worker
echo "--- curl localhost:8086 ---"; curl -s http://localhost:8086
ok "Task 4 done"

# ---------------------------------------------------------------- Task 3: Jenkins
banner "TASK 3 - JENKINS"
cp Jenkinsfile jenkins/Jenkinsfile
docker build -t sentiment-jenkins:lts jenkins/ || fail "Jenkins image build failed"
docker rm -f sentiment-jenkins >/dev/null 2>&1
docker run -d --name sentiment-jenkins -p 127.0.0.1:8090:8080 sentiment-jenkins:lts
echo "Waiting for Jenkins and the first pipeline build (1-3 minutes) ..."
RESULT=""
for i in $(seq 1 90); do
  RESULT=$(curl -s http://localhost:8090/job/sentiment-pipeline/1/api/json 2>/dev/null \
           | python3 -c 'import sys,json; print(json.load(sys.stdin).get("result") or "")' 2>/dev/null)
  [ -n "$RESULT" ] && break; sleep 4
done
echo "--- Console output of sentiment-pipeline #1 ---"
curl -s http://localhost:8090/job/sentiment-pipeline/1/consoleText
[ "$RESULT" = "SUCCESS" ] && ok "Task 3 done - open http://localhost:8090/job/sentiment-pipeline/ for Stage View" \
                          || fail "Jenkins build result: ${RESULT:-not finished}. Check http://localhost:8090"

# ---------------------------------------------------------------- Task 5: Kubernetes
banner "TASK 5 - KUBERNETES"
if ! kind get clusters 2>/dev/null | grep -qx sentiment; then
  kind create cluster --name sentiment --config k8s/kind-config.yaml
fi
kubectl config use-context kind-sentiment
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/sentiment-deployment --timeout=180s
kubectl get deployments
kubectl get pods -l tier=analytics -o wide
kubectl get svc sentiment-service
echo "--- curl localhost:30096 ---"; sleep 2; curl -s http://localhost:30096 | grep -i "<title>"
ok "Task 5 done"

# ---------------------------------------------------------------- Task 6: Terraform + Ansible
banner "TASK 6 - TERRAFORM + ANSIBLE"
cd "$ROOT/terraform"
terraform init -input=false
terraform apply -auto-approve -input=false
echo "--- Ansible: stat module ---"
ansible localhost -i ../ansible/inventory.ini -m stat  -a "path=$ROOT/terraform/sentiment.env" -e ansible_python_interpreter=auto_silent
echo "--- Ansible: shell module (contents) ---"
ansible localhost -i ../ansible/inventory.ini -m shell -a "cat $ROOT/terraform/sentiment.env" -e ansible_python_interpreter=auto_silent
cd "$ROOT"
ok "Task 6 done"

banner "ALL DONE"
echo "Jenkins Stage View : http://localhost:8090/job/sentiment-pipeline/"
echo "Docker worker      : http://localhost:8086"
echo "K8s NodePort       : http://localhost:30096"
echo "Full log           : $ROOT/logs/run_all.log"
