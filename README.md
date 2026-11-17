# Bulk GitHub Repo Cloner

This folder contains a script that clones or updates all repositories for the currently authenticated GitHub account into a local folder.

## Folder

- Script: `clone_all.sh`
- Target directory: `~/Documents/repos`

## Requirements

- GitHub CLI (`gh`) installed
- logged in to GitHub via `gh auth login`
- Git installed

## One-time setup

```bash
gh auth login --hostname github.com --git-protocol https
```

Then verify login:

```bash
gh auth status
gh api user --jq '.login'
```

If needed, trust GitHub's SSH host key for SSH mode:

```bash
mkdir -p ~/.ssh
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
```

## Run

Use HTTPS URLs:

```bash
cd ~/Documents/bulk-clones
URL_TYPE=https ./clone_all.sh
```

Use SSH URLs:

```bash
cd ~/Documents/bulk-clones
URL_TYPE=ssh ./clone_all.sh
```

Use a custom concurrency level:

```bash
cd ~/Documents/bulk-clones
URL_TYPE=https CONCURRENCY=8 ./clone_all.sh
```

You can also set concurrency with SSH URLs or lower/higher values depending on your machine:

```bash
cd ~/Documents/bulk-clones
URL_TYPE=ssh CONCURRENCY=4 ./clone_all.sh
URL_TYPE=https CONCURRENCY=12 ./clone_all.sh
```

## Notes

- The script uses the GitHub account currently logged in with `gh`.
- Repositories are cloned into `~/Documents/repos` by default.
- `URL_TYPE` can be `https` or `ssh`.
- `CONCURRENCY` controls how many repository clones/updates run in parallel; the default is `6`.
- Each repo prints its detected default branch before clone/update work begins.
- If a repo already exists, it runs `git pull --ff-only` instead of cloning again.
