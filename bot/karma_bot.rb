require 'slack-ruby-bot'

class KarmaBot < SlackRubyBot::Bot

  help do
    title 'Cox Karma Bot'
    desc 'Tracks Karma'

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

      slack_user = SlackUser.find_or_create_by( slack_id: slack_id )
      slack_user.karma += karma
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

    #use to report user karma
    text = ''

    # Use this to print out stuff in a formatted way in slack
    attachments = []

    slack_users = SlackUser.limit( 10 ).order( 'karma DESC' )

    10.times do |count|
      puts count, slack_users.length
      break if count >= slack_users.length
      text += "#{count+1}. <@#{slack_users[count].slack_id}> [#{slack_users[count].karma} karma]\n"
    end

    attachments << {
        pretext: 'Top 10 Karma Leaders',
        title: 'Users',
        text: text,
        color: '#110099'
    }

    client.web_client.chat_postMessage( channel: data.channel, as_user: true, attachments: attachments )

  end
end
