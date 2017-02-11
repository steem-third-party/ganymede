require 'test_helper'

class FindFlagwarJobTest < ActiveJob::TestCase
  def test_perform
    VCR.use_cassette('find_flag_war_job') do
      FindFlagwarJob.new.perform
      FindFlagwarJob.new.perform(tag: 'food')
      
      assert FindFlagwarJob.discussions('food').any?
    end
  end
end
