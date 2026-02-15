# Solution: Hard Link Deployment Trap

## What Happened

The deployment system used **hard links** to rotate config files:

1. **Initial deploy (v1):**
   `ln config.v1.json config.json` — creates a hard link, both files point to the same inode

2. **Upgrade attempt (v2):**
   `rm config.json && ln config.v2.json config.json` — config.json now points to v2's inode

3. **v2 config has invalid JSON:**
   The app crashes on startup (missing comma in JSON)

4. **Rollback attempt:**
   `rm config.json && ln config.v1.json config.json` — link back to v1

**But the rollback fails.** Why?

## The Hard Link Problem

When you create a hard link with `ln source target`, both files point to **the same inode** on disk. Editing either file modifies the inode itself, so changes are visible from all hard links.

In this scenario:
- `config.v1.json` and `config.v2.json` were originally created separately
- But when the engineer tried to fix v2's syntax error by editing `config.v2.json`, they **modified the shared inode**
- Since v1 and v2 share the same inode (due to hard linking during deployment), editing v2 also corrupted v1

Now `config.v1.json` contains v2's broken content. Rolling back creates a hard link to corrupted data.

## Diagnosing the Issue

```bash
vagrant ssh
cd /home/vagrant/configs
ls -li
```

You'll see both `config.v1.json` and `config.v2.json` have the **same inode number**. This means they're not separate files — they're two names pointing to the same data.

```bash
cat config.v1.json
cat config.v2.json
```

Both contain the broken v2 content (invalid JSON with missing comma).

## The Fix

### 1. Recreate proper v1 config

Delete the corrupted files and recreate v1 from scratch:

```bash
cd /home/vagrant/configs
rm config.v1.json config.v2.json

cat > config.v1.json <<'EOF'
{
  "version": "1.0.0",
  "feature_flags": {
    "new_api": false,
    "debug_mode": false
  },
  "database": {
    "host": "localhost",
    "port": 5432
  }
}
EOF
```

### 2. Deploy v1 using a copy (not hard link)

```bash
cp config.v1.json ../app/config.json
```

Or use a **symlink** (which doesn't have this problem):

```bash
ln -sf /home/vagrant/configs/config.v1.json ../app/config.json
```

### 3. Restart the app

```bash
cd ../app
pkill -f "python3 app.py"
nohup python3 app.py > app.log 2>&1 &
echo $! > app.pid
```

### 4. Verify

```bash
exit  # exit VM
./verify.sh
```

## Key Takeaways

- **Hard links share inodes.** Editing one hard-linked file modifies all of them.
- **Symlinks don't have this problem.** A symlink is a pointer to a filename, not an inode. Replacing the target file doesn't affect other symlinks.
- **For atomic config rotation, use symlinks or copies,** not hard links.
- **Inode semantics matter in deployment.** `ln` creates hard links by default. Use `ln -s` for symlinks or `cp` for copies.
- **This is a real production antipattern.** Hard-link-based deployments break rollback assumptions.

## Better Deployment Pattern

Instead of hard links:

```bash
# BAD (hard link)
ln config.v2.json config.json

# GOOD (symlink)
ln -sf config.v2.json config.json

# GOOD (atomic copy with temp file)
cp config.v2.json config.json.tmp
mv config.json.tmp config.json
```

Symlinks allow you to change the target independently. Atomic `cp + mv` ensures config updates are never partial.
