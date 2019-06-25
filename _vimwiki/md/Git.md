# Git

#### Revert changes to a file in a commit

    git show some_commit_sha1 -- some_file.c | git apply -R

#### So, firstly setup the remote repository:

	ssh git@example.com
	mkdir my_project.git
	cd my_project.git
	git init --bare
	git update-server-info # If planning to serve via HTTP
	exit

On local machine:

	cd my_project
	git init
	git add *
	git commit -m "My initial commit message"
	git remote add origin git@example.com:my_project.git
	git push -u origin master
	
Done!

#### Setting your branch to exactly match the remote branch can be done in two steps:

    git fetch origin OR git fetch --all
    git reset --hard origin/master

If you want to save your current branch's state btig4S
fore doing this (just in case), you can do:
    
    git commit -a -m "Saving my work, just in case"
    git branch my-saved-work

Now your work is saved on the branch "my-saved-work" in case you  decide you want it back (or want to look at it later or diff it against  your updated branch).
Note that the first example assumes that the remote repo's name is  "origin" and that the branch named "master" in the remote repo matches  the currently checked-out branch in your local repo.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

###### List tracked files:
    git ls-tree --name-only -r HEAD

###### Show remote repo:
    git remote show origin
	
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

###### Use git rm:

	git rm file1.txt
	git commit -m "remove file1.txt"

###### But if you want to remove the file only from the Git repository and not remove it from the filesystem, use:

	git rm --cached file1.txt

###### And to push changes to remote repo

	git push origin branch_name  


* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


#### Reset git history:
    move .git /somewhere/else
    git init
    git add .
    git commit -m "initial commit"
    git remote add origin [repoUrl]
    git push -u origin master --force
    

#### Git deal with multiple commits commits 
    git rebase -i

    Then chose the commit you want to edit and the changes.
    
    git commit -a --amend
    git rebase --continue
