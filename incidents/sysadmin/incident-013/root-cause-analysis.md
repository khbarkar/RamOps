# Root Cause Analysis: The Vanishing Log Files

## Incident Summary

Disk space was critically low (95% full) despite log rotation having run successfully. The deleted log files were not freeing disk space because the application still had open file descriptors pointing to them.

## Root Cause

When a file is deleted in Linux, the disk space is only freed when:
1. All hard links to the inode are removed (link count = 0)
2. All processes close their file descriptors to that inode

The log rotation script moved and deleted the old log file, but the web application still had the file open for writing. The inode remained allocated with the deleted file consuming disk space until the process closed the file descriptor.

## Technical Details

**Inodes and File Descriptors:**
- An inode stores file metadata and data block pointers
- A file descriptor is a process's reference to an open file
- Deleting a filename removes the directory entry but not the inode
- The inode persists while any process holds it open

**Hard Links vs Soft Links:**
- Hard links share the same inode (link count > 1)
- Soft links (symlinks) are separate files containing a path
- Deleting a hard link decrements the link count
- Deleting a symlink target breaks the link

## Resolution

**Immediate Fix:**
Restart the application to release the file descriptor:
```bash
systemctl restart webapp.service
```

**Proper Fix:**
Modify log rotation to use one of these strategies:
1. Send SIGHUP to the app to reopen log files
2. Use symlinks: `current.log` → `app-2024-01-15.log`
3. Use a log aggregator that handles rotation properly

## Prevention

- Use proper log rotation with process signaling
- Monitor for deleted files with open descriptors: `lsof | grep deleted`
- Implement log streaming to external systems
- Use systemd journal for automatic log management

## Key Learnings

- Files aren't truly deleted until all references are gone
- `df` shows actual disk usage, `du` shows file sizes
- Understanding inodes is critical for filesystem troubleshooting
- Log rotation requires coordination with the application
