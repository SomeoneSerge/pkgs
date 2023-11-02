import os

if "PREFIX_PYTHON_MODULES_DEBUG" in os.environ:
    import pdb

    pdb.set_trace()

import argparse
import shutil
import tempfile
import textwrap
import traceback
from pathlib import Path
from typing import Literal, Optional, Tuple

from rope.base.project import Project
from rope.refactor.move import MoveModule

parser = argparse.ArgumentParser("prefix-python-modules")
parser.add_argument("repo_root", type=Path)
parser.add_argument("--dont-catch", action="store_true")
parser.add_argument("--prefix", required=True)
parser.add_argument("--verbose", action="store_true")
parser.add_argument("--quiet", action="store_true")
parser.add_argument(
    "--mode",
    default="first-error",
    choices=("first-error", "keep-going", "interactive"),
)

CATCH_ERRORS = True


def indent(s: str, n: int = 4) -> str:
    return textwrap.indent(s, " " * n)


def convert_to_packages(project_root):
    project = Project(project_root)
    python_files = [p for p in project.get_python_files()]

    try:
        for f in python_files:
            rel_path = Path(f.path)
            if rel_path.parent == Path("."):
                continue
            path = project_root / rel_path.parent / "__init__.py"
            path.touch()
    finally:
        project.close()


def apply_changes(
    project,
    changes,
    mode: Literal["first-error", "keep-going", "interactive"],
) -> Tuple[
    Optional[Literal["quit", "next"]],
    Optional[str],
    Optional[Exception],
    Optional[str],
]:
    description = changes.get_description()

    while True:
        try:
            if mode == "interactive":
                print("Apply the following patch?")
                print(indent(description))
                print("[Y]es, [n]o, [q]uit? [Ynq]")
                action = input().lower().strip()
                if action == "":
                    action = "y"
                assert action in "ynq", action
                if action == "n":
                    return ("next", None, None, None)
                elif action == "q":
                    return ("quit", None, None, None)
            project.do(changes)
            project.validate()
        except Exception as e:
            if not CATCH_ERRORS:
                raise
            if mode != "interactive":
                return (None, description, e, traceback.format_exc())

            keep_asking = True
            action = "q"
            while keep_asking:
                print(
                    f"Failed to apply the patch: {e}\n"
                    "...[r]etry, print [v]erbose error, skip and proceed to the [n]ext patch, or [Q]uit? [rvnQ]"
                )
                action = input().lower().strip()
                if action == "":
                    action = "q"
                assert action in "rvnq", action
                if action == "v":
                    print(traceback.format_exc())
                    continue
                keep_asking = False
            if action == "q":
                return ("quit", description, e, traceback.format_exc())
            elif action == "n":
                return ("next", description, e, traceback.format_exc())
            else:
                continue
        else:
            return (None, description, None, None)


def main():
    args = parser.parse_args()

    global CATCH_ERRORS
    CATCH_ERRORS = not args.dont_catch

    convert_to_packages(args.repo_root)

    project = Project(args.repo_root)

    parallel_tree_for_rope = tempfile.mkdtemp()

    try:
        project.validate()

        python_files = [p for p in project.get_python_files()]
        python_files = [p for p in python_files if Path(p.path).parts[0] != args.prefix]

        toplevel_files = sorted(set(Path(p.path).parts[0] for p in python_files))
        toplevel_module_names = [name.removesuffix(".py") for name in toplevel_files]

        new_package = project.get_folder("omnimotion")
        if not new_package.exists():
            new_package.create()
            new_package.create_file("__init__.py")

        successes = []
        failures = []
        for name in toplevel_module_names:
            m = project.get_module(name)
            r = m.get_resource()

            old_path = r.pathlib

            changes = MoveModule(project, r).get_changes(new_package)
            (action, description, error, tb) = apply_changes(
                project, changes, mode=args.mode
            )

            if error is not None and args.verbose:
                failures.append((description, tb))
            elif error is not None:
                failures.append((description, error))
            if error is None and description is not None:
                successes.append(description)
                continue

            if action == "quit":
                parser.exit(0)
            elif action == "next":
                continue

            if error is not None and args.mode == "first-error":
                break

            assert not old_path.exists()

        if args.mode != "interactive" and not args.quiet:
            for description in successes:
                print("Successfully applied the patch:")
                print(indent(description))

            for description, e in failures:
                print("Failed to apply the patch:")
                print(indent(description))
                print(f"The error was: ({type(e).__name__}) {e}")

        if not args.quiet and failures:
            print(f"Observed the total of {len(failures)} failures")

        if failures:
            parser.exit(1)
    finally:
        project.close()
        shutil.rmtree(parallel_tree_for_rope, ignore_errors=True)


if __name__ == "__main__":
    main()
