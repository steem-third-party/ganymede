require 'test_helper'

class FindFlagwarJobTest < ActiveJob::TestCase
  
  # Note, if you delete the vcr fixture expecting it to get recreated, this
  # test might fail if there is no flag war in progress.
  def test_perform
    VCR.use_cassette('find_flag_war_job', record: RECORD_MODE) do
      FindFlagwarJob.new.perform
      FindFlagwarJob.new.perform(tag: 'food')
      
      assert FindFlagwarJob.discussions('food').any?
    end
  end
end
