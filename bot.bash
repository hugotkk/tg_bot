#!/bin/bash

if [[ -z "$api_token" ]] || [[ -z "$sleep" ]]; then
	echo 'sleep=<second> api_token=<YOUR_API_TOKEN> ./bot.bash '
	exit
fi

api_url=https://api.telegram.org/bot"$api_token"
binance_api_url=https://api1.binance.com/api/v3

m_result=$(curl -s $api_url'/getUpdates?offset=-1')
update_id=$(echo $m_result | jq .result[-1].update_id)

echo "Last update id: "$update_id

while true; 
do
	echo "Sleeping for $sleep Second"
	sleep 5
	echo "POLL START"
	m_result=$(curl -s $api_url'/getUpdates?offset='$update_id)
	update_id=$(echo $m_result | jq .result[-1].update_id)
	if [[ "" != "$update_id" ]] && [[ "null" != "$update_id" ]]; then
		update_id=$(($update_id+1))
		chat_ids=($(echo $m_result | jq '[.result[] | .message.chat.id] | unique | .[]'))
		echo 'Chat ids: '${chat_ids[@]}
		for chat_id in ${chat_ids[@]}; do
			echo "Parsing new messages from chat_id: "$chat_ids
			for token in ETH BTC DOGE; do 
				echo $m_result | jq '.result[] | select(.message.chat.id | contains('$chat_id') )'  | grep -q -i $token
				if [[ $? -eq 0 ]]; then
					echo "Send Message for "$token
					eth=$(curl -s $binance_api_url'/avgPrice?symbol='$token'USDT' | jq -r .price)
					result=$(curl -s $api_url'/sendMessage' -X POST -H 'Content-Type: application/json' -d '{"chat_id":'$chat_id',"text":"1 '$token' = '$eth' usdt"}')
				fi
			done
		done
	else
		echo "No new message found"
	fi
	echo "POLL END"
done