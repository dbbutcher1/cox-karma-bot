require 'slack-ruby-bot'
require 'pry'

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
      desc "Prints the top 10 users across all channels"
      long_desc 'This command shows who leads in karma across the organization'
    end

    command 'top' do
      desc 'Prints the top users within a channel'
      long_desc "This command will display the top X users (default 5) within a channel.\n\nexample:\n @coxkarma top 7"
    end
  end

  match /(\+{2,})|(\-{2,})/ do |client, data, match|

    begin

      channel = SlackChannel.find_or_create_by( slack_id: data.channel )

      # Magical regex that will find all instances of users with a + or -
      karma_changes = data.text.scan( /(([\w^-]+|<[^>]+>)\s*([+]{2,}|[^<>;][-]{2,}[^<>&]))/ ).collect { |x| x.first }
      karma_changes.delete_if { |val| val.gsub(/[+-]/, '').length == 0 }

      # Use this to print out stuff in a formatted way in slack
      attachments = []

      karma_changes.each do | karma_change |

        # Do some magic and remove the cruft so that we can act on only the requested karma change
        change = karma_change.scan( /[+]{2,}|[-]{2,}/ ).first

        # Parse out the user id and remove angle brackets and the @ symbol
        user_string = karma_change.gsub( /\<|\>|\+{2,}|\-{2,}|\@/, '' ).strip

        slack_id, user_alias = user_string.split( '|' )
        removed = false

        if change.include?( '+' )
          karma = change.count( '+' ) - 1 > Rails.application.config.max_karma ?
            Rails.application.config.max_karma : change.count( '+' ) - 1
        else
          removed = true
          karma = -( change.count( '-' ) - 1 > Rails.application.config.max_karma ?
            Rails.application.config.max_karma : change.count( '-' ) - 1 )
        end

        slack_user = SlackUser.find_or_create_by( slack_id: slack_id )
        slack_user.slack_channels << channel if slack_user.channels.find_by( id: channel.id ).nil?
        slack_user.alias = user_alias unless user_alias.blank?

        if slack_id != data.user
          slack_user.karma += karma
          slack_user.save!

          attachments << {
            fallback: "<@#{slack_user.slack_id}> now has #{slack_user.karma}",
            title: removed ? 'Karma Taken' : 'Karma Given',
            text: "<@#{slack_user.slack_id}> now has #{slack_user.karma}",
            color: removed ? '#FF0000' : '#00FF00'
          }
        else
          if karma > 0

            karma *= -1

            slack_user.karma += karma
            slack_user.save!

            attachments << {
              fallback: "Ego is getting to you... <@#{slack_user.slack_id}> now has #{slack_user.karma}",
              title: 'Karma Not Given',
              text: "Ego is getting to you... <@#{slack_user.slack_id}> now has #{slack_user.karma}",
              color: '#FF0000'
            }
          else
            attachments << {
                fallback: "Don't be so hard on yourself...",
                title: "It'll be ok",
                text: "Don't be so hard on yourself...",
                color: '#FF00'
            }
          end
        end
      end

      client.web_client.chat_postMessage( channel: channel.slack_id, as_user: true, attachments: attachments ) unless attachments.empty?

    rescue Exception => e
      puts e.message, e.backtrace
      client.say(
          channel: data.channel,
          text: "<@#{data.user}> :poop:! We encountered an error :cry:!!!>"
      )
    end
  end

  command 'leaderboard' do |client, data, match|

    begin
      #use to report user karma
      text = ''

      # Use this to print out stuff in a formatted way in slack
      attachments = []

      slack_users = SlackUser.limit( 10 ).order( 'karma DESC' )

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
    rescue Exception => e
      client.say(
          channel: data.channel,
          text: "<@#{data.user}> :poop:! We encountered an error :cry:!!!>"
      )
    end

  end

  command 'top' do |client, data, match|

    count = match[:expression].to_i > 0 ? [ match[:expression].to_i, 20 ].min : 5

    begin
      #use to report user karma
      text = ''

      # Use this to print out stuff in a formatted way in slack
      attachments = []

      slack_users = SlackChannel.find_by( slack_id: data.channel ).users.limit( count ).order( 'karma DESC' )

      slack_users.each_with_index do |user, index|
        text += "#{index + 1}. <@#{user.slack_id}> [#{user.karma} karma]\n"
      end

      attachments << {
          pretext: "Top #{count} Karma Leaders",
          title: 'Users',
          text: text,
          color: '#110099'
      }

      client.web_client.chat_postMessage( channel: data.channel, as_user: true, attachments: attachments )
    rescue Exception => e
      client.say(
          channel: data.channel,
          text: "<@#{data.user}> :poop:! We encountered an error :cry:!!!>"
      )
    end
  end
end
