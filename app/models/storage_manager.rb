class StorageManager

  attr_accessor :draft_root, :medusa_root, :root_set, :tmpdir

  def initialize

    storage_config = IDB_CONFIG[:storage].collect(&:to_h)
    self.root_set = MedusaStorage::RootSet.new(storage_config)
    self.draft_root = self.root_set.at('draft')
    self.medusa_root = self.root_set.at('medusa')
    initialize_tmpdir

  end

  def initialize_tmpdir
    self.tmpdir = IDB_CONFIG[:storage_tmpdir]
  end

end
