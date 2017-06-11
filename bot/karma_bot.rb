class KarmaBot < SlackRubyBot::Bot

  # Command for adding karma
  match /\+{2,}/ do |client, data, match|

  end

  # Command for removing karma
  match /\-{2,}/ do |client, data, match|

  end

  command /leaderboard/ do |client, data, match|
  end
end
