function gitchanges --wraps='git log --pretty=format: --name-only | sort | uniq -c | sort -rg' --description 'alias gitchanges=git log --pretty=format: --name-only | sort | uniq -c | sort -rg'
  git log --pretty=format: --name-only | sort | uniq -c | sort -rg $argv
        
end
