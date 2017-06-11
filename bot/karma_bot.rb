class KarmaBot < SlackRubyBot::Bot

  # Command for adding karma
  match /\+{2,}/ do |client, data, match|
    puts 'adding karma'
    user = data.text.match( /\<(.+?)\>/).to_s
    client.say( channel: data.channel, text: "#{user} Adding some karma" )
  end

  # Command for removing karma
  match /\-{2,}/ do |client, data, match|
    puts 'removing karma'
    client.say( channel: data.channel, text: 'Removing some karma' )
  end

  command 'leaderboard' do |client, data, match|
  end
end
