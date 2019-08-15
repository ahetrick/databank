require 'fileutils'
#before each test make sure that the strorage roots are empty
Before do
  Application.storage_manager.draft_root.delete_all_content
  Application.storage_manager.medusa_root.delete_all_content
end