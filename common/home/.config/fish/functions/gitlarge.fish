function gitlarge
    # Step 1: Build a temp file of all blobs and sizes
    set tmpfile (mktemp)
    git rev-list --objects --all | \
        git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
        grep "^blob" | \
        sort -k3 -n -r > $tmpfile

    echo "Top 10 largest blobs and the commits introducing them:"
    echo "------------------------------------------------------"

    head -n 10 $tmpfile | while read -l line
        # Parse fields
        set fields (string split ' ' $line)
        set sha $fields[2]
        set size_bytes $fields[3]
        set filepath (string join ' ' $fields[4..-1])

        # Step 2: Find commits introducing this blob
        set commit ""
        for candidate_commit in (git rev-list --all)
            if git ls-tree -r $candidate_commit | grep -q $sha
                set commit $candidate_commit
                break
            end
        end

        # Step 3: Find branches which contain this commit
        set branches (git branch -r --contains $commit | string join ', ')

        echo "File: $filepath"
        echo "Size: $size_bytes bytes"
        echo "First Seen In Commit: $commit"
        echo "Branches: $branches"
        echo "------------------------------------------------------"
    end

    rm $tmpfile
end
