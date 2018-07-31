class StorageManager

  attr_accessor :draft_root, :medusa_root, :tmpdir, :root_set

  def initialize

    storage_config = IDB_CONFIG[:storage].collect(&:to_h)
    self.root_set = MedusaStorage::RootSet.new(storage_config)
    self.draft_root = self.root_set.at('draft')
    self.medusa_root = self.root_set.at('medusa')

    #TODO: deal with tmpdir

  end

end
