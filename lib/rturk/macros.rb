module RTurk::Macros

  # Attempt to expire hit, then approve assignments, and finally dispose of
  def kill_hit(hit_id)
    forceExpireHIT(:HITId => hit_id)
    get_assignments_for_hit(hit_id).each do |assignment|
      approveAssignment(:AssignmentId => assignment[:AssignmentId])
    end
    disposeHIT(:HITId => hit_id)
  end

  # Wipe out all HIT's associated with this account
  def blank_slate
    search_response = searchHITs(:PageSize => 100)
    if search_results = search_response['SearchHITsResult']['HIT']
      search_results.each do |hit|
        kill_hit(hit['HITId'])
      end
    end
  end


  def get_assignments_for_hit(hit)
    response = request(:Operation => 'GetAssignmentsForHIT', :HITId => hit)
    assignments = []
    if response['GetAssignmentsForHITResult']['Assignment'].instance_of?(Array)
      response['GetAssignmentsForHITResult']['Assignment'].each do |assignment|
        answer = RTurk::Answer.parse(assignment['Answer'])
        assignment.delete('Answer')
        assignment['Answer'] = answer
        assignments << assignment
      end
    else
      if assignment = response['GetAssignmentsForHITResult']['Assignment']
        answer = RTurk::Answer.parse(response['GetAssignmentsForHITResult']['Assignment']['Answer'])
        assignment.delete('Answer')
        assignment['Answer'] = answer
        assignments << assignment
      end
    end
    assignments
  end

  def url_for_hit(hit_id)
    url_for_hit_type(getHIT(:HITId => hit_id)[:HITTypeId])
  end

  def url_for_hit_type(hit_type_id)
    if @host =~ /sandbox/
      "http://workersandbox.mturk.com/mturk/preview?groupId=#{hit_type_id}" # Sandbox Url
    else
      "http://mturk.com/mturk/preview?groupId=#{hit_type_id}" # Production Url
    end
  end


end
