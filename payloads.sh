#premium member

curl -X POST http://localhost:5678/webhook-test/e903ba99-6c8d-4f40-8808-47136b1f817c \
-H "Content-Type: application/json" \
-H "X-API-Key: sk_live_12345abcdef" \
-d '{                        
  "ticket_id": "TCK-9999",                                      
  "customer_tier": "Premium",
  "issue_type": "Lost Card",
  "message": "I am traveling in London staying at the Marriott hotel, room 402, checking out on Friday. My card was stolen, please expedite a new one."
}'

#vip member



curl -X POST http://localhost:5678/webhook-test/e903ba99-6c8d-4f40-8808-47136b1f817c \
-H "Content-Type: application/json" \
-H "X-API-Key: sk_live_12345abcdef" \
-d '{
  "ticket_id": "TCK-3003",
  "customer_tier": "VIP",
  "issue_type": "Lost Card",
  "message": "My card was swallowed by an ATM in Tokyo. I have a massive corporate dinner tonight and I need a solution immediately."
}'