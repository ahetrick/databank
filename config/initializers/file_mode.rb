require 'pathname'

Databank::Application.file_mode = Databank::FileMode::WRITE_READ

mount_path = Pathname.new(IDB_CONFIG[:storage_mount]).realpath

if (mount_path.to_s.casecmp IDB_CONFIG[:read_only_realpath]) == 0
  Databank::Application.file_mode = Databank::FileMode::READ_ONLY
end



