#!/usr/bin/python3

import slackweb

# This reads an environment variable named WEBHOOK_URL
slack = slackweb.Slack(os.environ['WEBHOOK_URL'])

# This is how to send a message.
slack.notify(text="We have a winner", channel="distro_check", username="distro_checker", icon_emoji=":ghost:")


