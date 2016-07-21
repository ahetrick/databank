require 'pathname'

Databank::Application.file_mode = Databank::FileMode::WRITE_READ

mount_path = Pathname.new(IDB_CONFIG[:storage_mount]).realpath

if (mount_path.to_s.casecmp IDB_CONFIG[:read_write_realpath]) != 0
  Databank::Application.file_mode = Databank::FileMode::READ_ONLY
  Databank::Application.alert_read_only_message = "Illinois Data Bank system is undergoing maintenance, and datasets cannot currently be added or edited."
end



