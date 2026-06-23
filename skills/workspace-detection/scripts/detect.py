#!/usr/bin/env python3
"""Workspace detection for AIDLC bootstrap (M_AIDLC v2 §9.3).

Reverse-engineers the current repo into an ObservedFacts payload. READ-ONLY: it inspects files
and `git` config but writes nothing. Heuristic — the agent reviews/corrects before POSTing to
submit_bootstrap_facts. Emits the ObservedFacts JSON on stdout.
"""
import json
import os
import subprocess
import sys


def sh(*args):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception:
        return ""


def exists(*names):
    return any(os.path.exists(n) for n in names)


def detect():
    root = os.getcwd()
    files = set()
    for dirpath, dirnames, filenames in os.walk(root):
        # don't descend into vendored / VCS dirs
        dirnames[:] = [d for d in dirnames if d not in {".git", "node_modules", ".venv", "venv", "dist", "build", "target"}]
        depth = dirpath[len(root):].count(os.sep)
        if depth > 3:
            dirnames[:] = []
            continue
        for f in filenames:
            files.add(f)

    languages, frameworks, package_managers = [], [], []
    if "package.json" in files:
        languages.append("javascript/typescript"); package_managers.append("npm")
        try:
            pkg = json.load(open(os.path.join(root, "package.json")))
            deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
            for fw in ("react", "next", "express", "fastify", "vue", "svelte", "@angular/core"):
                if fw in deps:
                    frameworks.append(fw)
        except Exception:
            pass
    if exists("tsconfig.json"):
        languages.append("typescript")
    if "pyproject.toml" in files or "requirements.txt" in files or "setup.py" in files:
        languages.append("python")
        package_managers.append("pip")
    if "go.mod" in files:
        languages.append("go")
    if "Cargo.toml" in files:
        languages.append("rust"); package_managers.append("cargo")
    if "pom.xml" in files or "build.gradle" in files:
        languages.append("java")
    if "pnpm-lock.yaml" in files:
        package_managers.append("pnpm")
    if "yarn.lock" in files:
        package_managers.append("yarn")

    ci = []
    if os.path.isdir(os.path.join(root, ".github", "workflows")):
        ci.append("github-actions")
    if exists(".gitlab-ci.yml"):
        ci.append("gitlab-ci")
    if exists(".circleci"):
        ci.append("circleci")
    if exists("railway.toml", "railway.json", "nixpacks.toml"):
        ci.append("railway")

    remote = sh("git", "remote", "get-url", "origin")
    repo_host = ""
    if "github.com" in remote:
        repo_host = "github"
    elif "gitlab" in remote:
        repo_host = "gitlab"
    elif "bitbucket" in remote:
        repo_host = "bitbucket"

    # protected branches — inferred (the agent confirms; host config may not be readable locally)
    branches = sh("git", "branch", "-r").splitlines()
    protected = []
    for b in branches:
        name = b.strip().split("/")[-1]
        if name in ("main", "master", "production", "release"):
            protected.append(name)
    if not protected:
        protected = ["main"]

    test = {
        "runners": [r for r, present in (
            ("jest", "jest.config.js" in files or "jest.config.ts" in files),
            ("vitest", "vitest.config.ts" in files or "vitest.config.js" in files),
            ("pytest", "pytest.ini" in files or "pyproject.toml" in files),
            ("go-test", "go.mod" in files),
        ) if present],
        "locations": [d for d in ("test", "tests", "__tests__", "spec") if os.path.isdir(os.path.join(root, d))],
    }

    deploy = {
        "environments": [],
        "pipeline": "railway" if exists("railway.toml", "railway.json") else (
            "github-actions" if "github-actions" in ci else None),
    }

    monorepo = exists("lerna.json", "pnpm-workspace.yaml", "turbo.json") or os.path.isdir(os.path.join(root, "packages"))

    return {
        "git_remote": remote,
        "languages": sorted(set(languages)),
        "frameworks": sorted(set(frameworks)),
        "repo_host": repo_host,
        "ci": sorted(set(ci)),
        "protected_branches": sorted(set(protected)),
        "test": test,
        "deploy": deploy,
        "package_managers": sorted(set(package_managers)),
        "monorepo": bool(monorepo),
    }


if __name__ == "__main__":
    json.dump(detect(), sys.stdout, indent=2)
    sys.stdout.write("\n")
