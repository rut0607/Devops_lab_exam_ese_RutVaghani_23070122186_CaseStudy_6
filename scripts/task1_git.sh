#!/usr/bin/env bash
# Task 1 - Git: repo sentiment-app, branch release-v4.0, commit sentiment.properties (BATCH=500),
# merge into main, tag v4.0.0-final.
# Run from an EMPTY folder named sentiment-app (or a fresh one) in Git Bash / terminal.
set -e

git init sentiment-app
cd sentiment-app
git checkout -b main

# Base commit on main so there is something to merge into
echo "# sentiment-app" > README.md
git add README.md
git commit -m "Initial commit on main"

# Feature work on the release branch
git checkout -b release-v4.0
echo "BATCH=500" > sentiment.properties
git add sentiment.properties
git commit -m "Add sentiment.properties with BATCH=500"

# Merge back into main and tag
git checkout main
git merge --no-ff release-v4.0 -m "Merge release-v4.0 into main"
git tag -a v4.0.0-final -m "Sentiment app v4.0.0 final release"

# Verification (screenshot this output)
git log --oneline --graph --all --decorate
git branch -a
git tag
cat sentiment.properties
