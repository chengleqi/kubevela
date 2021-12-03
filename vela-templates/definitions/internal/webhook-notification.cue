import (
	"vela/op"
	"encoding/base64"
)

"webhook-notification": {
	type: "workflow-step"
	annotations: {}
	labels: {}
	description: "Send message to webhook"
}
template: {

	parameter: {
		dingding?: {
			url: {
				address?: string
				fromSecret?: {
					name: string
					key:  string
				}
			}
			message: {
				text?: *null | {
					content: string
				}
				// +usage=msgType can be text, link, mardown, actionCard, feedCard
				msgtype: string
				link?:   *null | {
					text?:       string
					title?:      string
					messageUrl?: string
					picUrl?:     string
				}
				markdown?: *null | {
					text:  string
					title: string
				}
				at?: *null | {
					atMobiles?: *null | [...string]
					isAtAll?:   bool
				}
				actionCard?: *null | {
					text:           string
					title:          string
					hideAvatar:     string
					btnOrientation: string
					singleTitle:    string
					singleURL:      string
					btns:           *null | [...*null | {
						title:     string
						actionURL: string
					}]
				}
				feedCard?: *null | {
					links: *null | [...*null | {
						text?:       string
						title?:      string
						messageUrl?: string
						picUrl?:     string
					}]
				}
			}
		}

		slack?: {
			url: {
				address?: string
				fromSecret?: {
					name: string
					key:  string
				}
			}
			message: {
				text:         string
				blocks?:      *null | [...block]
				attachments?: *null | {
					blocks?: *null | [...block]
					color?:  string
				}
				thread_ts?: string
				mrkdwn?:    *true | bool
			}
		}
	}

	block: {
		type:      string
		block_id?: string
		elements?: [...{
			type:       string
			action_id?: string
			url?:       string
			value?:     string
			style?:     string
			text?:      textType
			confirm?: {
				title:   textType
				text:    textType
				confirm: textType
				deny:    textType
				style?:  string
			}
			options?: [...option]
			initial_options?: [...option]
			placeholder?:  textType
			initial_date?: string
			image_url?:    string
			alt_text?:     string
			option_groups?: [...option]
			max_selected_items?: int
			initial_value?:      string
			multiline?:          bool
			min_length?:         int
			max_length?:         int
			dispatch_action_config?: {
				trigger_actions_on?: [...string]
			}
			initial_time?: string
		}]
	}

	textType: {
		type:      string
		text:      string
		emoji?:    bool
		verbatim?: bool
	}

	option: {
		text:         textType
		value:        string
		description?: textType
		url?:         string
	}

	// send webhook notification
	ding: op.#Steps & {
		if parameter.dingding != _|_ {
			if parameter.dingding.url.address != _|_ {
				ding1: op.#DingTalk & {
					message: parameter.dingding.message
					dingUrl: parameter.dingding.url.address
				}
			}
			if parameter.dingding.url.fromSecret != _|_ && parameter.dingding.url.address == _|_ {
				read: op.#Read & {
					value: {
						apiVersion: "v1"
						kind:       "Secret"
						metadata: {
							name:      parameter.dingding.url.fromSecret.name
							namespace: context.namespace
						}
					}
				}

				decoded:     base64.Decode(null, read.value.data[parameter.dingding.url.fromSecret.key])
				stringValue: op.#ConvertString & {bt: decoded}
				ding2:       op.#DingTalk & {
					message: parameter.dingding.message
					dingUrl: stringValue.str
				}
			}
		}
	}

	slack: op.#Steps & {
		if parameter.slack != _|_ {
			if parameter.slack.url.address != _|_ {
				slack1: op.#Slack & {
					message:  parameter.slack.message
					slackUrl: parameter.slack.url.address
				}
			}
			if parameter.slack.url.fromSecret != _|_ && parameter.slack.url.address == _|_ {
				read: op.#Read & {
					value: {
						kind:       "Secret"
						apiVersion: "v1"
						metadata: {
							name:      parameter.slack.url.fromSecret.name
							namespace: context.namespace
						}
					}
				}

				decoded:     base64.Decode(null, read.value.data[parameter.slack.url.fromSecret.key])
				stringValue: op.#ConvertString & {bt: decoded}
				slack2:      op.#Slack & {
					message:  parameter.slack.message
					slackUrl: stringValue.str
				}
			}
		}
	}
}