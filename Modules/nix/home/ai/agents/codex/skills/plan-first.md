---
name: plan-first
description: Review repository state, agree on an explicit execution and Git publication plan before editing files. Use before repository changes.
---

# Plan first

1. **Review repository state:** Before editing, inspect `git status --short --branch`, tracked diffs, untracked files, and local commits not yet pushed. Review pre-existing changes and report their scope and status; do not overwrite, stage, or fold them into the task silently.
2. **Restate goal and targets:** Summarise the outcome, list the expected files to change, and state what will remain untouched. Highlight ambiguities.
3. **Plan implementation and publication:** Outline the implementation path, relevant edge cases, and proportionate verification. Include proposed commit messages for the pre-existing changes and the planned implementation, and state which commits will be pushed before and after the changes. Keep existing user changes in their own commit; do not amend or rewrite existing commits.
4. **Approval checkpoint:** Present the repository status, review summary, plan, and proposed commit messages. Wait for user approval before modifying files or committing/pushing anything. Approval covers only the reviewed scope and stated commit/push steps.
5. **Publish the starting state:** After approval, commit the reviewed pre-existing changes with the approved message and push them before editing. Push any already-committed local work that the user approved as part of the starting state. If changes cannot be cleanly isolated, or the scope differs from the approved summary, stop and ask for a revised plan.
6. **Implement and publish:** Follow the approved plan, then review the implementation diff and run the agreed checks. Commit the task changes separately with the approved message and push them. If the implementation or commit message needs a material change, return to the user for approval first.
7. **Report:** State the commits and push results, checks completed, and any remaining limitation. Explain any necessary deviation before proceeding with it.
