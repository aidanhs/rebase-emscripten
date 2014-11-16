set -e
cd emscripten-fastcomp

if [ "$1" = reset ]; then
  git clean -f -x -d
  git reset --hard
  git checkout incoming
  rm -f ../patch_to_undo ../patch_to_reapply
  git branch -D aphs-merge-pnacl-r34 aphs-tmp-diff || true
  exit
fi

# Step 0 - prepare
git config merge.renamelimit 2000
git checkout -b aphs-merge-pnacl-r34
git checkout -b aphs-tmp-diff
git diff 7026af7138fccfb HEAD > ../patch_to_undo
git revert --no-edit 370337f63da8fb2 # This was cherry picked #53
git diff 7026af7138fccfb HEAD > ../patch_to_reapply
git checkout aphs-merge-pnacl-r34

# Step 1 - undo emscripten changes
git apply --index --reverse ../patch_to_undo
git commit -m 'Prep for merging 3.4: undo changes from 3.3 branch

Copying the process from PNaCl, undo the changes made on our branch
so we can cleanly merge PNaCl LLVM 3.4

git diff 7026af7138fccfb HEAD > ../patch_to_undo
git apply --index --reverse ../patch_to_undo'

# Step 2 - roll forward to pnacl
git merge --no-commit fe90708cae88970
git commit -m 'Update to LLVM pnacl after they merged trunk r34 and reapplied pnacl changes'

# Step 3 - apply emscripten changes
cat ../repatch | patch -u ../patch_to_reapply
git apply --whitespace=fix --index --reject ../patch_to_reapply || true
