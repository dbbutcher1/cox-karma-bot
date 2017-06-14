require 'slack-ruby-bot'

class KarmaBot < SlackRubyBot::Bot

  help do
    title 'Cox Karma Bot'
    desc 'Tracks Karma'

    command 'leaderboard' do
      desc 'Prints the top 10 users'
      long_desc 'Cause I can....'
    end
  end

  match /(\+{2,})|(\-{2,})/ do |client, data, match|
    channel = SlackChannel.find_or_create_by( slack_id: data.channel )

    # Magical regex that will find all instances of users with a + or -
    karma_changes = data.text.scan( /(\<?(.+?)\>?\s*((\+{2,})|(\-{2,})))/ )

    # Use this to print out stuff in a formatted way in slack
    attachments = []

    karma_changes.each do | karma_change |
      # Do some magic and remove the cruft so that we can act on only the requested karma chnage
      change = karma_change.delete_if { |change| change.nil? ||
        change.match( /(\<?(.+?)\>?\s*((\+{2,})|(\-{2,})))/ ).nil? }.first

      # Parse out the user id and remove angle brackets and the @ symbol
      user_string = change.gsub( /\<|\>|\+|\-|\@/, '' ).strip
      puts change, user_string

      slack_id, user_alias = user_string.split( '|' )

      if change.include?( '+' )
        karma = change.count( '+' ) - 1 > Rails.application.config.max_karma ?
          Rails.application.config.max_karma : change.count( '+' ) - 1
      else
        karma = -( change.count( '-' ) - 1 > Rails.application.config.max_karma ?
          Rails.application.config.max_karma : change.count( '-' ) - 1 )
      end

      slack_user = SlackUser.find_or_create_by( slack_id: slack_id )
      slack_user.karma += karma
      slack_user.slack_channels << channel
      slack_user.alias = user_alias unless user_alias.blank?
      slack_user.save!

      attachments << {
        fallback: "<@#{slack_user.slack_id}> now has #{slack_user.karma}",
        title: 'Karma Given',
        text: "<@#{slack_user.slack_id}> now has #{slack_user.karma}",
        color: '#00FF00'
      }
    end

    client.web_client.chat_postMessage( channel: channel.slack_id, as_user: true, attachments: attachments )
  end

  command 'leaderboard' do |client, data, match|
    puts match[ :count ]
  end
end
