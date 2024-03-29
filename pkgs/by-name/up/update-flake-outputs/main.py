#!/usr/bin/env python

import argparse
import json
import os
import pprint
import subprocess
import tempfile
import textwrap
from contextlib import contextmanager
from pathlib import Path
from sys import stderr
from typing import Optional

parser = argparse.ArgumentParser("update-flake-outputs")
parser.add_argument("git_checkout")
parser.add_argument("--remote")
parser.add_argument("--overwrite-existing", action="store_true")


def get_flake_outputs(uri: str):
    p = subprocess.run(
        ["nix", "flake", "show", "--json", uri], check=True, capture_output=True
    )
    return json.loads(p.stdout)


def flake_packages(outputs: dict):
    all_platforms = outputs.get("packages", {})

    packages = {}
    for platform, plat_packages in all_platforms.items():
        for path, package in plat_packages.items():
            if path in packages:
                continue
            if package.get("type", None) != "derivation":
                continue
            packages[path] = f"{platform}.{path}"

    return packages


def nix_update(attr_name):
    subprocess.run(
        [
            "nix-update",
            "--commit",
            "--use-update-script",
            "--flake",
            attr_name,
        ],
        check=True,
    )


@contextmanager
def cwd(new_cwd: Optional[str | Path]):
    old_cwd = os.getcwd()

    if new_cwd is not None:
        os.chdir(new_cwd)

    try:
        yield
    finally:
        os.chdir(old_cwd)


@contextmanager
def git_worktree(worktree_path, new_branch, head_rev=None):
    args = [
        "git",
        "worktree",
        "add",
        "-B",
        new_branch,
        worktree_path,
    ]
    if head_rev is not None:
        args.append(head_rev)
    p = subprocess.run(
        args,
        check=True,
    )
    try:
        with cwd(worktree_path):
            yield
    finally:
        subprocess.run(
            ["git", "worktree", "remove", "-f", worktree_path],
            check=True,
        )


def git_rev_parse(rev):
    return (
        subprocess.run(["git", "rev-parse", rev], check=True, capture_output=True)
        .stdout.decode("utf8")
        .strip()
    )


def get_head():
    return git_rev_parse("HEAD")


def git_add_update():
    subprocess.run(["git", "add", "-u"], check=True, capture_output=True)


def git_commit_if_any(message):
    try:
        subprocess.run(
            ["git", "commit", "-m", message], check=True, capture_output=True
        )
        return True
    except subprocess.CalledProcessError:
        return False


def git_push_force_set_default(remote, remote_branch):
    args = [
        "git",
        "push",
        "--force",
        "-u",
        remote,
        f"HEAD:{remote_branch}",
    ]
    print(f"Executing {args}", file=stderr)
    subprocess.run(
        args,
        check=True,
    )


def gh_pr_list():
    p = subprocess.run(
        ["gh", "pr", "list", "--json", "title"],
        capture_output=True,
    )
    if p.returncode != 0:
        print(f"gh pr list failed: {p.stderr}")
    p.check_returncode()
    return json.loads(p.stdout)


def gh_pr_create(title, remote_branch=None):
    args = [
        "gh",
        "pr",
        "create",
        "--title",
        title,
        "--fill",
        "-B",
        "master",
    ]
    if remote_branch is not None:
        args.extend(["--head", remote_branch])
    p = subprocess.run(
        args,
        check=False,
        shell=False,
        capture_output=True,
    )

    if p.returncode != 0:
        print(f"{args} has failed:")
        print(textwrap.indent(p.stdout.decode("utf8"), prefix=" " * 4), file=stderr)
        print(textwrap.indent(p.stderr.decode("utf8"), prefix=" " * 4), file=stderr)

    p.check_returncode()
    return p.stdout.decode("utf8")


def get_short_msg(commit_id="HEAD"):
    return subprocess.run(
        [
            "git",
            "show",
            "-s",
            "--format=%s",
            commit_id,
        ],
        check=True,
        capture_output=True,
    ).stdout.decode("utf8")


if __name__ == "__main__":
    args = parser.parse_args()

    root = Path(args.git_checkout).absolute()

    with tempfile.TemporaryDirectory() as td, cwd(root):
        open_prs = [x["title"] for x in gh_pr_list()]
        packages = flake_packages(get_flake_outputs(args.git_checkout))

        pprint.pprint(packages)
        pprint.pprint(open_prs)

        for name in packages:
            new_checkout = Path(td, name)

            branch_name = f"update-flake-outputs/{name}"
            with git_worktree(new_checkout, branch_name, "HEAD"):
                try:
                    old = get_head()
                    nix_update(name)
                    new = get_head()

                    if new == old:
                        continue

                    print(f"old: {old}", file=stderr)
                    print(f"new: {new}", file=stderr)

                    msg = get_short_msg()
                    if not args.overwrite_existing and msg in open_prs:
                        print(
                            f"Skipping because an old PR is already open: {msg}",
                            file=stderr,
                        )
                        continue

                    try:
                        remote_changed = new != git_rev_parse(f"{args.remote}/{branch_name}")
                    except subprocess.CalledProcessError:
                        remote_changed = True

                    if remote_changed:
                        git_push_force_set_default(args.remote, branch_name)
                    else:
                        print(
                            f"Branch {branch_name} already at {new}. Not pushing",
                            file=stderr,
                        )

                    if msg in open_prs:
                        continue

                    gh_pr_create(msg, remote_branch=branch_name)

                except Exception as e:
                    print(f"Failed to update {name}: {e}")
