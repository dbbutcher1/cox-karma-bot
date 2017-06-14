require 'slack-ruby-bot'

class KarmaBot < SlackRubyBot::Bot
  help do
    title 'Cox Karma Bot'
    desc 'Tracks Karma'

    command '<user or thing> ++' do
      desc "Adds karma"
      long_desc "Add karma to a given user or thing"
    end

    command '<user or thing> --' do
      desc "Removes karma"
      long_desc "Removes karma to a given user or thing"
    end

    command 'leaderboard' do
      desc 'Prints the top 10 users across all channels'
      long_desc 'This command shows who leads in karma across the organization'
    end

    command 'top' do
      desc 'Prints the top users within a channel'
      long_desc 'This command will display the top X users (default 5) within a channel.\n\nexample:\n @coxkarma top 7'
    end
  end

  match /(\+{2,})|(\-{2,})/ do |client, data, match|
    channel = SlackChannel.find_or_create_by( slack_id: data.channel )

    # Magical regex that will find all instances of users with a + or -
    karma_changes = data.text.scan( /(([\w^-]+|<[^>]+>)\s*([+]{2,}|[-]{2,}))/ ).collect { |x| x.first }

    # Use this to print out stuff in a formatted way in slack
    attachments = []

    karma_changes.each do | karma_change |

      # Do some magic and remove the cruft so that we can act on only the requested karma chnage
      change = karma_change.scan( /[+]{2,}|[-]{2,}/ ).first

      # Parse out the user id and remove angle brackets and the @ symbol
      user_string = karma_change.gsub( /\<|\>|\+{2,}|\-{2,}|\@/, '' ).strip

      slack_id, user_alias = user_string.split( '|' )

      if change.include?( '+' )
        karma = change.count( '+' ) - 1 > Rails.application.config.max_karma ?
          Rails.application.config.max_karma : change.count( '+' ) - 1
      else
        karma = -( change.count( '-' ) - 1 > Rails.application.config.max_karma ?
          Rails.application.config.max_karma : change.count( '-' ) - 1 )
      end

      #unless slack_id == client.user
        slack_user = SlackUser.find_or_create_by( slack_id: slack_id )
        slack_user.karma += karma
        slack_user.slack_channels << channel unless slack_user.channels.find( channel.id )
        slack_user.alias = user_alias unless user_alias.blank?
        slack_user.save!

        attachments << {
          fallback: "<@#{slack_user.slack_id}> now has #{slack_user.karma}",
          title: 'Karma Given',
          text: "<@#{slack_user.slack_id}> now has #{slack_user.karma}",
          color: '#00FF00'
        }
      #end
    end

    client.web_client.chat_postMessage( channel: channel.slack_id, as_user: true, attachments: attachments )
  end

  command 'leaderboard' do |client, data, match|
    #use to report user karma
    text = ''

    # Use this to print out stuff in a formatted way in slack
    attachments = []

    slack_users = SlackUser.limit( match[:count].to_i ).order( 'karma DESC' )

    slack_users.each_with_index do |user, index|
      text += "#{index + 1}. <@#{user.slack_id}> [#{user.karma} karma]\n"
    end

    attachments << {
        pretext: 'Top 10 Karma Leaders',
        title: 'Users',
        text: text,
        color: '#110099'
    }

    client.web_client.chat_postMessage( channel: data.channel, as_user: true, attachments: attachments )
  end

  command 'top' do |client, data, match|
    #use to report user karma
    text = ''

    # Use this to print out stuff in a formatted way in slack
    attachments = []

    slack_users = SlackChannel.find_by( slack_id: data.channel ).users.limit( 5 ).order( 'karma DESC' )

    slack_users.each_with_index do |user, index|
      text += "#{index + 1}. <@#{user.slack_id}> [#{user.karma} karma]\n"
    end

    attachments << {
        pretext: "Top 5 Karma Leaders",
        title: 'Users',
        text: text,
        color: '#110099'
    }

    client.web_client.chat_postMessage( channel: data.channel, as_user: true, attachments: attachments )
  end

  match /top (?<count>\w*)$/ do |client, data, match|
    #use to report user karma
    text = ''

    # Use this to print out stuff in a formatted way in slack
    attachments = []

    slack_users = SlackChannel.find_by( slack_id: data.channel ).users.limit( match[:count].to_i ).order( 'karma DESC' )

    slack_users.each_with_index do |user, index|
      text += "#{index + 1}. <@#{user.slack_id}> [#{user.karma} karma]\n"
    end

    attachments << {
        pretext: "Top #{match[:count]} Karma Leaders",
        title: 'Users',
        text: text,
        color: '#110099'
    }

    client.web_client.chat_postMessage( channel: data.channel, as_user: true, attachments: attachments )
  end
end
