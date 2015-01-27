require 'jira'

class Robut::Plugin::JiraClient
  include Robut::Plugin

  class << self
    attr_accessor :jira_credentials
  end

  def usage
    "!1234 - will return #{self.jira_project}-1234 task description from Jira"
  end

  def handle(time, sender_nick, message)
    if match = message.match(/(\!|(#{jira_credentials[:jira_project]}\-))([1-9][0-9]+)/)
      m1, m2, task_index = match.captures
      reply(ios_issue_info(task_index))
    end
  end

  def jira_client
    options = {
       :username => jira_credentials[:username],
       :password => jira_credentials[:password],
       :site     => jira_credentials[:site],
       :context_path => '',
       :auth_type => :basic
      }

    client = JIRA::Client.new(options)
  end

  http do
    get '/sendmsg' do
      message = params[:message]
      say "#{message}", nil
      halt 200
    end
  end

  def issue_uri_str(issue_id)
      "#{jira_credentials[:site]}browse/#{issue_id}"
  end
  
  def issue_info(issue_id, with_description = false)
    client = jira_client() 
    issue = client.Issue.find(issue_id)
    result = nil
    if issue 
      fields = issue.attrs["fields"]
      summary = nil
      description = nil
      if fields
        summary = fields["summary"]
        description = fields["description"] || "<no description>"
      end 
      if fields && summary
        result = "#{issue_uri_str(issue_id)}: #{summary}"
        if with_description
          result += "\n  #{description.lines[0..15].join("  ")}"
        end
      end 
    end
    result
  end

  def ios_issue_info(short_issue_id,with_description=false)
    return issue_info("#{jira_credentials[:jira_project]}-"+short_issue_id,with_description)
  end

  def jira_credentials
    return self.class.jira_credentials
  end

end