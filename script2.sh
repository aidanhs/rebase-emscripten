set -e

if [ ! -d emscripten-fastcomp-clang ]; then
  git clone https://github.com/kripken/emscripten-fastcomp-clang.git
  cd emscripten-fastcomp-clang
  git remote add pnacl-clang https://git.chromium.org/native_client/pnacl-clang.git
  git checkout --orphan pnacl-clang
  git reset --hard && git clean -f -x -d
  git pull pnacl-clang master
  cd -
fi

cd emscripten-fastcomp-clang

if [ "$1" = reset ]; then
  git clean -f -x -d
  git reset --hard
  git checkout incoming
  rm -f ../clang_patch_to_undo ../clang_patch_to_reapply
  git branch -D aphs-merge-pnacl-r34 aphs-tmp-diff || true
  exit
fi

git checkout incoming

# Step 0 - prepare
git config merge.renamelimit 2000
git checkout -b aphs-merge-pnacl-r34
git checkout -b aphs-tmp-diff
git diff a963b803407c HEAD > ../clang_patch_to_undo
git revert --no-edit de1f674fbda4270 # This was cherry picked #4
git revert --no-edit 88198a1fe0d27   # Backported fix from 3.4
git diff a963b803407c HEAD > ../clang_patch_to_reapply
git checkout aphs-merge-pnacl-r34

# Step 1 - undo emscripten changes
git apply --index --reverse ../clang_patch_to_undo
git commit -m 'Prep for merging 3.4: undo changes from 3.3 branch

Copying the process from PNaCl, undo the changes made on our branch
so we can cleanly merge PNaCl Clang 3.4

git diff a963b803407c HEAD > ../clang_patch_to_undo
git apply --index --reverse ../clang_patch_to_undo'

# Step 2 - roll forward to pnacl
git merge --no-commit c9e11978abdba
git commit -m 'Update to Clang pnacl after they merged trunk r34 and reapplied pnacl changes'

# Step 3 - apply emscripten changes
cat ../repatch_clang | patch -u ../clang_patch_to_reapply
git apply --whitespace=fix --index --reject ../clang_patch_to_reapply || true

echo
echo "These files mark conflicts and must be resolved:"
find . -name '*.rej'
