require 'test_helper'

class FindFlagwarJobTest < ActiveJob::TestCase
  def test_perform
    VCR.use_cassette('find_flag_war_job') do
      FindFlagwarJob.new.perform
    end
  end

  def test_perform_with_tag
    VCR.use_cassette('find_flag_war_job') do
      FindFlagwarJob.new.perform(tag: 'life')
    end
  end
end
