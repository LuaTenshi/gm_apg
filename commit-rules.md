# Commit Rules

- [Commit Rules](#commit-rules)
  - [Squash](#squash)
    - [Here's what you do](#heres-what-you-do)
    - [Oh no I messed up](#oh-no-i-messed-up)
  - [Be Descriptive](#be-descriptive)
  - [Test and Check](#test-and-check)
  - [Be Considerate](#be-considerate)

## Squash

[Back to Top](#commit-rules)

If you have lots of commits like "Oops", "Reverted X", "Fixed bug", squash them.

### Here's what you do

1. Backup your current repo by copying it into another folder
   1. Be sure to remove the `.git` folder as you don't need that in your backup.
2. Go back to the working folder, aka the one with the `.git` folder.
3. `git log --pretty=oneline --abbrev-commit`
   1. The displayed list will be shown top (newest) to bottom (oldest).
   2. Find the main commit that you made (before the small fixes).
   3. Copy the code under it, it will look something like this... `742c3ac`
4. `git rebase -i <abbreviated commit code>`
   1. Git should guide you through this.
   2. If you need to fix conflicts your files will be edited, and you will get an error.
   3. [Don't panic](https://help.github.com/en/articles/resolving-a-merge-conflict-using-the-command-line)
5. Review your changes!
6. Make sure to **review your changes** sometimes conflict resolution can get undesirable code back into your repo.
7. When you're ready use `git push --force` to push your rebase.

### Oh no I messed up

1. Don't panic! You made a backup.
2. Delete everything besides the `.git` folder.
3. Copy and paste everything from your backup.
4. Now just push the change as a new commit.
   - Be sure to be very descriptive in your commit message/comment.

---

You may also want to look into [this stackoverflow question](https://stackoverflow.com/q/134882) and [the answer](https://stackoverflow.com/a/135614) provided.

## Be Descriptive

[Back to Top](#commit-rules)

You don't have to write a paragraph about all your changes, but describe what you're trying to do in a clear way.

## Test and Check

[Back to Top](#commit-rules)

Always test and check your code, and don't just test once. Test multiple times in multiple environements. If your code isn't tested don't commit.

## Be Considerate

[Back to Top](#commit-rules)

This addon will be runnning with other addons, please make sure it plays nice. Specify any detours, try not to [error](https://wiki.garrysmod.com/page/Global/error), and be sure to make all your codes behaviour expected.
