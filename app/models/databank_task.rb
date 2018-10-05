require 'rest-client'

class DatabankTask

  TASKS_URL = IDB_CONFIG[:tasks_url]

  def self.create_remote(datafile_web_id)

    datafile = Datafile.find_by_web_id(datafile_web_id)
    return nil unless datafile

    endpoint = "#{TASKS_URL}/tasks"
    payload = {task:{web_id: datafile.web_id,
                     storage_root: datafile.storage_root,
                     storage_key: datafile.storage_key,
                     binary_name: datafile.binary_name}}

    response = RestClient.post endpoint, payload

    if response.code == 201
      response_hash = JSON.parse(response)

      if response_hash.has_key?('id')
        return response_hash['id']
      else
        raise("task keys in response did not include id: #{response_hash.keys}")
      end
    else
      raise("problem creating task: #{response}")
    end
  end

  def self.get_all_remote_tasks

    endpoint = "#{TASKS_URL}/tasks"

    response = RestClient.get endpoint

    if response.code == 200
      response_hash = JSON.parse(response)
      return response_hash
    else
      raise("problem getting all remote tasks: #{response}")
    end


  end

  def self.get_remote_task(task_id)

    endpoint = "#{TASKS_URL}/tasks/#{task_id}"

    response = RestClient.get endpoint

    if response.code == 200
      response_hash = JSON.parse(response)
      return response_hash
    else
      raise("problem getting remote task for task: #{task_id}")
    end
  end

  def self.set_remote_task_status(task_id, new_status)
    endpoint = "#{TASKS_URL}/tasks/#{task_id}"
    payload = {task:{id: task_id,
                     status: new_status}}

    response = RestClient.patch endpoint, payload

    Rails.logger.warn("Problem setting status to #{new_status} for task #{task_id}.") unless response.code == 200

  end

  def self.get_remote_items(task_id)
    endpoint = "#{TASKS_URL}/tasks/#{task_id}/nested_items"

    response = RestClient.get endpoint

    if response.code == 200
      response_hash = JSON.parse(response)
      return response_hash
    else
      Rails.logger.warn("Problem getting tasks for task #{task_id}.")
    end




  end

  def self.problems(task_id)

    endpoint = "#{TASKS_URL}/tasks/#{task_id}/problems"

    response = RestClient.get endpoint

    Rails.logger.warn("inside get problems for task: #{task_id}")
    Rails.logger.warn(response)

    if response.code == 200
      response_hash = JSON.parse(response)
      return response_hash
    else
      raise("problem getting problems for task: #{task_id}")
    end

  end

  def self.problem_comments(task_id, problem_id)
    endpoint = "#{TASKS_URL}/tasks/#{task_id}/problems/#{problem_id}/comments"

    response = RestClient.get endpoint

    Rails.logger.warn("inside get comments for problem #{problem_id} for task #{task_id}")
    Rails.logger.warn(response)

    if response.code == 200
      response_hash = JSON.parse(response)
      return response_hash
    else
      raise("problem getting problem comments for task #{task_id} problem #{problem_id}")
    end
  end

  def self.nested_items(task_id)
    endpoint = "#{TASKS_URL}/tasks/#{task_id}/nested_items"

    response = RestClient.get endpoint

    Rails.logger.warn("inside get nested items for task #{task_id}")
    Rails.logger.warn(response)

    if response.code == 200
      response_hash = JSON.parse(response)
      return response_hash
    else
      raise("problem getting nested items for task #{task_id}")
    end

  end

end