Databank::Application.databank_config =
    YAML.load_file(File.join(Rails.root, 'config', 'databank.yml'))[Rails.env]