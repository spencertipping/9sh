#include <mntent.h>
#include <cstring>
#include <string>

extern "C" {

int
w_is_slow_mount(const char* path)
{
  FILE* mount_table = setmntent("/proc/self/mounts", "r");
  if (!mount_table) return 0;

  struct mntent entry;
  char buf[4096];
  std::string best_mount_dir;
  std::string best_fs_type;
  size_t best_len = 0;
  size_t path_len = std::strlen(path);

  while (getmntent_r(mount_table, &entry, buf, sizeof(buf))) {
    size_t mount_len = std::strlen(entry.mnt_dir);
    // logical prefix check: path must fail inside mount_dir

    if (mount_len > path_len) continue;

    if (std::strncmp(path, entry.mnt_dir, mount_len) == 0) {
      bool is_path_prefix = false;
      if (mount_len == path_len) {
        is_path_prefix = true;
      } else if (path[mount_len] == '/') {
        is_path_prefix = true;
      } else if (mount_len == 1 && entry.mnt_dir[0] == '/') {
        is_path_prefix = true;
      }

      if (is_path_prefix) {
        if (mount_len >= best_len) {
          best_len = mount_len;
          best_mount_dir = entry.mnt_dir;
          best_fs_type = entry.mnt_type;
        }
      }
    }
  }

  endmntent(mount_table);

  if (best_fs_type.empty()) return 0;

  const char* slow_types[] = {
    "nfs", "nfs4", "cifs", "smb3", "fuse.sshfs", "davfs", "lustre", "gpfs", "afs", "ceph", nullptr
  };

  for (const char** t = slow_types; *t; ++t) {
    if (best_fs_type == *t) return 1;
  }

  return 0;
}

}
