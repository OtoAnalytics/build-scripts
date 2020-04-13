#!/bin/bash

api_key="DATADOG-APIKEY"
app_key="APP_KEY"
#url="https://www.womply.com/peek/"

curl -X POST \
-H 'Content-Type: application/json' \
-H "DD-API-KEY: ${api_key}" \
-H "DD-APPLICATION-KEY: ${app_key}" \
-d '{
   "config":{
      "assertions":[
         {
            "operator":"is",
            "type":"statusCode",
            "target":200
         },
         {
            "operator":"contains",
            "type":"body",
            "target":"Fast-track your Paycheck Protection loan."
         },
         {
            "operator":"lessThan",
            "type":"responseTime",
            "target":2000
         }
      ],
      "request":{
         "method":"GET",
         "url":"'"${url}"'",
         "timeout":30
      }
   },
   "locations":[
      "aws:us-east-2",
      "aws:us-west-2"
   ],
   "message":"@pagerduty-Steven_UI_Escalation @slack-alerts-global-svcs Please check the site '"${url}"'",
   "name":"Test on '"${url}"'",
   "options":{
      "tick_every":60,
      "min_failure_duration":0,
      "min_location_failed":1,
      "follow_redirects":true
   },
   "tags":[
      "check_type:womply_landing_pages"
   ],
   "type":"api"
}' \
"https://api.datadoghq.com/api/v1/synthetics/tests"
